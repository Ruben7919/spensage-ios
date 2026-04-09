import Foundation

struct PersistedMissionProgress: Codable, Equatable {
    let completedAt: Date
    let rewardXP: Int
}

struct GrowthProgressState: Codable, Equatable {
    var trophyUnlockDates: [String: Date] = [:]
    var completedMissions: [String: PersistedMissionProgress] = [:]
}

enum GrowthProgressStore {
    private static let storageKeyPrefix = "native.growth.progress.state"

    static func load(for session: SessionState, defaults: UserDefaults = .standard) -> GrowthProgressState {
        guard
            let data = defaults.data(forKey: storageKey(for: session)),
            let state = try? JSONDecoder().decode(GrowthProgressState.self, from: data)
        else {
            return GrowthProgressState()
        }

        return state
    }

    @discardableResult
    static func sync(
        for session: SessionState,
        trophies: [GrowthTrophy],
        missions: [GrowthMission],
        defaults: UserDefaults = .standard,
        now: Date = .now
    ) -> GrowthProgressState {
        var state = load(for: session, defaults: defaults)

        for trophy in trophies where trophy.unlocked {
            if state.trophyUnlockDates[trophy.id] == nil {
                state.trophyUnlockDates[trophy.id] = trophy.unlockedAt ?? now
            }
        }

        for mission in missions where mission.status == .completed {
            if state.completedMissions[mission.id] == nil {
                state.completedMissions[mission.id] = PersistedMissionProgress(
                    completedAt: now,
                    rewardXP: mission.rewardXP
                )
            }
        }

        save(state, for: session, defaults: defaults)
        return state
    }

    static func reset(for session: SessionState, defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: storageKey(for: session))
    }

    private static func save(_ state: GrowthProgressState, for session: SessionState, defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: storageKey(for: session))
    }

    private static func storageKey(for session: SessionState) -> String {
        "\(storageKeyPrefix).\(session.storageNamespace)"
    }
}
