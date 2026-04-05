import Foundation
import Testing
@testable import SpendSage

struct GrowthCelebrationTests {
    @Test
    func detectsUnlockedTrophyAndMissionAndLevelUp() {
        let previous = snapshot(
            level: 2,
            totalXP: 210,
            streakDays: 2,
            unlockedTrophies: [],
            completedMissions: []
        )
        let current = snapshot(
            level: 3,
            totalXP: 360,
            streakDays: 3,
            unlockedTrophies: [
                trophy(id: "rookie-ledger", title: "Rookie Ledger")
            ],
            completedMissions: [
                mission(id: "ledger-momentum", title: "Log five expenses")
            ]
        )

        let celebrations = GrowthCelebrationBuilder.build(previous: previous, current: current)

        #expect(celebrations.contains(where: { $0.kind == .levelUp && $0.reachedLevel == 3 }))
        #expect(celebrations.contains(where: { $0.kind == .trophyUnlocked && $0.id == "trophy-rookie-ledger" }))
        #expect(celebrations.contains(where: { $0.kind == .missionCompleted && $0.id == "mission-ledger-momentum" }))
    }

    @Test
    func reviewPromptPolicyTriggersOnlyBeforePromptIsConsumed() {
        let suiteName = "GrowthCelebrationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let previous = snapshot(
            level: 2,
            totalXP: 200,
            streakDays: 2,
            unlockedTrophies: [
                trophy(id: "rookie-ledger", title: "Rookie Ledger")
            ],
            completedMissions: [
                mission(id: "ledger-momentum", title: "Log five expenses")
            ]
        )
        let current = snapshot(
            level: 3,
            totalXP: 360,
            streakDays: 4,
            unlockedTrophies: [
                trophy(id: "rookie-ledger", title: "Rookie Ledger"),
                trophy(id: "steady-paws", title: "Steady Paws")
            ],
            completedMissions: [
                mission(id: "ledger-momentum", title: "Log five expenses"),
                mission(id: "streak-keeper", title: "Protect a three-day streak")
            ]
        )

        #expect(AppReviewPromptPolicy.shouldPrompt(previous: previous, current: current, defaults: defaults))
        AppReviewPromptPolicy.markPrompted(defaults: defaults)
        #expect(AppReviewPromptPolicy.shouldPrompt(previous: previous, current: current, defaults: defaults) == false)
    }

    private func snapshot(
        level: Int,
        totalXP: Int,
        streakDays: Int,
        unlockedTrophies: [GrowthTrophy],
        completedMissions: [GrowthMission]
    ) -> DashboardGrowthSnapshot {
        DashboardGrowthSnapshot(
            greetingTitle: "Hola",
            greetingBody: "Hola",
            heroTitle: "Hola",
            heroBody: "Hola",
            coachTitle: "Hola",
            coachBody: "Hola",
            coachAction: "Hola",
            streakDays: streakDays,
            totalXP: totalXP,
            level: level,
            xpToNextLevel: 150,
            levelProgress: 0.5,
            riskState: .calm,
            strategies: [],
            allMissions: completedMissions,
            missions: completedMissions,
            seasonalMissions: [],
            trophies: unlockedTrophies,
            highlightedTrophies: unlockedTrophies,
            events: [],
            liveEvent: nil
        )
    }

    private func trophy(id: String, title: String) -> GrowthTrophy {
        GrowthTrophy(
            id: id,
            title: title,
            detail: title,
            celebration: title,
            systemImage: "sparkles",
            hybridBadgeAsset: "badge_savings_v2.png",
            progressValue: 1,
            progressTarget: 1,
            unlocked: true,
            unlockedAt: .now
        )
    }

    private func mission(id: String, title: String) -> GrowthMission {
        GrowthMission(
            id: id,
            title: title,
            detail: title,
            coachNote: title,
            cadenceLabel: "Daily",
            rewardXP: 80,
            systemImage: "sparkles",
            hybridBadgeAsset: "badge_quest_daily_v2.png",
            progressValue: 1,
            progressTarget: 1,
            status: .completed,
            seasonID: nil
        )
    }
}
