import Foundation
import SwiftUI

struct GrowthMissionEvaluationContext {
    let transactionCount: Int
    let streakDays: Int
    let uniqueExpenseDays: Int
    let accounts: Int
    let bills: Int
    let rules: Int
    let budgetHealthy: Bool
    let seasonalTransactionCount: Int
    let seasonalUniqueDayCount: Int
}

enum GrowthMissionObjective: Hashable {
    case transactionCount(Int)
    case streakDays(Int)
    case uniqueExpenseDays(Int)
    case accounts(Int)
    case bills(Int)
    case rules(Int)
    case budgetHealthy
    case seasonalTransactionCount(Int)
    case seasonalUniqueDayCount(Int)

    func progress(in context: GrowthMissionEvaluationContext) -> (value: Int, target: Int) {
        switch self {
        case let .transactionCount(target):
            return (context.transactionCount, target)
        case let .streakDays(target):
            return (context.streakDays, target)
        case let .uniqueExpenseDays(target):
            return (context.uniqueExpenseDays, target)
        case let .accounts(target):
            return (context.accounts, target)
        case let .bills(target):
            return (context.bills, target)
        case let .rules(target):
            return (context.rules, target)
        case .budgetHealthy:
            return (context.budgetHealthy ? 1 : 0, 1)
        case let .seasonalTransactionCount(target):
            return (context.seasonalTransactionCount, target)
        case let .seasonalUniqueDayCount(target):
            return (context.seasonalUniqueDayCount, target)
        }
    }
}

struct GrowthMissionBlueprint: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let coachNote: String
    let cadenceLabel: String
    let rewardXP: Int
    let systemImage: String
    let badgeAsset: String
    let seasonID: BrandSeasonID?
    let objective: GrowthMissionObjective
    let readyThreshold: Int?
    let displayPriority: Int

    func evaluate(in context: GrowthMissionEvaluationContext) -> GrowthMission {
        let progress = objective.progress(in: context)
        let status: GrowthMission.Status

        if progress.value >= progress.target {
            status = .completed
        } else if let readyThreshold, progress.value >= readyThreshold {
            status = .ready
        } else {
            status = .pending
        }

        return GrowthMission(
            id: id,
            title: title,
            detail: detail,
            coachNote: coachNote,
            cadenceLabel: cadenceLabel,
            rewardXP: rewardXP,
            systemImage: systemImage,
            hybridBadgeAsset: badgeAsset,
            progressValue: progress.value,
            progressTarget: progress.target,
            status: status,
            seasonID: seasonID
        )
    }
}

