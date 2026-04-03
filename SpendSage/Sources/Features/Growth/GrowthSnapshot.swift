import Foundation
import SwiftUI

struct GrowthMission: Identifiable, Equatable {
    enum Status: String {
        case pending = "Pending"
        case ready = "Ready"
        case completed = "Completed"
    }

    let id: String
    let title: String
    let detail: String
    let coachNote: String
    let cadenceLabel: String
    let rewardXP: Int
    let systemImage: String
    let progressValue: Int
    let progressTarget: Int
    let status: Status

    var progressRatio: Double {
        guard progressTarget > 0 else { return 0 }
        return min(1, max(0, Double(progressValue) / Double(progressTarget)))
    }

    var progressText: String {
        "\(min(progressValue, progressTarget))/\(progressTarget)"
    }
}

struct GrowthTrophy: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let celebration: String
    let systemImage: String
    let hybridBadgeAsset: String
    let progressValue: Int
    let progressTarget: Int
    let unlocked: Bool
    let unlockedAt: Date?

    var progressRatio: Double {
        guard progressTarget > 0 else { return 0 }
        return min(1, max(0, Double(progressValue) / Double(progressTarget)))
    }

    var progressText: String {
        if unlocked {
            return "Unlocked"
        }
        return "\(min(progressValue, progressTarget))/\(progressTarget)"
    }
}

struct GrowthEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let occurredAt: Date
    let systemImage: String
}

struct DashboardGrowthSnapshot: Equatable {
    enum RiskState {
        case calm
        case watch
        case urgent

        var label: String {
            switch self {
            case .calm: return "Stable"
            case .watch: return "Watchlist"
            case .urgent: return "Recovery mode"
            }
        }

        var tint: Color {
            switch self {
            case .calm: return BrandTheme.primary
            case .watch: return Color(red: 0.78, green: 0.53, blue: 0.16)
            case .urgent: return Color(red: 0.76, green: 0.28, blue: 0.23)
            }
        }

        var fill: Color {
            tint.opacity(0.16)
        }
    }

    let greetingTitle: String
    let greetingBody: String
    let heroTitle: String
    let heroBody: String
    let coachTitle: String
    let coachBody: String
    let coachAction: String
    let streakDays: Int
    let totalXP: Int
    let level: Int
    let xpToNextLevel: Int
    let levelProgress: Double
    let riskState: RiskState
    let missions: [GrowthMission]
    let trophies: [GrowthTrophy]
    let highlightedTrophies: [GrowthTrophy]
    let events: [GrowthEvent]
}

