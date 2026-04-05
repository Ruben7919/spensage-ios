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
    private static let storageKey = "native.growth.progress.state"

    static func load(defaults: UserDefaults = .standard) -> GrowthProgressState {
        guard
            let data = defaults.data(forKey: storageKey),
            let state = try? JSONDecoder().decode(GrowthProgressState.self, from: data)
        else {
            return GrowthProgressState()
        }

        return state
    }

    @discardableResult
    static func sync(
        trophies: [GrowthTrophy],
        missions: [GrowthMission],
        defaults: UserDefaults = .standard,
        now: Date = .now
    ) -> GrowthProgressState {
        var state = load(defaults: defaults)

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

        save(state, defaults: defaults)
        return state
    }

    static func reset(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: storageKey)
    }

    private static func save(_ state: GrowthProgressState, defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