enum GrowthMissionCatalog {
    static let coreBlueprints: [GrowthMissionBlueprint] = [
        GrowthMissionBlueprint(
            id: "ledger-momentum",
            title: "Log five expenses".appLocalized,
            detail: "Build enough activity for better coach calls and trophy momentum.".appLocalized,
            coachNote: "Short bursts of clean entries are better than one long catch-up session.".appLocalized,
            cadenceLabel: "Daily".appLocalized,
            rewardXP: 80,
            systemImage: "square.and.pencil.circle.fill",
            badgeAsset: "badge_quest_daily_v2.png",
            seasonID: nil,
            objective: .transactionCount(5),
            readyThreshold: 3,
            displayPriority: 0
        ),
        GrowthMissionBlueprint(
            id: "streak-keeper",
            title: "Protect a three-day streak".appLocalized,
            detail: "Consecutive active days turn the dashboard from static to predictive.".appLocalized,
            coachNote: "A streak is just repeatability made visible.".appLocalized,
            cadenceLabel: "Weekly".appLocalized,
            rewardXP: 110,
            systemImage: "flame.fill",
            badgeAsset: "badge_streak_v2.png",
            seasonID: nil,
            objective: .streakDays(3),
            readyThreshold: 2,
            displayPriority: 1
        ),
        GrowthMissionBlueprint(
            id: "account-map",
            title: "Add two account buckets".appLocalized,
            detail: "Cash, savings, and cards make the dashboard feel like a real cockpit.".appLocalized,
            coachNote: "One extra account usually unlocks the clearest net-worth story.".appLocalized,
            cadenceLabel: "Weekly".appLocalized,
            rewardXP: 90,
            systemImage: "building.columns.fill",
            badgeAsset: "badge_safe_to_spend_v2.png",
            seasonID: nil,
            objective: .accounts(2),
            readyThreshold: 1,
            displayPriority: 2
        ),
        GrowthMissionBlueprint(
            id: "bill-radar",
            title: "Turn on bills radar".appLocalized,
            detail: "Track at least one recurring bill so the dashboard can flag future pressure.".appLocalized,
            coachNote: "The calmest months are the ones where obligations stop arriving as surprises.".appLocalized,
            cadenceLabel: "Boss".appLocalized,
            rewardXP: 120,
            systemImage: "calendar.badge.clock",
            badgeAsset: "badge_bill_radar_v2.png",
            seasonID: nil,
            objective: .bills(1),
            readyThreshold: nil,
            displayPriority: 3
        ),
        GrowthMissionBlueprint(
            id: "rule-architect",
            title: "Create one smart rule".appLocalized,
            detail: "Let recurring merchants auto-land in the right category.".appLocalized,
            coachNote: "Rules remove friction from every future expense.".appLocalized,
            cadenceLabel: "Boss".appLocalized,
            rewardXP: 120,
            systemImage: "point.3.filled.connected.trianglepath.dotted",
            badgeAsset: "badge_smart_spend_v2.png",
            seasonID: nil,
            objective: .rules(1),
            readyThreshold: nil,
            displayPriority: 4
        ),
        GrowthMissionBlueprint(
            id: "budget-guardian",
            title: "Keep the month inside budget".appLocalized,
            detail: "Stay under the current monthly plan through the next review.".appLocalized,
            coachNote: "If the dashboard stays green, your next decisions get easier.".appLocalized,
            cadenceLabel: "Monthly".appLocalized,
            rewardXP: 140,
            systemImage: "shield.lefthalf.filled",
            badgeAsset: "badge_budgeting_v2.png",
            seasonID: nil,
            objective: .budgetHealthy,
            readyThreshold: nil,
            displayPriority: 5
        )
    ]

    static let seasonalBlueprints: [BrandSeasonID: [GrowthMissionBlueprint]] = [
        .halloween: [
            GrowthMissionBlueprint(
                id: "halloween-night-watch",
                title: "Night watch streak".appLocalized,
                detail: "Stay active on four separate Halloween event days to keep impulse spending from sneaking in.".appLocalized,
                coachNote: "Short check-ins beat one giant cleanup after the candy and costume rush.".appLocalized,
                cadenceLabel: "Event".appLocalized,
                rewardXP: 160,
                systemImage: "moon.stars.fill",
                badgeAsset: "badge_event_halloween_v2.png",
                seasonID: .halloween,
                objective: .seasonalUniqueDayCount(4),
                readyThreshold: 3,
                displayPriority: 0
            ),
            GrowthMissionBlueprint(
                id: "halloween-loot-log",
                title: "Log six spooky purchases".appLocalized,
                detail: "Capture the seasonal extras before they blur into the monthly total.".appLocalized,
                coachNote: "Event spending only feels scary when it stays invisible.".appLocalized,
                cadenceLabel: "Event".appLocalized,
                rewardXP: 140,
                systemImage: "sparkles",
                badgeAsset: "badge_event_halloween_v2.png",
                seasonID: .halloween,
                objective: .seasonalTransactionCount(6),
                readyThreshold: 4,
                displayPriority: 1
            )
        ],
        .winterHolidays: [
            GrowthMissionBlueprint(
                id: "holiday-gift-guard",
                title: "Guard the gift budget".appLocalized,
                detail: "Keep the month inside plan while the festive art pack is live.".appLocalized,
                coachNote: "A visible guardrail makes generous spending feel calm instead of fuzzy.".appLocalized,
                cadenceLabel: "Event".appLocalized,
                rewardXP: 180,
                systemImage: "gift.fill",
                badgeAsset: "badge_event_holiday_v2.png",
                seasonID: .winterHolidays,
                objective: .budgetHealthy,
                readyThreshold: nil,
                displayPriority: 0
            ),
            GrowthMissionBlueprint(
                id: "holiday-wrap-up",
                title: "Log five festive moments".appLocalized,
                detail: "Track the travel, gifts, and hosting costs while the holiday pack is active.".appLocalized,
                coachNote: "Small captures keep December from turning into a mystery total.".appLocalized,
                cadenceLabel: "Event".appLocalized,
                rewardXP: 145,
                systemImage: "sparkles.rectangle.stack.fill",
                badgeAsset: "badge_event_holiday_v2.png",
                seasonID: .winterHolidays,
                objective: .seasonalTransactionCount(5),
                readyThreshold: 3,
                displayPriority: 1
            )
        ],
        .newYear: [
            GrowthMissionBlueprint(
                id: "new-year-fresh-ledger",
                title: "Fresh ledger reset".appLocalized,
                detail: "Log three January entries so the year starts with real visibility instead of guesswork.".appLocalized,
                coachNote: "The cleanest reset is a short first week, not a perfect spreadsheet.".appLocalized,
                cadenceLabel: "Event".appLocalized,
                rewardXP: 150,
                systemImage: "sparkles",
                badgeAsset: "badge_event_new_year_v2.png",
                seasonID: .newYear,
                objective: .seasonalTransactionCount(3),
                readyThreshold: 2,
                displayPriority: 0
            ),
            GrowthMissionBlueprint(
                id: "new-year-cleanup",
                title: "Reset with two active days".appLocalized,
                detail: "Two separate days of cleanup are enough to wake the coach back up for the year.".appLocalized,
                coachNote: "Momentum usually returns faster than motivation once the first two days are visible.".appLocalized,
                cadenceLabel: "Event".appLocalized,
                rewardXP: 120,
                systemImage: "sun.max.fill",
                badgeAsset: "badge_event_new_year_v2.png",
                seasonID: .newYear,
                objective: .seasonalUniqueDayCount(2),
                readyThreshold: nil,
                displayPriority: 1
            )
        ]
    ]