enum GrowthSnapshotBuilder {
    static func build(
        session: SessionState,
        state: FinanceDashboardState?,
        ledger: LocalFinanceLedger?,
        accounts: [AccountRecord],
        bills: [BillRecord],
        rules: [RuleRecord],
        profile: ProfileRecord
    ) -> DashboardGrowthSnapshot {
        let expenses = ledger?.expenses ?? []
        let uniqueDays = uniqueExpenseDays(in: expenses)
        let streakDays = activeStreak(from: uniqueDays)
        let transactionCount = state?.transactionCount ?? expenses.count
        let utilization = state?.utilizationRatio ?? 0
        let isBudgetHealthy = transactionCount > 0 && utilization <= 1
        let profileCustomized = profile != .default
        let riskState: DashboardGrowthSnapshot.RiskState

        if transactionCount == 0 || utilization < 0.82 {
            riskState = .calm
        } else if utilization < 1 {
            riskState = .watch
        } else {
            riskState = .urgent
        }

        let totalXP =
            transactionCount * 24 +
            uniqueDays.count * 18 +
            accounts.count * 32 +
            bills.count * 34 +
            rules.count * 30 +
            (isBudgetHealthy ? 42 : 0) +
            (profileCustomized ? 18 : 0)
        let level = max(1, (totalXP / 150) + 1)
        let currentThreshold = max(0, (level - 1) * 150)
        let nextThreshold = level * 150
        let xpToNextLevel = max(0, nextThreshold - totalXP)
        let levelProgressDenominator = max(1, nextThreshold - currentThreshold)
        let levelProgress = Double(totalXP - currentThreshold) / Double(levelProgressDenominator)

        let greetingTitle: String
        switch session {
        case .guest:
            greetingTitle = "Your local growth loop"
        case let .signedIn(email, _):
            greetingTitle = "Welcome back, \(email)"
        case .signedOut:
            greetingTitle = "Dashboard"
        }

        let heroTitle: String
        let heroBody: String
        if transactionCount == 0 {
            heroTitle = "Start the first mission"
            heroBody = "Log one expense to wake up coach tips, mission progress, and trophy momentum."
        } else if riskState == .urgent {
            heroTitle = "Tighten the month before it drifts"
            heroBody = "Spending is above the current budget track. Focus on the top category and lock one cleanup action today."
        } else if riskState == .watch {
            heroTitle = "You still have room to steer"
            heroBody = "The month is heating up, but one rule, one bill review, or one trimmed category keeps the dashboard in control."
        } else {
            heroTitle = "Momentum is compounding"
            heroBody = "Your local ledger is clean enough for coaching, missions, and trophy progress to feel intentional."
        }

        let topCategoryName = state?.topCategory?.category.rawValue ?? "your top category"
        let coachTitle: String
        let coachBody: String
        let coachAction: String
        if transactionCount == 0 {
            coachTitle = "Coach: capture the first receipt-sized win"
            coachBody = "The dashboard is ready, but it needs one real expense before it can coach patterns."
            coachAction = "Add one expense today."
        } else if utilization >= 1 {
            coachTitle = "Coach: rescue the monthly runway"
            coachBody = "The fastest relief is usually hiding inside \(topCategoryName.lowercased()). Trim one purchase or move one bill before the week closes."
            coachAction = "Protect cash before opening a new category."
        } else if rules.isEmpty && transactionCount >= 3 {
            coachTitle = "Coach: automate the repeated noise"
            coachBody = "You already have enough transactions for a merchant rule. Turn repetition into cleaner category data."
            coachAction = "Create one rule for the merchant you type most."
        } else if accounts.count < 2 {
            coachTitle = "Coach: widen the financial map"
            coachBody = "The dashboard reads spend well, but it gets smarter once savings or cash balances are part of the story."
            coachAction = "Add one more account bucket."
        } else if bills.isEmpty {
            coachTitle = "Coach: make future obligations visible"
            coachBody = "Recurring bills are still invisible to the dashboard. Add the next due obligation so the coach can call it out early."
            coachAction = "Set up your first recurring bill."
        } else {
            coachTitle = "Coach: keep the rhythm predictable"
            coachBody = "You already have the pieces of a strong local loop. Now the win is consistency: short check-ins, clean categories, and fewer surprises."
            coachAction = "Protect the streak with one quick review tonight."
        }

        let missions = buildMissions(
            transactionCount: transactionCount,
            streakDays: streakDays,
            accounts: accounts.count,
            bills: bills.count,
            rules: rules.count,
            budgetHealthy: isBudgetHealthy
        )

        let trophies = buildTrophies(
            state: state,
            ledger: ledger,
            streakDays: streakDays,
            uniqueDayCount: uniqueDays.count,
            accounts: accounts.count,
            bills: bills.count,
            rules: rules.count,
            level: level,
            budgetHealthy: isBudgetHealthy,
            profileCustomized: profileCustomized
        )
        let events = buildEvents(
            state: state,
            ledger: ledger,
            trophies: trophies,
            coachAction: coachAction,
            riskState: riskState
        )

        return DashboardGrowthSnapshot(
            greetingTitle: greetingTitle,
            greetingBody: session == .guest
                ? "Everything here is generated from the ledger on this device."
                : "Your dashboard mixes budget health, missions, coach tips, and trophy momentum.",
            heroTitle: heroTitle,
            heroBody: heroBody,
            coachTitle: coachTitle,
            coachBody: coachBody,
            coachAction: coachAction,
            streakDays: streakDays,
            totalXP: totalXP,
            level: level,
            xpToNextLevel: xpToNextLevel,
            levelProgress: levelProgress,
            riskState: riskState,
            missions: missions,
            trophies: trophies,
            highlightedTrophies: Array(trophies.filter(\.unlocked).prefix(3)),
            events: Array(events.prefix(6))
        )
    }

