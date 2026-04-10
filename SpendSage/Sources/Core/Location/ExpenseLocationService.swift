import CoreLocation
import Foundation

enum ExpenseLocationAuthorizationStatus: Equatable {
    case notDetermined
    case denied
    case restricted
    case granted

    var systemImage: String {
        switch self {
        case .notDetermined:
            return "location.circle"
        case .denied:
            return "location.slash.circle"
        case .restricted:
            return "location.slash.circle.fill"
        case .granted:
            return "location.circle.fill"
        }
    }

    var summary: String {
        switch self {
        case .notDetermined:
            return "MichiFinanzas puede usar tu ubicación actual solo cuando tú quieras etiquetar un gasto."
        case .denied:
            return "La ubicación está denegada en este iPhone."
        case .restricted:
            return "La ubicación está restringida por el sistema o por controles del dispositivo."
        case .granted:
            return "MichiFinanzas puede usar tu ubicación actual mientras la app está abierta para etiquetar un gasto."
        }
    }
}

enum ExpenseLocationError: LocalizedError, Equatable {
    case accessDenied
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Permite la ubicación mientras usas la app para etiquetar un gasto con tu lugar actual."
        case .locationUnavailable:
            return "No se pudo resolver una ubicación válida en este momento."
        }
    }
}

@MainActor
protocol ExpenseLocationServicing {
    func authorizationStatus() async -> ExpenseLocationAuthorizationStatus
    func requestAuthorization() async throws
    func requestCurrentLocationLabel() async throws -> String
}

enum DefaultExpenseLocationService {
    @MainActor
    static func make() -> ExpenseLocationServicing {
        LiveExpenseLocationService()
    }
}

@MainActor
final class LiveExpenseLocationService: NSObject, ExpenseLocationServicing, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var authorizationContinuation: CheckedContinuation<Void, Error>?
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func authorizationStatus() async -> ExpenseLocationAuthorizationStatus {
        Self.mapAuthorization(manager.authorizationStatus)
    }

    func requestAuthorization() async throws {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return
        case .denied:
            throw ExpenseLocationError.accessDenied
        case .restricted:
            throw ExpenseLocationError.locationUnavailable
        case .notDetermined:
            try await withCheckedThrowingContinuation { continuation in
                authorizationContinuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        @unknown default:
            throw ExpenseLocationError.locationUnavailable
        }
    }

    func requestCurrentLocationLabel() async throws -> String {
        try await requestAuthorization()
        let location = try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        guard let placemark = placemarks.first else {
            throw ExpenseLocationError.locationUnavailable
        }

        let parts = [
            placemark.name,
            placemark.locality,
            placemark.administrativeArea,
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

        guard let first = parts.first else {
            throw ExpenseLocationError.locationUnavailable
        }

        return Array(parts.prefix(2)).joined(separator: ", ").isEmpty ? first : Array(parts.prefix(2)).joined(separator: ", ")
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard let continuation = authorizationContinuation else { return }
            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                authorizationContinuation = nil
                continuation.resume()
            case .denied:
                authorizationContinuation = nil
                continuation.resume(throwing: ExpenseLocationError.accessDenied)
            case .restricted:
                authorizationContinuation = nil
                continuation.resume(throwing: ExpenseLocationError.locationUnavailable)
            case .notDetermined:
                break
            @unknown default:
                authorizationContinuation = nil
                continuation.resume(throwing: ExpenseLocationError.locationUnavailable)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let continuation = locationContinuation else { return }
            locationContinuation = nil
            if let location = locations.last {
                continuation.resume(returning: location)
            } else {
                continuation.resume(throwing: ExpenseLocationError.locationUnavailable)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            guard let continuation = locationContinuation else { return }
            locationContinuation = nil
            continuation.resume(throwing: error)
        }
    }

    private static func mapAuthorization(_ status: CLAuthorizationStatus) -> ExpenseLocationAuthorizationStatus {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
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
struct PreviewExpenseLocationService: ExpenseLocationServicing {
    func authorizationStatus() async -> ExpenseLocationAuthorizationStatus {
        .notDetermined
    }

    func requestAuthorization() async throws {}

    func requestCurrentLocationLabel() async throws -> String {
        "Quito, EC"
    }
}