    static func activeBlueprints(for activeSeason: BrandSeasonDefinition?) -> [GrowthMissionBlueprint] {
        guard let activeSeason else { return [] }
        return seasonalBlueprints[activeSeason.id] ?? []
    }
}

struct GrowthMission: Identifiable, Equatable {
    enum Status: String {
        case pending = "Pending"
        case ready = "Ready"
        case completed = "Completed"

        var localizedTitle: String {
            rawValue.appLocalized
        }
    }

    let id: String
    let title: String
    let detail: String
    let coachNote: String
    let cadenceLabel: String
    let rewardXP: Int
    let systemImage: String
    let hybridBadgeAsset: String
    let progressValue: Int
    let progressTarget: Int
    let status: Status
    let seasonID: BrandSeasonID?

    var progressRatio: Double {
        guard progressTarget > 0 else { return 0 }
        return min(1, max(0, Double(progressValue) / Double(progressTarget)))
    }

    var progressText: String {
        "\(min(progressValue, progressTarget))/\(progressTarget)"
    }

    var isSeasonal: Bool {
        seasonID != nil
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
            return "Unlocked".appLocalized
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

struct GrowthLiveEvent: Equatable {
    let title: String
    let detail: String
    let badgeText: String
    let badgeAsset: String
    let sceneKey: String
    let isActive: Bool
    let dateLabel: String
}

struct DashboardSavingsStrategy: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let footnote: String
    let badgeText: String
    let badgeSystemImage: String
    let systemImage: String
}

struct DashboardGrowthSnapshot: Equatable {
    enum RiskState {
        case calm
        case watch
        case urgent

