import EventKit
import Foundation

struct BillCalendarSyncStatus: Equatable {
    let authorization: BillCalendarAuthorizationState
    let lastSyncedAt: Date?
    let syncedBillCount: Int?
    let lastError: String?
    let isSyncing: Bool

    init(
        authorization: BillCalendarAuthorizationState = .notDetermined,
        lastSyncedAt: Date? = nil,
        syncedBillCount: Int? = nil,
        lastError: String? = nil,
        isSyncing: Bool = false
    ) {
        self.authorization = authorization
        self.lastSyncedAt = lastSyncedAt
        self.syncedBillCount = syncedBillCount
        self.lastError = lastError
        self.isSyncing = isSyncing
    }
}

enum BillCalendarAuthorizationState: Equatable {
    case notDetermined
    case denied
    case restricted
    case granted

    var systemImage: String {
        switch self {
        case .notDetermined:
            return "calendar.badge.questionmark"
        case .denied:
            return "calendar.badge.exclamationmark"
        case .restricted:
            return "calendar.badge.minus"
        case .granted:
            return "calendar.badge.checkmark"
        }
    }

    var summary: String {
        switch self {
        case .notDetermined:
            return "SpendSage puede crear recordatorios de facturas en tu calendario si tú lo autorizas."
        case .denied:
            return "El permiso de calendario está denegado en este iPhone."
        case .restricted:
            return "El calendario está restringido por el sistema o por controles del dispositivo."
        case .granted:
            return "SpendSage puede crear o actualizar recordatorios de facturas en tu calendario."
        }
    }
}

enum BillCalendarSyncError: LocalizedError, Equatable {
    case accessDenied
    case calendarUnavailable

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Permite acceso al calendario para crear recordatorios de facturas."
        case .calendarUnavailable:
            return "No se encontró un calendario disponible para crear eventos."
        }
    }
}

@MainActor
protocol BillCalendarSyncServicing {
    func authorizationStatus() async -> BillCalendarAuthorizationState
    func requestAccessIfNeeded() async throws
    func syncBills(_ bills: [BillRecord], ledger: LocalFinanceLedger, session: SessionState) async throws -> Int
}

enum DefaultBillCalendarSyncService {
    @MainActor
    static func make() -> BillCalendarSyncServicing {
        LiveBillCalendarSyncService()
    }
}

@MainActor
final class LiveBillCalendarSyncService: BillCalendarSyncServicing {
    private let store = EKEventStore()

    func authorizationStatus() async -> BillCalendarAuthorizationState {
        Self.mapAuthorization(EKEventStore.authorizationStatus(for: .event))
    }

    func requestAccessIfNeeded() async throws {
        let current = EKEventStore.authorizationStatus(for: .event)
        switch current {
        case .authorized, .fullAccess, .writeOnly:
            return
        case .denied:
            throw BillCalendarSyncError.accessDenied
        case .restricted:
            throw BillCalendarSyncError.calendarUnavailable
        case .notDetermined:
            let granted = try await store.requestFullAccessToEvents()
            guard granted else {
                throw BillCalendarSyncError.accessDenied
            }
        @unknown default:
            throw BillCalendarSyncError.calendarUnavailable
        }
    }

    func syncBills(_ bills: [BillRecord], ledger: LocalFinanceLedger, session: SessionState) async throws -> Int {
        try await requestAccessIfNeeded()
        guard let calendar = store.defaultCalendarForNewEvents else {
            throw BillCalendarSyncError.calendarUnavailable
        }

        var mapping = BillCalendarSyncPersistence.eventMapping(for: session)
        let activeBillIDs = Set(bills.map { $0.id.uuidString })

        for (billID, eventIdentifier) in mapping where !activeBillIDs.contains(billID) {
            if let event = store.event(withIdentifier: eventIdentifier) {
                try? store.remove(event, span: .futureEvents)
            }
            mapping.removeValue(forKey: billID)
        }

        for bill in bills {
            let identifier = bill.id.uuidString
            let dueDate = ledger.dueDate(for: bill)
            let event = mapping[identifier].flatMap(store.event(withIdentifier:)) ?? EKEvent(eventStore: store)
            event.calendar = calendar
            event.title = "\(bill.title) · SpendSage"
            event.startDate = Calendar.autoupdatingCurrent.startOfDay(for: dueDate)
            event.endDate = Calendar.autoupdatingCurrent.date(byAdding: .day, value: 1, to: event.startDate) ?? event.startDate
            event.isAllDay = true
            event.notes = "Bill reminder generated from SpendSage."
            event.alarms = [EKAlarm(relativeOffset: -60 * 60 * 24)]
            event.recurrenceRules = [recurrenceRule(for: bill)]
            try store.save(event, span: .futureEvents)
            if let eventIdentifier = event.eventIdentifier {
                mapping[identifier] = eventIdentifier
            }
        }

        BillCalendarSyncPersistence.saveEventMapping(mapping, for: session)
        BillCalendarSyncPersistence.recordSync(count: bills.count, for: session)
        return bills.count
    }

    private func recurrenceRule(for bill: BillRecord) -> EKRecurrenceRule {
        switch bill.cadence ?? .monthly {
        case .monthly:
            return EKRecurrenceRule(
                recurrenceWith: .monthly,
                interval: 1,
                end: nil
            )
        case .yearly:
            return EKRecurrenceRule(
                recurrenceWith: .yearly,
                interval: 1,
                end: nil
            )
        }
    }

    private static func mapAuthorization(_ status: EKAuthorizationStatus) -> BillCalendarAuthorizationState {
        switch status {
        case .authorized, .fullAccess, .writeOnly:
            return .granted
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .restricted
        }
    }
}

@MainActor
struct PreviewBillCalendarSyncService: BillCalendarSyncServicing {
    func authorizationStatus() async -> BillCalendarAuthorizationState {
        .notDetermined
    }

    func requestAccessIfNeeded() async throws {}

    func syncBills(_ bills: [BillRecord], ledger: LocalFinanceLedger, session: SessionState) async throws -> Int {
        bills.count
    }
}

enum BillCalendarSyncPersistence {
    struct Marker: Codable, Equatable {
        let syncedAt: Date
        let count: Int
    }

    private static let mappingKeyPrefix = "spendsage.calendar.mapping"
    private static let markerKeyPrefix = "spendsage.calendar.marker"

    static func eventMapping(for session: SessionState, defaults: UserDefaults = .standard) -> [String: String] {
        guard
            let data = defaults.data(forKey: mappingKey(for: session)),
            let mapping = try? JSONDecoder().decode([String: String].self, from: data)
        else {
            return [:]
        }
        return mapping
    }

    static func saveEventMapping(_ mapping: [String: String], for session: SessionState, defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(mapping) else { return }
        defaults.set(data, forKey: mappingKey(for: session))
    }

    static func marker(for session: SessionState, defaults: UserDefaults = .standard) -> Marker? {
        guard
            let data = defaults.data(forKey: markerKey(for: session)),
            let marker = try? JSONDecoder().decode(Marker.self, from: data)
        else {
            return nil
        }
        return marker
    }

    static func recordSync(count: Int, for session: SessionState, defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(Marker(syncedAt: .now, count: count)) else { return }
        defaults.set(data, forKey: markerKey(for: session))
    }

    private static func mappingKey(for session: SessionState) -> String {
        "\(mappingKeyPrefix).\(session.storageNamespace)"
    }

    private static func markerKey(for session: SessionState) -> String {
        "\(markerKeyPrefix).\(session.storageNamespace)"
    }
}