    private static func buildMissions(
        transactionCount: Int,
        streakDays: Int,
        accounts: Int,
        bills: Int,
        rules: Int,
        budgetHealthy: Bool
    ) -> [GrowthMission] {
        let candidates = [
            GrowthMission(
                id: "ledger-momentum",
                title: "Log five expenses",
                detail: "Build enough activity for better coach calls and trophy momentum.",
                coachNote: "Short bursts of clean entries are better than one long catch-up session.",
                cadenceLabel: "Daily",
                rewardXP: 80,
                systemImage: "square.and.pencil.circle.fill",
                progressValue: transactionCount,
                progressTarget: 5,
                status: transactionCount >= 5 ? .completed : transactionCount >= 3 ? .ready : .pending
            ),
            GrowthMission(
                id: "streak-keeper",
                title: "Protect a three-day streak",
                detail: "Consecutive active days turn the dashboard from static to predictive.",
                coachNote: "A streak is just repeatability made visible.",
                cadenceLabel: "Weekly",
                rewardXP: 110,
                systemImage: "flame.fill",
                progressValue: streakDays,
                progressTarget: 3,
                status: streakDays >= 3 ? .completed : streakDays >= 2 ? .ready : .pending
            ),
            GrowthMission(
                id: "account-map",
                title: "Add two account buckets",
                detail: "Cash, savings, and cards make the dashboard feel like a real cockpit.",
                coachNote: "One extra account usually unlocks the clearest net-worth story.",
                cadenceLabel: "Weekly",
                rewardXP: 90,
                systemImage: "building.columns.fill",
                progressValue: accounts,
                progressTarget: 2,
                status: accounts >= 2 ? .completed : accounts == 1 ? .ready : .pending
            ),
            GrowthMission(
                id: "bill-radar",
                title: "Turn on bills radar",
                detail: "Track at least one recurring bill so the dashboard can flag future pressure.",
                coachNote: "The calmest months are the ones where obligations stop arriving as surprises.",
                cadenceLabel: "Boss",
                rewardXP: 120,
                systemImage: "calendar.badge.clock",
                progressValue: bills,
                progressTarget: 1,
                status: bills >= 1 ? .completed : .pending
            ),
            GrowthMission(
                id: "rule-architect",
                title: "Create one smart rule",
                detail: "Let recurring merchants auto-land in the right category.",
                coachNote: "Rules remove friction from every future expense.",
                cadenceLabel: "Boss",
                rewardXP: 120,
                systemImage: "point.3.filled.connected.trianglepath.dotted",
                progressValue: rules,
                progressTarget: 1,
                status: rules >= 1 ? .completed : .pending
            ),
            GrowthMission(
                id: "budget-guardian",
                title: "Keep the month inside budget",
                detail: "Stay under the current monthly plan through the next review.",
                coachNote: "If the dashboard stays green, your next decisions get easier.",
                cadenceLabel: "Monthly",
                rewardXP: 140,
                systemImage: "shield.lefthalf.filled",
                progressValue: budgetHealthy ? 1 : 0,
                progressTarget: 1,
                status: budgetHealthy ? .completed : .pending
            )
        ]

        return candidates
            .sorted { lhs, rhs in
                if lhs.status != rhs.status {
                    return lhs.status.sortRank < rhs.status.sortRank
                }
                return lhs.progressRatio > rhs.progressRatio
            }
            .prefix(4)
            .map { $0 }
    }

    private static func buildTrophies(
        state: FinanceDashboardState?,
        ledger: LocalFinanceLedger?,
        streakDays: Int,
        uniqueDayCount: Int,
        accounts: Int,
        bills: Int,
        rules: Int,
        level: Int,
        budgetHealthy: Bool,
        profileCustomized: Bool
    ) -> [GrowthTrophy] {
        let expenses = ledger?.expenses.sorted { $0.date < $1.date } ?? []
        let lastUpdated = ledger?.updatedAt ?? state?.lastUpdated
        let rookieDate = expenses.first?.date
        let steadyDate = nthUniqueExpenseDate(in: expenses, n: 7)

        return [
            GrowthTrophy(
                id: "rookie-ledger",
                title: "Rookie Ledger",
                detail: "The first expense is in. The dashboard can finally coach with real data.",
                celebration: "First expense saved locally.",
                systemImage: "sparkles.rectangle.stack.fill",
                hybridBadgeAsset: "badge_savings_v2.png",
                progressValue: expenses.count,
                progressTarget: 1,
                unlocked: expenses.count >= 1,
                unlockedAt: rookieDate
            ),
            GrowthTrophy(
                id: "steady-paws",
                title: "Steady Paws",
                detail: "Seven active days turned your finance rhythm into a visible streak.",
                celebration: "A full week of active ledger days.",
                systemImage: "pawprint.fill",
                hybridBadgeAsset: "badge_streak_guardian_v2.png",
                progressValue: uniqueDayCount,
                progressTarget: 7,
                unlocked: uniqueDayCount >= 7,
                unlockedAt: steadyDate
            ),
            GrowthTrophy(
                id: "budget-boss",
                title: "Budget Boss",
                detail: "The month is still inside the current plan while activity keeps growing.",
                celebration: "Budget remained in the safe zone.",
                systemImage: "shield.checkered",
                hybridBadgeAsset: "badge_budgeting_v2.png",
                progressValue: budgetHealthy ? 1 : 0,
                progressTarget: 1,
                unlocked: budgetHealthy && expenses.count >= 5,
                unlockedAt: budgetHealthy && expenses.count >= 5 ? lastUpdated : nil
            ),
            GrowthTrophy(
                id: "rule-architect",
                title: "Rule Architect",
                detail: "One merchant rule means the local ledger is starting to self-organize.",
                celebration: "First rule added.",
                systemImage: "point.3.connected.trianglepath.dotted",
                hybridBadgeAsset: "badge_smart_spend_v2.png",
                progressValue: rules,
                progressTarget: 1,
                unlocked: rules >= 1,
                unlockedAt: rules >= 1 ? lastUpdated : nil
            ),
            GrowthTrophy(
                id: "bill-keeper",
                title: "Bill Keeper",
                detail: "Recurring obligations now have a home inside the dashboard.",
                celebration: "Bills radar activated.",
                systemImage: "calendar.badge.clock",
                hybridBadgeAsset: "badge_goals_v2.png",
                progressValue: bills,
                progressTarget: 1,
                unlocked: bills >= 1,
                unlockedAt: bills >= 1 ? lastUpdated : nil
            ),
            GrowthTrophy(
                id: "level-five",
                title: "Level Five",
                detail: "Your local system is deep enough to feel like a product loop, not just a ledger.",
                celebration: "Level five reached.",
                systemImage: "bolt.circle.fill",
                hybridBadgeAsset: "badge_level_up_v2.png",
                progressValue: level,
                progressTarget: 5,
                unlocked: level >= 5,
                unlockedAt: level >= 5 ? lastUpdated : nil
            ),
            GrowthTrophy(
                id: "identity-tuned",
                title: "Identity Tuned",
                detail: "The household profile is customized, making the app feel owned instead of generic.",
                celebration: "Profile updated for this household.",
                systemImage: "person.crop.circle.badge.checkmark",
                hybridBadgeAsset: "badge_security_v2.png",
                progressValue: profileCustomized ? 1 : 0,
                progressTarget: 1,
                unlocked: profileCustomized,
                unlockedAt: profileCustomized ? lastUpdated : nil
            )
        ]
    }

