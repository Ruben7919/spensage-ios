import Foundation

struct SelectedSpaceStore {
    private let defaults: UserDefaults
    private let keyPrefix = "native.sharing.selectedSpace"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func currentSpaceID(for session: SessionState) -> String? {
        let trimmed = defaults.string(forKey: storageKey(for: session))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else { return nil }
        return trimmed
    }

    func setCurrentSpaceID(_ spaceID: String?, for session: SessionState) {
        let trimmed = spaceID?.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = storageKey(for: session)
        guard let trimmed, !trimmed.isEmpty else {
            defaults.removeObject(forKey: key)
            return
        }
        defaults.set(trimmed, forKey: key)
    }

    private func storageKey(for session: SessionState) -> String {
        "\(keyPrefix).\(session.storageNamespace)"
    }
}
