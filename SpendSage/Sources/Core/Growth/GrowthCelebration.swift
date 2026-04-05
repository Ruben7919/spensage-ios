import Foundation

enum GrowthCelebrationKind: String, Equatable {
    case trophyUnlocked
    case missionCompleted
    case levelUp

    var badgeLabel: String {
        switch self {
        case .trophyUnlocked:
            return "Badge desbloqueado".appLocalized
        case .missionCompleted:
            return "Misión completada".appLocalized
        case .levelUp:
            return "Subida de nivel".appLocalized
        }
    }
}

struct GrowthCelebration: Identifiable, Equatable {
    let id: String
    let kind: GrowthCelebrationKind
    let title: String
    let message: String
    let detail: String
    let badgeAsset: String
    let systemImage: String
    let rewardXP: Int?
    let reachedLevel: Int?
    let shareText: String
}

enum GrowthCelebrationBuilder {
    static func build(previous: DashboardGrowthSnapshot, current: DashboardGrowthSnapshot) -> [GrowthCelebration] {
        var celebrations: [GrowthCelebration] = []

        if current.level > previous.level {
            celebrations.append(
                GrowthCelebration(
                    id: "level-\(current.level)",
                    kind: .levelUp,
                    title: AppLocalization.localized("Nivel %d", arguments: current.level),
                    message: previous.level + 1 == current.level
                        ? AppLocalization.localized("Subiste del nivel %d al %d.", arguments: previous.level, current.level)
                        : AppLocalization.localized("Saltaste del nivel %d al %d.", arguments: previous.level, current.level),
                    detail: AppLocalization.localized(
                        "Tu loop local ya tiene suficiente ritmo para abrir un nuevo tramo del progreso. Te faltan %@ para el siguiente nivel.",
                        arguments: "\(current.xpToNextLevel) XP"
                    ),
                    badgeAsset: "badge_level_up_v2.png",
                    systemImage: "bolt.fill",
                    rewardXP: nil,
                    reachedLevel: current.level,
                    shareText: AppLocalization.localized(
                        "Acabo de subir al %@ en SpendSage. Un paso más en mi loop de ahorro.",
                        arguments: "nivel \(current.level)"
                    )
                )
            )
        }

        let previousUnlockedTrophies = Set(previous.trophies.filter(\.unlocked).map(\.id))
        let unlockedTrophies = current.trophies
            .filter { $0.unlocked && !previousUnlockedTrophies.contains($0.id) }
            .sorted { $0.title < $1.title }

        celebrations.append(
            contentsOf: unlockedTrophies.map { trophy in
                GrowthCelebration(
                    id: "trophy-\(trophy.id)",
                    kind: .trophyUnlocked,
                    title: trophy.title,
                    message: trophy.celebration,
                    detail: trophy.detail,
                    badgeAsset: trophy.hybridBadgeAsset,
                    systemImage: trophy.systemImage,
                    rewardXP: nil,
                    reachedLevel: nil,
                    shareText: AppLocalization.localized(
                        "Desbloqueé el badge \"%@\" en SpendSage. Cada hábito limpio hace más fuerte mi plan de ahorro.",
                        arguments: trophy.title
                    )
                )
            }
        )

        let previousCompletedMissionIDs = Set(
            previous.allMissions
                .filter { $0.status == .completed }
                .map(\.id)
        )
        let completedMissions = current.allMissions
            .filter { $0.status == .completed && !previousCompletedMissionIDs.contains($0.id) }
            .sorted { $0.title < $1.title }

        celebrations.append(
            contentsOf: completedMissions.map { mission in
                GrowthCelebration(
                    id: "mission-\(mission.id)",
                    kind: .missionCompleted,
                    title: mission.title,
                    message: AppLocalization.localized("Misión completada. %d XP listos para tu progreso.", arguments: mission.rewardXP),
                    detail: mission.detail,
                    badgeAsset: mission.hybridBadgeAsset,
                    systemImage: mission.systemImage,
                    rewardXP: mission.rewardXP,
                    reachedLevel: nil,
                    shareText: AppLocalization.localized(
                        "Completé la misión \"%@\" en SpendSage. Voy sumando disciplina y ahorro un paso a la vez.",
                        arguments: mission.title
                    )
                )
            }
        )

        return celebrations
    }
}

enum AppReviewPromptPolicy {
    private static let didPromptKey = "native.review.prompt.didRequest"

    static func shouldPrompt(previous: DashboardGrowthSnapshot, current: DashboardGrowthSnapshot, defaults: UserDefaults = .standard) -> Bool {
        guard !defaults.bool(forKey: didPromptKey) else { return false }

        let trophyGain = current.trophies.filter(\.unlocked).count > previous.trophies.filter(\.unlocked).count
        let missionGain = current.allMissions.filter { $0.status == .completed }.count > previous.allMissions.filter { $0.status == .completed }.count
        let levelGain = current.level > previous.level
        let enoughHistory = current.totalXP >= 220 || current.streakDays >= 3
        let enoughWins = current.trophies.filter(\.unlocked).count >= 2 || current.allMissions.filter { $0.status == .completed }.count >= 2

        return (trophyGain || missionGain || levelGain) && enoughHistory && enoughWins
    }

    static func markPrompted(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: didPromptKey)
    }
}