        var label: String {
            switch self {
            case .calm: return "Stable".appLocalized
            case .watch: return "Watchlist".appLocalized
            case .urgent: return "Recovery mode".appLocalized
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
    let strategies: [DashboardSavingsStrategy]
    let missions: [GrowthMission]
    let seasonalMissions: [GrowthMission]
    let trophies: [GrowthTrophy]
    let highlightedTrophies: [GrowthTrophy]
    let events: [GrowthEvent]
    let liveEvent: GrowthLiveEvent?
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
        let activeSeason = BrandSeasonCatalog.activeSeason()
        let seasonalExpenses = expenses.filter { expense in
            guard let activeSeason else { return false }
            return BrandSeasonCatalog.contains(expense.date, in: activeSeason)
        }
        let seasonalUniqueDays = uniqueExpenseDays(in: seasonalExpenses)
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
            greetingTitle = "Your local growth loop".appLocalized
        case let .signedIn(email, _):
            let handle = email
                .components(separatedBy: "@")
                .first?
                .replacingOccurrences(of: ".", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let displayName = handle?.isEmpty == false ? handle! : email
            greetingTitle = AppLocalization.localized("Welcome back, %@", arguments: displayName)
        case .signedOut:
            greetingTitle = "Dashboard".appLocalized
        }

        let heroTitle: String
        let heroBody: String
        if transactionCount == 0 {
            heroTitle = "Start the first mission".appLocalized
            heroBody = "Log one expense to wake up coach tips, mission progress, and trophy momentum.".appLocalized
        } else if riskState == .urgent {
            heroTitle = "Tighten the month before it drifts".appLocalized
            heroBody = "Spending is above the current budget track. Focus on the top category and lock one cleanup action today.".appLocalized
        } else if riskState == .watch {
            heroTitle = "You still have room to steer".appLocalized
            heroBody = "The month is heating up, but one rule, one bill review, or one trimmed category keeps the dashboard in control.".appLocalized
        } else {
            heroTitle = "Momentum is compounding".appLocalized
            heroBody = "Your local ledger is clean enough for coaching, missions, and trophy progress to feel intentional.".appLocalized
        }

        let topCategoryName = state?.topCategory?.category.localizedTitle ?? "your top category".appLocalized
        let coachTitle: String
        let coachBody: String
        let coachAction: String
        if transactionCount == 0 {
            coachTitle = "Coach: capture the first receipt-sized win".appLocalized
            coachBody = "The dashboard is ready, but it needs one real expense before it can coach patterns.".appLocalized
            coachAction = "Add one expense today.".appLocalized
        } else if utilization >= 1 {
            coachTitle = "Coach: rescue the monthly runway".appLocalized
            coachBody = AppLocalization.localized(
                "The fastest relief is usually hiding inside %@. Trim one purchase or move one bill before the week closes.",
                arguments: topCategoryName.lowercased()
            )
            coachAction = "Protect cash before opening a new category.".appLocalized
        } else if rules.isEmpty && transactionCount >= 3 {
            coachTitle = "Coach: automate the repeated noise".appLocalized
            coachBody = "You already have enough transactions for a merchant rule. Turn repetition into cleaner category data.".appLocalized
            coachAction = "Create one rule for the merchant you type most.".appLocalized
        } else if accounts.count < 2 {
            coachTitle = "Coach: widen the financial map".appLocalized
            coachBody = "The dashboard reads spend well, but it gets smarter once savings or cash balances are part of the story.".appLocalized
            coachAction = "Add one more account bucket.".appLocalized
        } else if bills.isEmpty {
            coachTitle = "Coach: make future obligations visible".appLocalized
            coachBody = "Recurring bills are still invisible to the dashboard. Add the next due obligation so the coach can call it out early.".appLocalized
            coachAction = "Set up your first recurring bill.".appLocalized
        } else {
            coachTitle = "Coach: keep the rhythm predictable".appLocalized
            coachBody = "You already have the pieces of a strong local loop. Now the win is consistency: short check-ins, clean categories, and fewer surprises.".appLocalized
            coachAction = "Protect the streak with one quick review tonight.".appLocalized
        }

        let missions = buildMissions(
            context: GrowthMissionEvaluationContext(
                transactionCount: transactionCount,
                streakDays: streakDays,
                uniqueExpenseDays: uniqueDays.count,
                accounts: accounts.count,
                bills: bills.count,
                rules: rules.count,
                budgetHealthy: isBudgetHealthy,
                seasonalTransactionCount: seasonalExpenses.count,
                seasonalUniqueDayCount: seasonalUniqueDays.count
            ),
            activeSeason: activeSeason
        )
        let strategies = buildStrategies(
            state: state,
            ledger: ledger,
            rules: rules
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
            riskState: riskState,
            activeSeason: activeSeason
        )
        let liveEvent = buildLiveEvent(activeSeason: activeSeason)

        return DashboardGrowthSnapshot(
            greetingTitle: greetingTitle,
            greetingBody: session == .guest
                ? "Everything here is generated from the ledger on this device.".appLocalized
                : "Your dashboard mixes budget health, missions, coach tips, and trophy momentum.".appLocalized,
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
            strategies: strategies,
            missions: missions,
            seasonalMissions: missions.filter(\.isSeasonal),
            trophies: trophies,
            highlightedTrophies: Array(trophies.filter(\.unlocked).prefix(3)),
            events: Array(events.prefix(6)),
            liveEvent: liveEvent
        )
    }

    private static func buildMissions(
        context: GrowthMissionEvaluationContext,
        activeSeason: BrandSeasonDefinition?
    ) -> [GrowthMission] {
        let coreMissions = GrowthMissionCatalog.coreBlueprints.map { $0.evaluate(in: context) }
        let seasonalMissions = GrowthMissionCatalog
            .activeBlueprints(for: activeSeason)
            .map { $0.evaluate(in: context) }

        let candidates = seasonalMissions + coreMissions

        return candidates
            .sorted { lhs, rhs in
                if lhs.isSeasonal != rhs.isSeasonal {
                    return lhs.isSeasonal && !rhs.isSeasonal
                }
                if lhs.status != rhs.status {
                    return lhs.status.sortRank < rhs.status.sortRank
                }
                let lhsPriority = missionDisplayPriority(for: lhs.id, seasonID: lhs.seasonID)
                let rhsPriority = missionDisplayPriority(for: rhs.id, seasonID: rhs.seasonID)
                if lhsPriority != rhsPriority {
                    return lhsPriority < rhsPriority
                }
                return lhs.progressRatio > rhs.progressRatio
            }
            .prefix(activeSeason == nil ? 4 : 5)
            .map { $0 }
    }

    private static func buildStrategies(
        state: FinanceDashboardState?,
        ledger: LocalFinanceLedger?,
        rules: [RuleRecord]
    ) -> [DashboardSavingsStrategy] {
        guard let state else {
            return []
        }

        let currencyCode = AppCurrencyFormat.currentCode()
        let weeklySafeToSpend = safeToSpendWeek(for: state.budgetSnapshot.remaining, daysLeft: state.remainingDaysInMonth)
        let hotspot = ledger?.discretionaryHotspots(limit: 1).first
        let topMerchant = ledger?.merchantSuggestions(limit: 1).first
        var candidates: [(priority: Int, strategy: DashboardSavingsStrategy)] = []

        if state.transactionCount == 0 {
            candidates.append(
                (
                    0,
                    DashboardSavingsStrategy(
                        id: "seed-ledger",
                        title: "Seed the coach with three real expenses".appLocalized,
                        detail: "Log groceries, transport, and one flexible purchase so the app can start spotting repeat behavior instead of guessing.".appLocalized,
                        footnote: "The first savings suggestions become more reliable as soon as the local ledger has a few categories to compare.".appLocalized,
                        badgeText: "3 entries".appLocalized,
                        badgeSystemImage: "sparkles",
                        systemImage: "square.and.pencil.circle.fill"
                    )
                )
            )
            return candidates.map(\.strategy)
        }

        if let topCategory = state.topCategory {
            let categoryShare = share(of: topCategory.total, in: state.budgetSnapshot.monthlySpent)
            if state.utilizationRatio >= 0.82 || categoryShare >= 0.34 {
                let suggestedTrim = suggestedTrimAmount(
                    averageExpense: state.averageExpense,
                    topCategoryTotal: topCategory.total,
                    hotspotAverage: hotspot?.averageAmount
                )
                let shareLabel = percentLabel(for: categoryShare)
                let title = state.utilizationRatio >= 1
                    ? AppLocalization.localized("Trim %@ first", arguments: topCategory.category.localizedTitle)
                    : AppLocalization.localized("Cap %@ this week", arguments: topCategory.category.localizedTitle)

                candidates.append(
                    (
                        state.utilizationRatio >= 1 ? 0 : 1,
                        DashboardSavingsStrategy(
                            id: "top-category-\(topCategory.id)",
                            title: title,
                            detail: AppLocalization.localized(
                                "%@ is already %@ of monthly spend. A smaller week there protects the whole plan faster than trimming everywhere.",
                                arguments: topCategory.category.localizedTitle,
                                shareLabel
                            ),
                            footnote: AppLocalization.localized(
                                "%d transaction%@ are already concentrated in %@.",
                                arguments: topCategory.count,
                                topCategory.count == 1 ? "" : "s",
                                topCategory.category.localizedTitle.lowercased()
                            ),
                            badgeText: AppLocalization.localized("Keep %@", arguments: suggestedTrim.formatted(.currency(code: currencyCode))),
                            badgeSystemImage: state.utilizationRatio >= 1 ? "shield.fill" : "leaf.fill",
                            systemImage: topCategory.category.symbolName
                        )
                    )
                )
            }
        }

        if let hotspot {
            candidates.append(
                (
                    state.utilizationRatio >= 1 ? 1 : 0,
                    DashboardSavingsStrategy(
                        id: "merchant-hotspot-\(hotspot.id)",
                        title: AppLocalization.localized("Pause %@ once", arguments: hotspot.merchant),
                        detail: AppLocalization.localized(
                            "%@ showed up %@ for %@ this month. Skipping one visit buys breathing room immediately.",
                            arguments: hotspot.merchant,
                            hotspot.frequencyLabel,
                            hotspot.totalAmount.formatted(.currency(code: currencyCode))
                        ),
                        footnote: AppLocalization.localized(
                            "The average ticket there is %@, so one pause already changes the weekly pace.",
                            arguments: hotspot.averageAmount.formatted(.currency(code: currencyCode))
                        ),
                        badgeText: AppLocalization.localized("Keep %@", arguments: hotspot.averageAmount.formatted(.currency(code: currencyCode))),
                        badgeSystemImage: "pause.circle.fill",
                        systemImage: hotspot.category.symbolName
                    )
                )
            )
        }

        if state.budgetSnapshot.remaining > 0 {
            let reserveAmount = suggestedReserveAmount(
                income: state.budgetSnapshot.monthlyIncome,
                remaining: state.budgetSnapshot.remaining
            )
            if reserveAmount >= 5 {
                let adjustedWeekly = safeToSpendWeek(
                    for: state.budgetSnapshot.remaining - reserveAmount,
                    daysLeft: state.remainingDaysInMonth
                )
                candidates.append(
                    (
                        state.utilizationRatio >= 1 ? 3 : 1,
                        DashboardSavingsStrategy(
                            id: "reserve-buffer",
                            title: "Lock a savings buffer now".appLocalized,
                            detail: AppLocalization.localized(
                                "Move %@ aside before the rest of the month absorbs it into daily spending.",
                                arguments: reserveAmount.formatted(.currency(code: currencyCode))
                            ),
                            footnote: AppLocalization.localized(
                                "%@ still stays safe for the next 7 days after that move.",
                                arguments: adjustedWeekly.formatted(.currency(code: currencyCode))
                            ),
                            badgeText: AppLocalization.localized("Buffer %@", arguments: reserveAmount.formatted(.currency(code: currencyCode))),
                            badgeSystemImage: "target",
                            systemImage: "banknote.fill"
                        )
                    )
                )
            }
        }

        if rules.isEmpty, let topMerchant, topMerchant.frequency >= 2 {
            candidates.append(
                (
                    2,
                    DashboardSavingsStrategy(
                        id: "merchant-rule-\(topMerchant.id)",
                        title: AppLocalization.localized("Automate %@", arguments: topMerchant.merchant),
                        detail: AppLocalization.localized(
                            "%@ already appears %@. One merchant rule keeps the category clean without repeating the same edit.",
                            arguments: topMerchant.merchant,
                            topMerchant.frequencyLabel
                        ),
                        footnote: "Cleaner categories make the coach and future savings suggestions more reliable every week.".appLocalized,
                        badgeText: "1 tap rule".appLocalized,
                        badgeSystemImage: "sparkles",
                        systemImage: "point.3.connected.trianglepath.dotted"
                    )
                )
            )
        }

        if weeklySafeToSpend > 0, candidates.isEmpty {
            candidates.append(
                (
                    0,
                    DashboardSavingsStrategy(
                        id: "protect-weekly-pace",
                        title: "Protect the weekly pace".appLocalized,
                        detail: AppLocalization.localized(
                            "Stay close to %@ for the next 7 days so the month keeps feeling easy to steer.",
                            arguments: weeklySafeToSpend.formatted(.currency(code: currencyCode))
                        ),
                        footnote: "Small adjustments now keep the dashboard in the calm zone and reduce end-of-month cleanup.".appLocalized,
                        badgeText: AppLocalization.localized("Spend %@", arguments: weeklySafeToSpend.formatted(.currency(code: currencyCode))),
                        badgeSystemImage: "calendar",
                        systemImage: "gauge.with.dots.needle.bottom.50percent"
                    )
                )
            )
        }

        return candidates
            .sorted { lhs, rhs in
                if lhs.priority != rhs.priority {
                    return lhs.priority < rhs.priority
                }
                return lhs.strategy.id < rhs.strategy.id
            }
            .map(\.strategy)
            .prefix(3)
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
                title: "Rookie Ledger".appLocalized,
                detail: "The first expense is in. The dashboard can finally coach with real data.".appLocalized,
                celebration: "First expense saved locally.".appLocalized,
                systemImage: "sparkles.rectangle.stack.fill",
                hybridBadgeAsset: "badge_savings_v2.png",
                progressValue: expenses.count,
                progressTarget: 1,
                unlocked: expenses.count >= 1,
                unlockedAt: rookieDate
            ),
            GrowthTrophy(
                id: "steady-paws",
                title: "Steady Paws".appLocalized,
                detail: "Seven active days turned your finance rhythm into a visible streak.".appLocalized,
                celebration: "A full week of active ledger days.".appLocalized,
                systemImage: "pawprint.fill",
                hybridBadgeAsset: "badge_streak_guardian_v2.png",
                progressValue: uniqueDayCount,
                progressTarget: 7,
                unlocked: uniqueDayCount >= 7,
                unlockedAt: steadyDate
            ),
            GrowthTrophy(
                id: "budget-boss",
                title: "Budget Boss".appLocalized,
                detail: "The month is still inside the current plan while activity keeps growing.".appLocalized,
                celebration: "Budget remained in the safe zone.".appLocalized,
                systemImage: "shield.checkered",
                hybridBadgeAsset: "badge_budgeting_v2.png",
                progressValue: budgetHealthy ? 1 : 0,
                progressTarget: 1,
                unlocked: budgetHealthy && expenses.count >= 5,
                unlockedAt: budgetHealthy && expenses.count >= 5 ? lastUpdated : nil
            ),
            GrowthTrophy(
                id: "rule-architect",
                title: "Rule Architect".appLocalized,
                detail: "One merchant rule means the local ledger is starting to self-organize.".appLocalized,
                celebration: "First rule added.".appLocalized,
                systemImage: "point.3.connected.trianglepath.dotted",
                hybridBadgeAsset: "badge_smart_spend_v2.png",
                progressValue: rules,
                progressTarget: 1,
                unlocked: rules >= 1,
                unlockedAt: rules >= 1 ? lastUpdated : nil
            ),
            GrowthTrophy(
                id: "bill-keeper",
                title: "Bill Keeper".appLocalized,
                detail: "Recurring obligations now have a home inside the dashboard.".appLocalized,
                celebration: "Bills radar activated.".appLocalized,
                systemImage: "calendar.badge.clock",
                hybridBadgeAsset: "badge_goals_v2.png",
                progressValue: bills,
                progressTarget: 1,
                unlocked: bills >= 1,
                unlockedAt: bills >= 1 ? lastUpdated : nil
            ),
            GrowthTrophy(
                id: "level-five",
                title: "Level Five".appLocalized,
                detail: "Your local system is deep enough to feel like a product loop, not just a ledger.".appLocalized,
                celebration: "Level five reached.".appLocalized,
                systemImage: "bolt.circle.fill",
                hybridBadgeAsset: "badge_level_up_v2.png",
                progressValue: level,
                progressTarget: 5,
                unlocked: level >= 5,
                unlockedAt: level >= 5 ? lastUpdated : nil
            ),
            GrowthTrophy(
                id: "identity-tuned",
                title: "Identity Tuned".appLocalized,
                detail: "The household profile is customized, making the app feel owned instead of generic.".appLocalized,
                celebration: "Profile updated for this household.".appLocalized,
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
        riskState: DashboardGrowthSnapshot.RiskState,
        activeSeason: BrandSeasonDefinition?
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
                    title: AppLocalization.localized("%@ is leading this month", arguments: topCategory.category.localizedTitle),
                    detail: AppLocalization.localized(
                        "%d local expense%@ are shaping the current plan.",
                        arguments: topCategory.count,
                        topCategory.count == 1 ? "" : "s"
                    ),
                    occurredAt: lastUpdated,
                    systemImage: topCategory.category.symbolName
                )
            )
        }

