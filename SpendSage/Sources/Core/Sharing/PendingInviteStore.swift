import Foundation

struct PendingInviteStore {
    private let defaults: UserDefaults
    private let storageKey = "native.pendingInviteCode"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func currentCode() -> String? {
        let trimmed = defaults.string(forKey: storageKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else { return nil }
        return trimmed
    }

    func store(code: String?) {
        let trimmed = code?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else {
            defaults.removeObject(forKey: storageKey)
            return
        }
        defaults.set(trimmed, forKey: storageKey)
    }

    func consumeCode() -> String? {
        let value = currentCode()
        defaults.removeObject(forKey: storageKey)
        return value
    }
}
