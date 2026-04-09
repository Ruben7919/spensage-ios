import Foundation
import MetricKit

struct TelemetryEvent: Codable, Equatable, Identifiable {
    let id: UUID
    let name: String
    let occurredAt: String
    let properties: [String: String]

    init(
        id: UUID = UUID(),
        name: String,
        occurredAt: String = TelemetryDate.isoString(from: .now),
        properties: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.occurredAt = occurredAt
        self.properties = properties
    }
}

struct TelemetryDiagnostic: Codable, Equatable, Identifiable {
    let id: UUID
    let kind: String
    let capturedAt: String
    let payloadBase64: String
    let sizeBytes: Int

    init(
        id: UUID = UUID(),
        kind: String,
        capturedAt: String = TelemetryDate.isoString(from: .now),
        payloadBase64: String,
        sizeBytes: Int
    ) {
        self.id = id
        self.kind = kind
        self.capturedAt = capturedAt
        self.payloadBase64 = payloadBase64
        self.sizeBytes = sizeBytes
    }
}

private struct TelemetryEnvelope: Encodable {
    let events: [TelemetryEvent]
    let diagnostics: [TelemetryDiagnostic]
}

@MainActor
protocol TelemetryServicing {
    func start()
    func track(_ name: String, properties: [String: String]) async
    func flushIfPossible(session: SessionState) async
}

enum DefaultTelemetryService {
    @MainActor
    static func make(
        authService: AuthServicing,
        configuration: BackendConfiguration?
    ) -> TelemetryServicing {
        guard let configuration else {
            return PreviewTelemetryService()
        }
        return LiveTelemetryService(authService: authService, configuration: configuration)
    }
}

@MainActor
final class LiveTelemetryService: TelemetryServicing {
    private let authService: AuthServicing
    private let configuration: BackendConfiguration
    private let sessionURL: URLSession

    init(
        authService: AuthServicing,
        configuration: BackendConfiguration,
        sessionURL: URLSession = .shared
    ) {
        self.authService = authService
        self.configuration = configuration
        self.sessionURL = sessionURL
    }

    func start() {
        MetricKitCollector.shared.start()
    }

    func track(_ name: String, properties: [String: String]) async {
        TelemetryPersistence.enqueue(
            event: TelemetryEvent(name: name, properties: properties)
        )
    }

    func flushIfPossible(session: SessionState) async {
        guard session.isAuthenticated else { return }
        guard let idToken = await authService.currentIDToken(), !idToken.isEmpty else { return }

        let events = TelemetryPersistence.pendingEvents()
        let diagnostics = TelemetryPersistence.pendingDiagnostics()
        guard !events.isEmpty || !diagnostics.isEmpty else { return }

        let envelope = TelemetryEnvelope(events: events, diagnostics: diagnostics)
        guard let body = try? JSONEncoder().encode(envelope) else { return }

        var request = URLRequest(url: configuration.url(for: "/me/telemetry"))
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        do {
            let (_, response) = try await sessionURL.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return
            }
            TelemetryPersistence.clear(events: events, diagnostics: diagnostics)
        } catch {
            return
        }
    }
}

@MainActor
struct PreviewTelemetryService: TelemetryServicing {
    func start() {}

    func track(_ name: String, properties: [String: String]) async {}

    func flushIfPossible(session: SessionState) async {}
}

private enum TelemetryPersistence {
    nonisolated(unsafe) private static let defaults = UserDefaults.standard
    private static let eventsKey = "native.telemetry.events"
    private static let diagnosticsKey = "native.telemetry.diagnostics"
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()
    private static let eventLimit = 50
    private static let diagnosticLimit = 5

    static func enqueue(event: TelemetryEvent) {
        var events = pendingEvents()
        events.append(event)
        if events.count > eventLimit {
            events.removeFirst(events.count - eventLimit)
        }
        save(events: events)
    }

    static func enqueue(diagnostic: TelemetryDiagnostic) {
        var diagnostics = pendingDiagnostics()
        diagnostics.append(diagnostic)
        if diagnostics.count > diagnosticLimit {
            diagnostics.removeFirst(diagnostics.count - diagnosticLimit)
        }
        save(diagnostics: diagnostics)
    }

    static func pendingEvents() -> [TelemetryEvent] {
        decode([TelemetryEvent].self, forKey: eventsKey) ?? []
    }

    static func pendingDiagnostics() -> [TelemetryDiagnostic] {
        decode([TelemetryDiagnostic].self, forKey: diagnosticsKey) ?? []
    }

    static func clear(events: [TelemetryEvent], diagnostics: [TelemetryDiagnostic]) {
        let remainingEvents = pendingEvents().filter { candidate in
            events.contains(where: { $0.id == candidate.id }) == false
        }
        let remainingDiagnostics = pendingDiagnostics().filter { candidate in
            diagnostics.contains(where: { $0.id == candidate.id }) == false
        }
        save(events: remainingEvents)
        save(diagnostics: remainingDiagnostics)
    }

    private static func save(events: [TelemetryEvent]) {
        guard let data = try? encoder.encode(events) else { return }
        defaults.set(data, forKey: eventsKey)
    }

    private static func save(diagnostics: [TelemetryDiagnostic]) {
        guard let data = try? encoder.encode(diagnostics) else { return }
        defaults.set(data, forKey: diagnosticsKey)
    }

    private static func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(type, from: data)
    }
}

final class MetricKitCollector: NSObject, MXMetricManagerSubscriber {
    nonisolated(unsafe) static let shared = MetricKitCollector()

    private var didStart = false

    func start() {
        guard didStart == false else { return }
        didStart = true
        MXMetricManager.shared.add(self)
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            let data = payload.jsonRepresentation()
            TelemetryPersistence.enqueue(
                diagnostic: TelemetryDiagnostic(
                    kind: "mxDiagnosticPayload",
                    payloadBase64: data.base64EncodedString(),
                    sizeBytes: data.count
                )
            )
        }
    }

    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            let data = payload.jsonRepresentation()
            TelemetryPersistence.enqueue(
                diagnostic: TelemetryDiagnostic(
                    kind: "mxMetricPayload",
                    payloadBase64: data.base64EncodedString(),
                    sizeBytes: data.count
                )
            )
        }
    }
}

private enum TelemetryDate {
    nonisolated(unsafe) static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func isoString(from date: Date) -> String {
        formatter.string(from: date)
    }
}