        if let largestExpense = state?.largestExpense {
            items.append(
                GrowthEvent(
                    id: "largest-\(largestExpense.id)",
                    title: "Largest recent swing".appLocalized,
                    detail: AppLocalization.localized("%@ is the biggest recent movement in the ledger.", arguments: largestExpense.title),
                    occurredAt: largestExpense.date,
                    systemImage: "arrow.up.right.circle.fill"
                )
            )
        }

        items.append(
            GrowthEvent(
                id: "coach-action",
                title: (riskState == .urgent ? "Coach wants a rescue move" : "Coach picked the next move").appLocalized,
                detail: coachAction,
                occurredAt: lastUpdated,
                systemImage: "lightbulb.max.fill"
            )
        )

        if let activeSeason {
            items.append(
                GrowthEvent(
                    id: "season-\(activeSeason.id.rawValue)",
                    title: activeSeason.title.appLocalized,
                    detail: activeSeason.summary.appLocalized,
                    occurredAt: lastUpdated,
                    systemImage: "wand.and.stars"
                )
            )
        }

        return items.sorted { $0.occurredAt > $1.occurredAt }
    }

    private static func buildLiveEvent(
        activeSeason: BrandSeasonDefinition?,
        referenceDate: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> GrowthLiveEvent? {
        if let activeSeason {
            return GrowthLiveEvent(
                title: activeSeason.title,
                detail: activeSeason.summary,
                badgeText: activeSeason.badgeText,
                badgeAsset: activeSeason.badgeAsset,
                sceneKey: activeSeason.spotlightGuideKey,
                isActive: true,
                dateLabel: "Live now".appLocalized
            )
        }

        guard let nextSeason = BrandSeasonCatalog.nextSeason(after: referenceDate, calendar: calendar) else {
            return nil
        }

        return GrowthLiveEvent(
            title: nextSeason.season.title,
            detail: nextSeason.season.summary,
            badgeText: "Next live event".appLocalized,
            badgeAsset: nextSeason.season.badgeAsset,
            sceneKey: nextSeason.season.spotlightGuideKey,
            isActive: false,
            dateLabel: AppLocalization.localized(
                "Starts %@",
                arguments: nextSeason.startDate.formatted(date: .abbreviated, time: .omitted)
            )
        )
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

    private static func safeToSpendWeek(for remaining: Decimal, daysLeft: Int) -> Decimal {
        let safeDays = max(daysLeft, 1)
        let perDay = remaining / Decimal(safeDays)
        let weekly = perDay * Decimal(7)
        return weekly > 0 ? weekly : 0
    }

    private static func share(of value: Decimal, in total: Decimal) -> Double {
        guard total > 0 else { return 0 }
        let lhs = NSDecimalNumber(decimal: value).doubleValue
        let rhs = NSDecimalNumber(decimal: total).doubleValue
        guard rhs > 0 else { return 0 }
        return lhs / rhs
    }

    private static func percentLabel(for value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private static func suggestedTrimAmount(
        averageExpense: Decimal,
        topCategoryTotal: Decimal,
        hotspotAverage: Decimal?
    ) -> Decimal {
        let hotspotValue = hotspotAverage ?? 0
        let categorySlice = topCategoryTotal * Decimal(string: "0.18")!
        let baseline = max(averageExpense, hotspotValue)
        return max(baseline, categorySlice)
    }

    private static func suggestedReserveAmount(income: Decimal, remaining: Decimal) -> Decimal {
        let incomeCap = income * Decimal(string: "0.08")!
        let remainingCap = remaining * Decimal(string: "0.25")!
        return min(incomeCap, remainingCap)
    }

    private static func missionDisplayPriority(for id: String, seasonID: BrandSeasonID?) -> Int {
        if let seasonID {
            return GrowthMissionCatalog
                .seasonalBlueprints[seasonID]?
                .first(where: { $0.id == id })?
                .displayPriority ?? .max
        }

        return GrowthMissionCatalog
            .coreBlueprints
            .first(where: { $0.id == id })?
            .displayPriority ?? .max
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
