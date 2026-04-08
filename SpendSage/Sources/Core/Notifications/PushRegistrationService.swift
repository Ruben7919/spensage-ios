import CryptoKit
import Foundation
import UIKit
import UserNotifications

enum PushAuthorizationState: Equatable {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral
}

struct PushRegistrationStatus: Equatable {
    var backendEnabled = false
    var authorization: PushAuthorizationState = .notDetermined
    var cachedTokenSuffix: String?
    var lastUploadedAt: Date?
    var lastUploadedEnvironment: String?
    var lastUploadedEmail: String?
    var lastError: String?
    var isRegistering = false
    var isSendingTestPush = false
}

struct PushUploadMarker: Codable, Equatable {
    let tokenHash: String
    let email: String
    let environmentName: String
    let apnsEnvironment: APNSEnvironment
    let uploadedAt: Date
}

enum PushRegistrationError: LocalizedError, Equatable {
    case permissionDenied
    case registrationTimedOut
    case registrationFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Activa las notificaciones para este iPhone antes de registrar push."
        case .registrationTimedOut:
            return "El registro push tardó demasiado. Vuelve a intentarlo."
        case let .registrationFailed(message):
            return message
        }
    }
}

@MainActor
protocol PushRegistrationServicing {
    func authorizationStatus() async -> PushAuthorizationState
    func cachedToken() -> String?
    func requestRemoteNotificationToken() async throws -> String
}

enum DefaultPushRegistrationService {
    @MainActor
    static func make() -> PushRegistrationServicing {
        LivePushRegistrationService()
    }
}

@MainActor
final class LivePushRegistrationService: PushRegistrationServicing {
    func authorizationStatus() async -> PushAuthorizationState {
        await PushRegistrationPermissionCenter.shared.authorizationStatus()
    }

    func cachedToken() -> String? {
        PushRegistrationPersistence.cachedToken()
    }

    func requestRemoteNotificationToken() async throws -> String {
        #if targetEnvironment(simulator)
        throw PushRegistrationError.registrationFailed("APNs no se puede validar de punta a punta en Simulator. Usa un iPhone físico.")
        #else
        let currentStatus = await authorizationStatus()
        if currentStatus == .denied {
            throw PushRegistrationError.permissionDenied
        }

        if currentStatus == .notDetermined {
            let granted = await PushRegistrationPermissionCenter.shared.requestAuthorization()
            if !granted {
                throw PushRegistrationError.permissionDenied
            }
        }

        if let token = PushRegistrationPersistence.cachedToken(), !token.isEmpty {
            UIApplication.shared.registerForRemoteNotifications()
            return token
        }

        return try await waitForRegistration()
        #endif
    }

    private func waitForRegistration() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let center = NotificationCenter.default
            var continuationResolved = false
            var successObserver: NSObjectProtocol?
            var failureObserver: NSObjectProtocol?

            func resolve(_ result: Result<String, Error>) {
                guard !continuationResolved else { return }
                continuationResolved = true
                if let successObserver {
                    center.removeObserver(successObserver)
                }
                if let failureObserver {
                    center.removeObserver(failureObserver)
                }
                switch result {
                case let .success(token):
                    continuation.resume(returning: token)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }

            successObserver = center.addObserver(
                forName: .spendsageDidRegisterForRemoteNotifications,
                object: nil,
                queue: .main
            ) { notification in
                let token = notification.userInfo?[PushRegistrationNotificationKeys.token] as? String ?? ""
                if token.isEmpty {
                    resolve(.failure(PushRegistrationError.registrationFailed("No se recibió un token APNs válido.")))
                    return
                }
                resolve(.success(token))
            }

            failureObserver = center.addObserver(
                forName: .spendsageDidFailRemoteNotificationRegistration,
                object: nil,
                queue: .main
            ) { notification in
                let message = notification.userInfo?[PushRegistrationNotificationKeys.error] as? String
                    ?? "Falló el registro APNs."
                resolve(.failure(PushRegistrationError.registrationFailed(message)))
            }

            UIApplication.shared.registerForRemoteNotifications()

            Task { @MainActor in
                try? await Task.sleep(for: .seconds(15))
                resolve(.failure(PushRegistrationError.registrationTimedOut))
            }
        }
    }
}

@MainActor
struct PreviewPushRegistrationService: PushRegistrationServicing {
    func authorizationStatus() async -> PushAuthorizationState {
        .notDetermined
    }

    func cachedToken() -> String? {
        nil
    }

    func requestRemoteNotificationToken() async throws -> String {
        throw PushRegistrationError.registrationFailed("Push registration is not available in previews.")
    }
}

enum PushRegistrationPersistence {
    private static let cachedTokenKey = "native.push.cachedAPNSToken"
    private static let uploadMarkerKey = "native.push.lastUploadMarker"

    static func cacheToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: cachedTokenKey)
    }

    static func cachedToken() -> String? {
        let token = UserDefaults.standard.string(forKey: cachedTokenKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return token?.isEmpty == false ? token : nil
    }

    static func recordUpload(
        token: String,
        email: String,
        environmentName: String,
        apnsEnvironment: APNSEnvironment,
        uploadedAt: Date = .now
    ) {
        let marker = PushUploadMarker(
            tokenHash: token.sha256Hex,
            email: email,
            environmentName: environmentName,
            apnsEnvironment: apnsEnvironment,
            uploadedAt: uploadedAt
        )
        guard let data = try? JSONEncoder().encode(marker) else { return }
        UserDefaults.standard.set(data, forKey: uploadMarkerKey)
    }

    static func uploadMarker() -> PushUploadMarker? {
        guard
            let data = UserDefaults.standard.data(forKey: uploadMarkerKey),
            let marker = try? JSONDecoder().decode(PushUploadMarker.self, from: data)
        else {
            return nil
        }
        return marker
    }

    static func clearUploadMarker() {
        UserDefaults.standard.removeObject(forKey: uploadMarkerKey)
    }

    static func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: cachedTokenKey)
        UserDefaults.standard.removeObject(forKey: uploadMarkerKey)
    }

    static func shouldUpload(token: String, email: String, environmentName: String, apnsEnvironment: APNSEnvironment) -> Bool {
        guard let marker = uploadMarker() else { return true }
        return marker.tokenHash != token.sha256Hex
            || marker.email.caseInsensitiveCompare(email) != .orderedSame
            || marker.environmentName != environmentName
            || marker.apnsEnvironment != apnsEnvironment
    }
}

struct PushRegistrationPermissionCenter {
    static let shared = PushRegistrationPermissionCenter()

    func authorizationStatus() async -> PushAuthorizationState {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                let status: PushAuthorizationState
                switch settings.authorizationStatus {
                case .authorized:
                    status = .authorized
                case .denied:
                    status = .denied
                case .ephemeral:
                    status = .ephemeral
                case .provisional:
                    status = .provisional
                case .notDetermined:
                    status = .notDetermined
                @unknown default:
                    status = .notDetermined
                }
                continuation.resume(returning: status)
            }
        }
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }
}

enum PushRegistrationNotificationKeys {
    static let token = "token"
    static let error = "error"
}

extension Notification.Name {
    static let spendsageDidRegisterForRemoteNotifications = Notification.Name("SpendSageDidRegisterForRemoteNotifications")
    static let spendsageDidFailRemoteNotificationRegistration = Notification.Name("SpendSageDidFailRemoteNotificationRegistration")
}

private extension String {
    var sha256Hex: String {
        let digest = SHA256.hash(data: Data(utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