    private static func buildEvents(
        state: FinanceDashboardState?,
        ledger: LocalFinanceLedger?,
        trophies: [GrowthTrophy],
        coachAction: String,
        riskState: DashboardGrowthSnapshot.RiskState
    ) -> [GrowthEvent] {
        let lastUpdated = ledger?.updatedAt ?? state?.lastUpdated ?? .now
        var items: [GrowthEvent] = trophies.compactMap { trophy in
            guard trophy.unlocked, let unlockedAt = trophy.unlockedAt else { return nil }
            return GrowthEvent(
                id: "trophy-\(trophy.id)",
                title: trophy.title,
                detail: trophy.celebration,
                occurredAt: unlockedAt,
                systemImage: "trophy.fill"
            )
        }

        if let topCategory = state?.topCategory {
            items.append(
                GrowthEvent(
                    id: "category-\(topCategory.id)",
                    title: "\(topCategory.category.rawValue) is leading this month",
                    detail: "\(topCategory.count) local expense\(topCategory.count == 1 ? "" : "s") are shaping the current plan.",
                    occurredAt: lastUpdated,
                    systemImage: topCategory.category.symbolName
                )
            )
        }

        if let largestExpense = state?.largestExpense {
            items.append(
                GrowthEvent(
                    id: "largest-\(largestExpense.id)",
                    title: "Largest recent swing",
                    detail: "\(largestExpense.title) is the biggest recent movement in the ledger.",
                    occurredAt: largestExpense.date,
                    systemImage: "arrow.up.right.circle.fill"
                )
            )
        }

        items.append(
            GrowthEvent(
                id: "coach-action",
                title: riskState == .urgent ? "Coach wants a rescue move" : "Coach picked the next move",
                detail: coachAction,
                occurredAt: lastUpdated,
                systemImage: "lightbulb.max.fill"
            )
        )

        return items.sorted { $0.occurredAt > $1.occurredAt }
    }

    private static func uniqueExpenseDays(in expenses: [ExpenseRecord]) -> [Date] {
        let calendar = Calendar.autoupdatingCurrent
        let grouped = Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }
        return grouped.keys.sorted()
    }

    private static func activeStreak(from uniqueDays: [Date]) -> Int {
        guard !uniqueDays.isEmpty else { return 0 }
        let calendar = Calendar.autoupdatingCurrent
        let set = Set(uniqueDays.map { calendar.startOfDay(for: $0) })
        var cursor = calendar.startOfDay(for: .now)

        if !set.contains(cursor), let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor), set.contains(yesterday) {
            cursor = yesterday
        }

        var streak = 0
        while set.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    private static func nthUniqueExpenseDate(in expenses: [ExpenseRecord], n: Int) -> Date? {
        guard n > 0 else { return nil }
        let calendar = Calendar.autoupdatingCurrent
        var seen = Set<Date>()
        var uniqueDates: [Date] = []

        for expense in expenses.sorted(by: { $0.date < $1.date }) {
            let day = calendar.startOfDay(for: expense.date)
            if seen.insert(day).inserted {
                uniqueDates.append(expense.date)
            }
            if uniqueDates.count >= n {
                return uniqueDates[n - 1]
            }
        }

        return nil
    }
}

private extension GrowthMission.Status {
    var sortRank: Int {
        switch self {
        case .pending: return 0
        case .ready: return 1
        case .completed: return 2
        }
    }
}
