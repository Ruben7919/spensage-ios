import Foundation
import LocalAuthentication
import Security

enum AuthSessionPreferences {
    static let rememberDeviceKey = "native.auth.rememberDevice"
    static let biometricUnlockKey = "native.auth.biometricUnlock"

    static func rememberDeviceEnabled(in userDefaults: UserDefaults = .standard) -> Bool {
        if userDefaults.object(forKey: rememberDeviceKey) == nil {
            return true
        }
        return userDefaults.bool(forKey: rememberDeviceKey)
    }

    static func biometricUnlockEnabled(in userDefaults: UserDefaults = .standard) -> Bool {
        if userDefaults.object(forKey: biometricUnlockKey) == nil {
            return true
        }
        return userDefaults.bool(forKey: biometricUnlockKey)
    }
}

enum BiometricKind: Equatable {
    case none
    case faceID
    case touchID
    case opticID

    var displayName: String {
        switch self {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "biometría"
        }
    }

    var systemImage: String {
        switch self {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock.fill"
        }
    }
}

struct PersistedAuthSession: Codable, Equatable {
    let email: String
    let provider: String?
    let refreshToken: String
    let storedAt: Date
}

enum AuthSessionVault {
    private static let service = (Bundle.main.bundleIdentifier ?? "com.spendsage.ai") + ".remembered-session"
    private static let account = "cloud-user"

    static func load() -> PersistedAuthSession? {
        var query = baseQuery()
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let session = try? JSONDecoder().decode(PersistedAuthSession.self, from: data)
        else {
            return nil
        }
        return session
    }

    static func save(_ session: PersistedAuthSession) throws {
        let data = try JSONEncoder().encode(session)
        var query = baseQuery()
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let addStatus = SecItemAdd(query as CFDictionary, nil)
        if addStatus == errSecDuplicateItem {
            let attributes = [
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            ] as [String: Any]
            let updateStatus = SecItemUpdate(baseQuery() as CFDictionary, attributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(updateStatus))
            }
        } else if addStatus != errSecSuccess {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(addStatus))
        }
    }

    static func delete() {
        SecItemDelete(baseQuery() as CFDictionary)
    }

    static func hasSession() -> Bool {
        load() != nil
    }

    private static func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}

enum BiometricUnlockService {
    static func availableBiometric() -> BiometricKind {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        default:
            return .none
        }
    }

    static func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Usar otra cuenta"
        context.localizedFallbackTitle = "Usar código"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }

        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
