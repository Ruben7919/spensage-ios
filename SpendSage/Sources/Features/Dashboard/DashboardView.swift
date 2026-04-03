import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: AppViewModel
    var onOpenGuide: (() -> Void)? = nil
    @State private var isPresentingGuide = false
    @State private var hasPresentedInitialGuide = false
    @State private var selectedMood: DailyCheckInMood = .neutral
    @State private var dailySpentInput = ""
    @State private var dailyReflection = ""
    @State private var dailyCheckInNote: String?
    @State private var selectedWeeklyDecision: WeeklyDecisionSurface = .trimTopCategory
    @State private var weeklyDecisionNote: String?
    @State private var questSkipTokensRemaining = 2
    @State private var questFeedback: String?
    @State private var questStatusOverrides: [String: QuestBoardStatus] = [:]

    private let currencyCode = "USD"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header

                if let state = viewModel.dashboardState {
                    if isGuestLocalMode {
                        localModeCard
                    }
                    firstWinCard(for: state, growth: growthSnapshot)
                    heroCard(for: state, growth: growthSnapshot)
                    loopCard(for: state, growth: growthSnapshot)
                    dailyCheckInCard(for: state, growth: growthSnapshot)
                    coachCard(growth: growthSnapshot)
                    weeklyDecisionCard(for: state, growth: growthSnapshot)
                    missionsSection(growth: growthSnapshot)
                    trophyShowcaseSection(growth: growthSnapshot)
                    timelineSection(growth: growthSnapshot)
                    summaryGrid(for: state, growth: growthSnapshot)
                    netWorthCard
                    billsRadarCard
                    recurringCandidatesCard
                    cumulativeTrendCard
                    categoryCard(for: state)
                    workspaceCard(growth: growthSnapshot)
                    recentExpensesCard(for: state)
                } else {
                    loadingStateCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
        .background(
            ZStack {
                BrandTheme.canvas
                BrandBackdropView()
            }
            .ignoresSafeArea()
        )
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .task {
            if viewModel.dashboardState == nil {
                await viewModel.refreshDashboard()
            }
        }
        .onAppear {
            guard !hasPresentedInitialGuide else { return }
            hasPresentedInitialGuide = true
            if onOpenGuide == nil, !GuideProgressStore.isSeen(.dashboard) {
                isPresentingGuide = true
            }
        }
        .sheet(isPresented: $isPresentingGuide) {
            GuideSheet(guide: GuideLibrary.guide(.dashboard))
        }
    }

    private var growthSnapshot: DashboardGrowthSnapshot {
        GrowthSnapshotBuilder.build(
            session: viewModel.session,
            state: viewModel.dashboardState,
            ledger: viewModel.ledger,
            accounts: viewModel.accounts,
            bills: viewModel.bills,
            rules: viewModel.rules,
            profile: viewModel.profile
        )
    }

    private var isGuestLocalMode: Bool {
        if case .guest = viewModel.session {
            return true
        }
        return false
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    BrandBadge(
                        text: viewModel.session == .guest ? "Guest local mode" : "SpendSage loop",
                        systemImage: viewModel.session == .guest ? "iphone.gen3" : "sparkles"
                    )

                    Text(growthSnapshot.greetingTitle)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandTheme.ink)

                    Text(growthSnapshot.greetingBody)
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                }

                Spacer(minLength: 0)

                Button("Sign out") {
                    viewModel.signOut()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BrandTheme.primary)
            }

            HStack(spacing: 12) {
                Button("Add expense") {
                    viewModel.presentAddExpense()
                }
                .buttonStyle(PrimaryCTAStyle())

                Button("Budget wizard") {
                    viewModel.presentBudgetWizard()
                }
                .buttonStyle(SecondaryCTAStyle())
            }

            if let onOpenGuide {
                Button {
                    onOpenGuide()
                } label: {
                    Label("Open dashboard guide", systemImage: "questionmark.circle")
                }
                .buttonStyle(SecondaryCTAStyle())
            } else {
                Button {
                    isPresentingGuide = true
                } label: {
                    Label("Open dashboard guide", systemImage: "questionmark.circle")
                }
                .buttonStyle(SecondaryCTAStyle())
            }
        }
    }

    private var localModeCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Local free mode")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text("Your free plan stays on this device to avoid cloud cost and account friction. Upgrade later for restore, sync, and richer connected tools.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    BrandBadge(text: "Guest local", systemImage: "iphone.gen3")
                }

                NavigationLink {
                    PremiumView(viewModel: viewModel)
                } label: {
                    Label("Unlock premium", systemImage: "sparkles")
                }
                .buttonStyle(PrimaryCTAStyle())
            }
        }
    }

    private func firstWinCard(for state: FinanceDashboardState, growth: DashboardGrowthSnapshot) -> some View {
        let weeklyGuardrail = safeToSpendWeek(for: state)

        return SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("First win")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text("Keep the onboarding-style first result visible: one safe-to-spend number, one next move, and a light goal cue.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    BrandBadge(text: "Safe-to-spend", systemImage: "banknote.fill")
                }

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(
                        title: "This week",
                        value: weeklyGuardrail.formatted(.currency(code: currencyCode)),
                        systemImage: "banknote.fill"
                    )
                    BrandMetricTile(
                        title: "Days left",
                        value: "\(state.remainingDaysInMonth)",
                        systemImage: "calendar"
                    )
                    BrandMetricTile(
                        title: "Confidence",
                        value: "\(min(95, 64 + growth.streakDays))%",
                        systemImage: "checkmark.seal.fill"
                    )
                }

                BrandFeatureRow(
                    systemImage: "sparkles",
                    title: "Next move",
                    detail: growth.coachAction
                )
            }
        }
    }

    private func heroCard(for state: FinanceDashboardState, growth: DashboardGrowthSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    riskChip(for: growth.riskState)
                    Text(growth.heroTitle)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(growth.heroBody)
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 8) {
                    dashboardStatPill(
                        title: "Streak",
                        value: "\(growth.streakDays)d",
                        systemImage: "flame.fill"
                    )
                    dashboardStatPill(
                        title: "Level",
                        value: "\(growth.level)",
                        systemImage: "bolt.fill"
                    )
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Safe to spend now")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.8))
                    Spacer()
                    Text(state.budgetSnapshot.remaining, format: .currency(code: currencyCode))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                ProgressView(value: min(max(state.utilizationRatio, 0), 1))
                    .tint(Color.white.opacity(0.96))
                    .background(Color.white.opacity(0.16))
                    .clipShape(Capsule(style: .continuous))

                HStack {
                    Text("Spent \(state.budgetSnapshot.monthlySpent, format: .currency(code: currencyCode))")
                    Spacer()
                    Text("Budget \(state.budgetSnapshot.monthlyBudget, format: .currency(code: currencyCode))")
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.82))
            }

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                invertedMetricTile(title: "XP", value: "\(growth.totalXP)", systemImage: "sparkles")
                invertedMetricTile(title: "Next level", value: "\(growth.xpToNextLevel) XP", systemImage: "arrow.up.forward")
                invertedMetricTile(title: "Expenses", value: "\(state.transactionCount)", systemImage: "list.bullet.rectangle")
                invertedMetricTile(title: "Runway", value: "\(state.remainingDaysInMonth)d", systemImage: "calendar")
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            BrandTheme.primary,
                            BrandTheme.primary.opacity(0.88),
                            BrandTheme.glow.opacity(0.84)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 170, height: 170)
                        .offset(x: 26, y: -34)
                }
                .overlay(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 38, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 210, height: 120)
                        .rotationEffect(.degrees(-8))
                        .offset(x: -24, y: 32)
                }
        )
        .shadow(color: BrandTheme.shadow.opacity(0.18), radius: 24, x: 0, y: 14)
    }

    private func loopCard(for state: FinanceDashboardState, growth: DashboardGrowthSnapshot) -> some View {
        let progress = min(max(state.utilizationRatio, 0), 1)
        let nextBill = viewModel.ledger?.upcomingBills().first
        let nextBillValue = nextBill.map { bill -> String in
            let dueDate = viewModel.ledger?.dueDate(for: bill)
            let dueText = dueDate.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "Soon"
            return "\(bill.amount.formatted(.currency(code: currencyCode))) · \(dueText)"
        } ?? "No bills queued"

        return SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        sectionHeading(
                            title: "Local loop",
                            detail: "A compact month view that keeps spending, bills, and automation close together."
                        )

                        Text(loopStatusText(for: state))
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                    }

                    Spacer(minLength: 0)

                    BrandBadge(text: loopPaceLabel(for: state), systemImage: "arrow.triangle.2.circlepath")
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Budget pace")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(BrandTheme.ink)
                        Spacer()
                        Text("\(Int((progress * 100).rounded()))% used")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(BrandTheme.muted)
                    }

                    ProgressView(value: progress)
                        .tint(BrandTheme.primary)

                    HStack {
                        Text("Spent \(state.budgetSnapshot.monthlySpent.formatted(.currency(code: currencyCode)))")
                        Spacer()
                        Text("Remaining \(state.budgetSnapshot.remaining.formatted(.currency(code: currencyCode)))")
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(BrandTheme.muted)
                }

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(
                        title: "Average ticket",
                        value: state.averageExpense.formatted(.currency(code: currencyCode)),
                        systemImage: "chart.bar.fill"
                    )
                    BrandMetricTile(
                        title: "Largest expense",
                        value: state.largestExpense?.amount.formatted(.currency(code: currencyCode)) ?? "None",
                        systemImage: "arrow.up.right.circle.fill"
                    )
                    BrandMetricTile(
                        title: "Accounts",
                        value: "\(viewModel.accounts.count)",
                        systemImage: "wallet.pass.fill"
                    )
                    BrandMetricTile(
                        title: "Rules",
                        value: "\(viewModel.rules.count)",
                        systemImage: "line.3.horizontal.decrease.circle.fill"
                    )
                }

                HStack(alignment: .top, spacing: 12) {
                    dashboardLoopCallout(
                        title: "Next bill",
                        detail: nextBillValue,
                        systemImage: "calendar.badge.clock"
                    )

                    dashboardLoopCallout(
                        title: "Coach action",
                        detail: growth.coachAction,
                        systemImage: "lightbulb.max.fill"
                    )
                }
            }
        }
    }

    private func coachCard(growth: DashboardGrowthSnapshot) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    BrandBadge(text: "Coach tip", systemImage: "lightbulb.max.fill")
                    Spacer()
                    Text("Level \(growth.level)")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.muted)
                }

                Text(growth.coachTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(BrandTheme.ink)

                Text(growth.coachBody)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)

                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(growth.riskState.fill)
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(growth.riskState.tint)
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recommended next move")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(BrandTheme.muted)
                        Text(growth.coachAction)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(BrandTheme.ink)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func missionsSection(growth: DashboardGrowthSnapshot) -> some View {
        let readyMission = growth.missions.first(where: { questStatus(for: $0) != .completed && questStatus(for: $0) != .skipped })

        return SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        sectionHeading(
                            title: "Quest board",
                            detail: "Complete missions, skip one when needed, and keep the local streak moving."
                        )
                    }

                    Spacer(minLength: 0)

                    BrandBadge(text: questModeLabel(for: growth), systemImage: "arrow.triangle.2.circlepath")
                }

                HStack(spacing: 12) {
                    dashboardLoopCallout(
                        title: "Ready now",
                        detail: readyMission?.title ?? "No mission is actionable yet.",
                        systemImage: "bolt.fill"
                    )

                    dashboardLoopCallout(
                        title: "Skip tokens",
                        detail: "\(questSkipTokensRemaining) left",
                        systemImage: "ticket.fill"
                    )

                    dashboardLoopCallout(
                        title: "Quest mix",
                        detail: missionMixText(for: growth),
                        systemImage: "calendar.badge.clock"
                    )
                }

                VStack(spacing: 14) {
                    ForEach(growth.missions) { mission in
                        DashboardMissionCard(
                            mission: mission,
                            status: questStatus(for: mission),
                            skipTokensRemaining: questSkipTokensRemaining,
                            onComplete: {
                                completeQuest(mission)
                            },
                            onSkip: {
                                skipQuest(mission)
                            }
                        )
                    }
                }

                if let questFeedback {
                    BrandFeatureRow(
                        systemImage: "checkmark.seal.fill",
                        title: "Quest board update",
                        detail: questFeedback
                    )
                }
            }
        }
    }

    private func trophyShowcaseSection(growth: DashboardGrowthSnapshot) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Trophy collection")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text("Wins, streaks, and progress markers that reward cleaner money habits.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                    }

                    Spacer(minLength: 0)

                    NavigationLink {
                        TrophyHistoryView(viewModel: viewModel)
                    } label: {
                        Label("History", systemImage: "trophy.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(BrandTheme.primary)
                    }
                }

                if growth.highlightedTrophies.isEmpty {
                    emptyRow(
                        title: "No trophies unlocked yet",
                        detail: "The first one usually lands right after the first real expense."
                    )
                } else {
                    ForEach(growth.highlightedTrophies) { trophy in
                        trophyRow(trophy)
                    }
                }
            }
        }
    }

    private func timelineSection(growth: DashboardGrowthSnapshot) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Recent progress",
                    detail: "Events, coach cues, and trophy beats that explain why the dashboard feels different now."
                )

                ForEach(growth.events) { event in
                    DashboardTimelineRow(event: event)
                }
            }
        }
    }

    private func summaryGrid(for state: FinanceDashboardState, growth: DashboardGrowthSnapshot) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Dashboard pulse",
                    detail: "The finance basics are surfaced with stronger signals, calmer summaries, and faster next steps."
                )

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(
                        title: "Spent",
                        value: state.budgetSnapshot.monthlySpent.formatted(.currency(code: currencyCode)),
                        systemImage: "creditcard.fill"
                    )
                    BrandMetricTile(
                        title: "Income",
                        value: state.budgetSnapshot.monthlyIncome.formatted(.currency(code: currencyCode)),
                        systemImage: "banknote.fill"
                    )
                    BrandMetricTile(
                        title: "Average expense",
                        value: state.averageExpense.formatted(.currency(code: currencyCode)),
                        systemImage: "chart.bar.fill"
                    )
                    BrandMetricTile(
                        title: "Active streak",
                        value: "\(growth.streakDays) days",
                        systemImage: "flame.fill"
                    )
                    BrandMetricTile(
                        title: "Accounts",
                        value: "\(viewModel.accounts.count)",
                        systemImage: "wallet.pass.fill"
                    )
                    BrandMetricTile(
                        title: "Bills",
                        value: "\(viewModel.bills.count)",
                        systemImage: "calendar.badge.clock"
                    )
                    BrandMetricTile(
                        title: "Rules",
                        value: "\(viewModel.rules.count)",
                        systemImage: "line.3.horizontal.decrease.circle.fill"
                    )
                }
            }
        }
    }

    private var netWorthCard: some View {
        let assets = viewModel.ledger?.liquidAccountBalance() ?? 0
        let liabilities = viewModel.ledger?.creditExposure() ?? 0
        let netWorth = assets - liabilities

        return SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Net worth snapshot",
                    detail: viewModel.accounts.isEmpty
                        ? "Add manual balances for cash, savings, cards, and loans to track net worth here."
                        : "\(viewModel.accounts.count) manual account\(viewModel.accounts.count == 1 ? "" : "s") are feeding this balance sheet."
                )

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(title: "Assets", value: assets.formatted(.currency(code: currencyCode)), systemImage: "arrow.up.circle.fill")
                    BrandMetricTile(title: "Liabilities", value: liabilities.formatted(.currency(code: currencyCode)), systemImage: "arrow.down.circle.fill")
                    BrandMetricTile(title: "Net worth", value: netWorth.formatted(.currency(code: currencyCode)), systemImage: "scale.3d")
                }

                NavigationLink {
                    FinanceAccountsToolView(viewModel: viewModel)
                } label: {
                    Label("Manage accounts", systemImage: "wallet.pass.fill")
                }
                .buttonStyle(SecondaryCTAStyle())
            }
        }
    }

    private var billsRadarCard: some View {
        let trackedBills = viewModel.ledger?.upcomingBills().prefix(3) ?? []
        let urgentCount = (viewModel.ledger?.bills ?? []).filter {
            guard let ledger = viewModel.ledger else { return false }
            let status = ledger.billStatus(for: $0)
            return status == .dueSoon || status == .overdue
        }.count

        return SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Bills radar",
                    detail: urgentCount > 0
                        ? "\(urgentCount) tracked bill\(urgentCount == 1 ? "" : "s") need attention."
                        : "Tracked bills are lined up. Review the next due dates before they sneak up on you."
                )

                if trackedBills.isEmpty {
                    emptyRow(
                        title: "No bills tracked yet",
                        detail: "Add recurring obligations so the dashboard can warn you before they are due."
                    )
                } else {
                    ForEach(Array(trackedBills)) { bill in
                        let status = viewModel.ledger?.billStatus(for: bill) ?? .upcoming
                        let dueDate = viewModel.ledger?.dueDate(for: bill).formatted(date: .abbreviated, time: .omitted) ?? "Soon"
                        BrandFeatureRow(
                            systemImage: status.symbolName,
                            title: bill.title,
                            detail: "\(bill.amount.formatted(.currency(code: currencyCode))) · \(status.rawValue) · \(dueDate)"
                        )
                    }
                }

                NavigationLink {
                    FinanceBillsToolView(viewModel: viewModel)
                } label: {
                    Label("Manage bills", systemImage: "calendar.badge.clock")
                }
                .buttonStyle(SecondaryCTAStyle())
            }
        }
    }

    private var recurringCandidatesCard: some View {
        let candidates = recurringCandidates()

        return SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Recurring candidates",
                    detail: candidates.isEmpty
                        ? "Repeated merchants will show up here once the ledger has enough rhythm."
                        : "Repeated merchant patterns that look like subscriptions or regular bills."
                )

                if candidates.isEmpty {
                    emptyRow(
                        title: "No recurring candidates yet",
                        detail: "A few repeated merchants will surface here as soon as the ledger has enough history."
                    )
                } else {
                    ForEach(Array(candidates.prefix(3)), id: \.merchant) { candidate in
                        BrandFeatureRow(
                            systemImage: "repeat.circle.fill",
                            title: candidate.merchant,
                            detail: recurringCandidateDetail(candidate)
                        )
                    }
                }
            }
        }
    }

    private var cumulativeTrendCard: some View {
        let rows = recentCumulativeTrendRows()
        let averageSpend = rows.isEmpty ? 0 : rows.reduce(Decimal.zero) { $0 + $1.total } / Decimal(rows.count)
        let monthlyIncome = viewModel.ledger?.monthlyIncome ?? 0
        let averageIncome = rows.isEmpty ? 0 : monthlyIncome / Decimal(rows.count)
        let averageNet = averageIncome - averageSpend
        let strongestDay = rows.max { lhs, rhs in lhs.total < rhs.total }
        let footerRows: [TrendPoint] = {
            guard !rows.isEmpty else { return [] }
            let middleIndex = rows.count / 2
            let middleRow = rows.indices.contains(middleIndex) ? rows[middleIndex] : nil
            return [rows.first, middleRow, rows.last].compactMap { $0 }
        }()

        return SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "30-day cumulative trend",
                    detail: "A local line chart that shows how spend has stacked up day by day over the recent month."
                )

                if rows.isEmpty {
                    emptyRow(
                        title: "Not enough history yet",
                        detail: "As more days accumulate, this chart will show how spend is trending over time."
                    )
                } else {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        BrandMetricTile(
                            title: "Avg day spend",
                            value: averageSpend.formatted(.currency(code: currencyCode)),
                            systemImage: "chart.bar.fill"
                        )
                        BrandMetricTile(
                            title: "Avg daily net",
                            value: averageNet.formatted(.currency(code: currencyCode)),
                            systemImage: "banknote.fill"
                        )
                        BrandMetricTile(
                            title: "Peak day",
                            value: strongestDay?.label ?? "n/a",
                            systemImage: "arrow.up.right.circle.fill"
                        )
                    }

                    cumulativeTrendSparkline(rows: rows)

                    HStack(spacing: 10) {
                        ForEach(footerRows) { row in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.label)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BrandTheme.ink)
                                Text(row.total.formatted(.currency(code: currencyCode)))
                                    .font(.caption2)
                                    .foregroundStyle(BrandTheme.muted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }

    private func categoryCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Top categories",
                    detail: state.categoryBreakdown.isEmpty
                        ? "Add an expense to see category pressure."
                        : "\(state.transactionCount) transactions are shaping the month."
                )

                if state.categoryBreakdown.isEmpty {
                    emptyRow(
                        title: "No category signal yet",
                        detail: "The first few expenses will quickly reveal where the budget is tilting."
                    )
                } else {
                    ForEach(state.categoryBreakdown) { category in
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(BrandTheme.accent.opacity(0.18))
                                Image(systemName: category.category.symbolName)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(BrandTheme.primary)
                            }
                            .frame(width: 46, height: 46)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(category.category.rawValue)
                                    .font(.headline)
                                    .foregroundStyle(BrandTheme.ink)
                                Text("\(category.count) expense\(category.count == 1 ? "" : "s")")
                                    .font(.footnote)
                                    .foregroundStyle(BrandTheme.muted)
                            }

                            Spacer(minLength: 0)

                            Text(category.total, format: .currency(code: currencyCode))
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)
                        }
                    }
                }
            }
        }
    }

    private func workspaceCard(growth: DashboardGrowthSnapshot) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Tool stack",
                    detail: "Accounts, bills, and smart rules stay close so the dashboard can coach from a fuller picture."
                )

                NavigationLink {
                    FinanceAccountsToolView(viewModel: viewModel)
                } label: {
                    workspaceRow(
                        title: "Accounts",
                        detail: "\(viewModel.accounts.count) tracked bucket\(viewModel.accounts.count == 1 ? "" : "s")",
                        value: (viewModel.ledger?.totalAccountBalance() ?? 0).formatted(.currency(code: currencyCode)),
                        systemImage: "creditcard.fill"
                    )
                }

                NavigationLink {
                    FinanceBillsToolView(viewModel: viewModel)
                } label: {
                    workspaceRow(
                        title: "Bills radar",
                        detail: "\(viewModel.bills.count) recurring obligation\(viewModel.bills.count == 1 ? "" : "s")",
                        value: growth.missions.contains(where: { $0.id == "bill-radar" && $0.status == .completed }) ? "On" : "Needs setup",
                        systemImage: "calendar.badge.clock"
                    )
                }

                NavigationLink {
                    FinanceRulesToolView(viewModel: viewModel)
                } label: {
                    workspaceRow(
                        title: "Smart rules",
                        detail: "\(viewModel.rules.count) automation\(viewModel.rules.count == 1 ? "" : "s")",
                        value: viewModel.rules.isEmpty ? "No automation" : "Live",
                        systemImage: "line.3.horizontal.decrease.circle.fill"
                    )
                }
            }
        }
    }

    private func recentExpensesCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Recent expenses",
                    detail: state.largestExpense.map {
                        "Largest recent movement: \($0.amount.formatted(.currency(code: currencyCode)))"
                    } ?? "The newest activity lands here first."
                )

                if state.recentExpenses.isEmpty {
                    emptyRow(
                        title: "Recent activity will show up here",
                        detail: "Once the ledger moves, this list becomes the fastest way to audit what just happened."
                    )
                } else {
                    ForEach(state.recentExpenses) { expense in
                        expenseRow(expense)
                    }
                }
            }
        }
    }

    private var loadingStateCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                BrandBadge(text: "Loading dashboard", systemImage: "sparkles")
                Text("Your dashboard is building budget cues, coach tips, missions, and trophies.")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(BrandTheme.ink)
                Text("This stays local to the device until the ledger snapshot is ready.")
                    .foregroundStyle(BrandTheme.muted)
                ProgressView()
                    .tint(BrandTheme.primary)
            }
        }
    }

    private func sectionHeading(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(BrandTheme.ink)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(BrandTheme.muted)
        }
    }

    private func riskChip(for state: DashboardGrowthSnapshot.RiskState) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 8, height: 8)
            Text(state.label)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.18))
        .clipShape(Capsule(style: .continuous))
    }

    private func dashboardStatPill(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.7))
                Text(value)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.14))
        .clipShape(Capsule(style: .continuous))
    }

    private func invertedMetricTile(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.white.opacity(0.76))

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.12))
        )
    }

    private func trophyRow(_ trophy: GrowthTrophy) -> some View {
        HStack(spacing: 14) {
            GrowthTrophyPlate(trophy: trophy, size: 54)

            VStack(alignment: .leading, spacing: 4) {
                Text(trophy.title)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text(trophy.detail)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                if let unlockedAt = trophy.unlockedAt {
                    Text(unlockedAt, style: .date)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BrandTheme.primary)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func emptyRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(BrandTheme.ink)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(BrandTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BrandTheme.surfaceTint)
        )
    }

    private func expenseRow(_ expense: ExpenseItem) -> some View {
        let category = ExpenseCategory(rawValue: expense.category) ?? .other

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(BrandTheme.accent.opacity(0.18))
                Image(systemName: category.symbolName)
                    .foregroundStyle(BrandTheme.primary)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text("\(category.rawValue) · \(expense.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
            }

            Spacer(minLength: 0)

            Text(expense.amount, format: .currency(code: currencyCode))
                .font(.headline)
                .foregroundStyle(BrandTheme.ink)
        }
        .padding(.vertical, 2)
    }

    private func workspaceRow(title: String, detail: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(BrandTheme.surfaceTint)
                Image(systemName: systemImage)
                    .foregroundStyle(BrandTheme.primary)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
            }

            Spacer(minLength: 0)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BrandTheme.primary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BrandTheme.surfaceTint)
        )
    }

    private func dashboardLoopCallout(title: String, detail: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(BrandTheme.surfaceTint)
                Image(systemName: systemImage)
                    .foregroundStyle(BrandTheme.primary)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BrandTheme.ink)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BrandTheme.surfaceTint)
        )
    }

    private func loopPaceLabel(for state: FinanceDashboardState) -> String {
        if state.transactionCount == 0 {
            return "Start here"
        }
        if state.utilizationRatio < 0.82 {
            return "Calm pace"
        }
        if state.utilizationRatio < 1 {
            return "Watch pace"
        }
        return "Over budget"
    }

    private func loopStatusText(for state: FinanceDashboardState) -> String {
        if state.transactionCount == 0 {
            return "One expense will unlock category pressure, pace, and bill radar."
        }
        if let nextBill = viewModel.ledger?.upcomingBills().first,
           let dueDate = viewModel.ledger?.dueDate(for: nextBill) {
            return "The next obligation is \(nextBill.title) due \(dueDate.formatted(date: .abbreviated, time: .omitted))."
        }
        return "The month is being tracked locally, so every card can react instantly to new entries."
    }

    private func dailyCheckInCard(for state: FinanceDashboardState, growth: DashboardGrowthSnapshot) -> some View {
        let moodSummary = selectedMood.summary
        let amountSummary = decimalValue(from: dailySpentInput)
            .map { $0.formatted(.currency(code: currencyCode)) } ?? "Optional"

        return SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        sectionHeading(
                            title: "Daily check-in",
                            detail: "Name the mood, capture today's spend if you want, and keep the local streak honest."
                        )
                    }

                    Spacer(minLength: 0)

                    BrandBadge(text: "Today", systemImage: "face.smiling")
                }

                HStack(spacing: 10) {
                    ForEach(DailyCheckInMood.allCases) { mood in
                        Button {
                            selectedMood = mood
                        } label: {
                            Label(mood.title, systemImage: mood.systemImage)
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(CheckInChipStyle(isSelected: selectedMood == mood))
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    TextField("Spent today (optional)", text: $dailySpentInput)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                    TextField("Quick note for yourself", text: $dailyReflection)
                        .textFieldStyle(.roundedBorder)
                }

                HStack(spacing: 12) {
                    Button("Save check-in") {
                        let amount = decimalValue(from: dailySpentInput)
                        let amountText = amount.map { $0.formatted(.currency(code: currencyCode)) }
                        let note = dailyReflection.trimmingCharacters(in: .whitespacesAndNewlines)
                        let pieces = [
                            "Saved a \(selectedMood.title.lowercased()) check-in locally.",
                            amountText.map { "Spend: \($0)." },
                            note.isEmpty ? nil : "Note: \(note)."
                        ].compactMap { $0 }
                        dailyCheckInNote = pieces.joined(separator: " ")
                    }
                    .buttonStyle(PrimaryCTAStyle())

                    Button("Reset") {
                        selectedMood = .neutral
                        dailySpentInput = ""
                        dailyReflection = ""
                        dailyCheckInNote = nil
                    }
                    .buttonStyle(SecondaryCTAStyle())
                }

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(title: "Streak", value: "\(growth.streakDays) days", systemImage: "flame.fill")
                    BrandMetricTile(title: "Mood", value: moodSummary, systemImage: selectedMood.systemImage)
                    BrandMetricTile(title: "Today", value: amountSummary, systemImage: "pencil.and.outline")
                }

                if let dailyCheckInNote {
                    BrandFeatureRow(
                        systemImage: "checkmark.seal.fill",
                        title: "Check-in saved locally",
                        detail: dailyCheckInNote
                    )
                } else {
                    BrandFeatureRow(
                        systemImage: "lightbulb.max.fill",
                        title: "Why this matters now",
                        detail: dailyCheckInHint(for: state, growth: growth)
                    )
                }
            }
        }
    }

    private func weeklyDecisionCard(for state: FinanceDashboardState, growth: DashboardGrowthSnapshot) -> some View {
        let weekSpend = weeklySpend()
        let nextBill = viewModel.bills.first

        return SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        sectionHeading(
                            title: "Weekly decision",
                            detail: "Pick the move that will do the most to steady the week before it closes."
                        )
                    }

                    Spacer(minLength: 0)

                    BrandBadge(text: "Decision", systemImage: "arrow.triangle.branch")
                }

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(
                        title: "This week",
                        value: "\(weeklyExpenseCount()) expenses",
                        systemImage: "calendar.badge.clock"
                    )
                    BrandMetricTile(
                        title: "Weekly spend",
                        value: weekSpend.formatted(.currency(code: currencyCode)),
                        systemImage: "creditcard.fill"
                    )
                    BrandMetricTile(
                        title: "Best lever",
                        value: selectedWeeklyDecision.title,
                        systemImage: selectedWeeklyDecision.systemImage
                    )
                }

                VStack(spacing: 10) {
                    ForEach(WeeklyDecisionSurface.allCases) { decision in
                        Button {
                            selectedWeeklyDecision = decision
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: decision.systemImage)
                                    .foregroundStyle(selectedWeeklyDecision == decision ? .white : BrandTheme.primary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(decision.title)
                                        .font(.subheadline.weight(.semibold))
                                    Text(decision.detail(for: state, growth: growth, weekSpend: weekSpend, nextBill: nextBill))
                                        .font(.footnote)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                        .buttonStyle(WeeklyDecisionChipStyle(isSelected: selectedWeeklyDecision == decision))
                    }
                }

                BrandFeatureRow(
                    systemImage: selectedWeeklyDecision.systemImage,
                    title: selectedWeeklyDecision.title,
                    detail: selectedWeeklyDecision.detail(for: state, growth: growth, weekSpend: weekSpend, nextBill: nextBill)
                )

                Button("Lock in this move locally") {
                    weeklyDecisionNote = "Weekly decision set to \(selectedWeeklyDecision.title.lowercased())."
                }
                .buttonStyle(PrimaryCTAStyle())

                if let weeklyDecisionNote {
                    Text(weeklyDecisionNote)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.primary)
                } else {
                    Text("This stays on-device and only helps frame the next review.")
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }
            }
        }
    }

    private func weeklySpend() -> Decimal {
        let cutoff = Calendar.autoupdatingCurrent.date(byAdding: .day, value: -6, to: .now) ?? .now
        guard let expenses = viewModel.ledger?.expenses else { return 0 }
        return expenses
            .filter { $0.date >= cutoff }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    private func weeklyExpenseCount() -> Int {
        let cutoff = Calendar.autoupdatingCurrent.date(byAdding: .day, value: -6, to: .now) ?? .now
        guard let expenses = viewModel.ledger?.expenses else { return 0 }
        return expenses.filter { $0.date >= cutoff }.count
    }

    private func dailyCheckInHint(for state: FinanceDashboardState, growth: DashboardGrowthSnapshot) -> String {
        let mood = selectedMood.summary.lowercased()
        if state.transactionCount == 0 {
            return "Start with a \(mood) check-in and one real expense so the coach has something concrete to read."
        }
        return "A \(mood) check-in plus a quick spend note gives the dashboard a better read on today’s risk and rhythm."
    }

    private func missionMixText(for growth: DashboardGrowthSnapshot) -> String {
        let dailyCount = growth.missions.filter { $0.cadenceLabel == "Daily" }.count
        let weeklyCount = growth.missions.filter { $0.cadenceLabel == "Weekly" }.count
        let bossCount = growth.missions.filter { $0.cadenceLabel == "Boss" }.count
        return "\(dailyCount) daily · \(weeklyCount) weekly · \(bossCount) boss"
    }

    private func decimalValue(from input: String) -> Decimal? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        let number = NSDecimalNumber(string: normalized)
        guard number != .notANumber else { return nil }
        return number.decimalValue
    }

    private func safeToSpendWeek(for state: FinanceDashboardState) -> Decimal {
        let weeksLeft = max(1, Int(ceil(Double(max(state.remainingDaysInMonth, 1)) / 7.0)))
        return state.budgetSnapshot.remaining / Decimal(weeksLeft)
    }

    private func recurringCandidates() -> [(merchant: String, count: Int, averageAmount: Decimal, nextChargeDate: Date?)] {
        let expenses = viewModel.ledger?.expenses ?? []
        let grouped = Dictionary(grouping: expenses) { expense in
            expense.merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return grouped
            .filter { key, value in !key.isEmpty && value.count >= 2 }
            .map { key, value in
                let sorted = value.sorted { $0.date < $1.date }
                let total = sorted.reduce(Decimal.zero) { $0 + $1.amount }
                return (
                    merchant: key,
                    count: sorted.count,
                    averageAmount: total / Decimal(sorted.count),
                    nextChargeDate: estimatedRecurringNextDate(from: sorted)
                )
            }
            .sorted { lhs, rhs in
                lhs.count > rhs.count || (
                    lhs.count == rhs.count &&
                    lhs.merchant.localizedCaseInsensitiveCompare(rhs.merchant) == .orderedAscending
                )
            }
    }

    private func recurringCandidateDetail(_ candidate: (merchant: String, count: Int, averageAmount: Decimal, nextChargeDate: Date?)) -> String {
        let frequency = "\(candidate.count)x recently"
        let average = "avg \(candidate.averageAmount.formatted(.currency(code: currencyCode)))"
        if let nextChargeDate = candidate.nextChargeDate {
            let nextCharge = "next \(nextChargeDate.formatted(date: .abbreviated, time: .omitted))"
            return "\(frequency) · \(average) · \(nextCharge)"
        }
        return "\(frequency) · \(average) · pattern building"
    }

    private func recentCumulativeTrendRows() -> [TrendPoint] {
        let calendar = Calendar.autoupdatingCurrent
        let expenses = viewModel.ledger?.expenses ?? []
        var cumulative = Decimal.zero
        let startDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -29, to: .now) ?? .now)

        return (0..<30).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else { return nil }
            let label = date.formatted(.dateTime.month(.abbreviated).day())
            let total = expenses
                .filter { calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(Decimal.zero) { $0 + $1.amount }
            cumulative += total
            return TrendPoint(id: label, label: label, total: total, cumulative: cumulative)
        }
    }

    private func questStatus(for mission: GrowthMission) -> QuestBoardStatus {
        if let override = questStatusOverrides[mission.id] {
            return override
        }

        switch mission.status {
        case .pending:
            return .pending
        case .ready:
            return .ready
        case .completed:
            return .completed
        }
    }

    private func questModeLabel(for growth: DashboardGrowthSnapshot) -> String {
        switch growth.riskState {
        case .calm:
            return "Gentle"
        case .watch:
            return "Active"
        case .urgent:
            return "Recovery"
        }
    }

    private func completeQuest(_ mission: GrowthMission) {
        questStatusOverrides[mission.id] = .completed
        questFeedback = "Completed \(mission.title.lowercased()) locally for +\(mission.rewardXP) XP."
    }

    private func skipQuest(_ mission: GrowthMission) {
        guard questSkipTokensRemaining > 0 else {
            questFeedback = "No skip tokens left right now."
            return
        }
        questStatusOverrides[mission.id] = .skipped
        questSkipTokensRemaining -= 1
        questFeedback = "Skipped \(mission.title.lowercased()) with a local token. \(questSkipTokensRemaining) skip token\(questSkipTokensRemaining == 1 ? "" : "s") left."
    }

    private func estimatedRecurringNextDate(from expenses: [ExpenseRecord]) -> Date? {
        guard expenses.count >= 2 else { return nil }

        let calendar = Calendar.autoupdatingCurrent
        let sorted = expenses.sorted { $0.date < $1.date }
        let intervals = zip(sorted.dropFirst(), sorted).map { current, previous in
            current.date.timeIntervalSince(previous.date)
        }
        guard !intervals.isEmpty else { return nil }

        let averageIntervalDays = intervals.reduce(0, +) / Double(intervals.count) / 86_400
        let nextInDays = max(7, Int(round(averageIntervalDays)))
        return calendar.date(byAdding: .day, value: nextInDays, to: sorted.last?.date ?? .now)
    }

    private func cumulativeTrendSparkline(rows: [TrendPoint]) -> some View {
        GeometryReader { proxy in
            let size = proxy.size
            let plottedPoints = trendPoints(for: rows, in: size)
            let baselineY = max(size.height - 14, 14)

            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(BrandTheme.surfaceTint)

                if plottedPoints.count > 1 {
                    Path { path in
                        path.move(to: plottedPoints[0])
                        for point in plottedPoints.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(
                        BrandTheme.primary,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )

                    Path { path in
                        guard let first = plottedPoints.first, let last = plottedPoints.last else { return }
                        path.move(to: CGPoint(x: first.x, y: baselineY))
                        path.addLine(to: first)
                        for point in plottedPoints.dropFirst() {
                            path.addLine(to: point)
                        }
                        path.addLine(to: CGPoint(x: last.x, y: baselineY))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [BrandTheme.primary.opacity(0.24), BrandTheme.primary.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                ForEach(Array(plottedPoints.enumerated()), id: \.offset) { index, point in
                    Circle()
                        .fill(index == plottedPoints.count - 1 ? BrandTheme.primary : BrandTheme.surface)
                        .overlay(
                            Circle()
                                .stroke(BrandTheme.primary, lineWidth: 1.5)
                        )
                        .frame(width: 9, height: 9)
                        .position(point)
                }
            }
        }
        .frame(height: 180)
    }

    private func trendPoints(for rows: [TrendPoint], in size: CGSize) -> [CGPoint] {
        guard !rows.isEmpty else { return [] }

        let width = max(size.width, 1)
        let height = max(size.height, 1)
        let xPadding: CGFloat = 14
        let yPadding: CGFloat = 14
        let usableWidth = max(width - xPadding * 2, 1)
        let usableHeight = max(height - yPadding * 2, 1)
        let maxValue = max(NSDecimalNumber(decimal: rows.map(\.cumulative).max() ?? 1).doubleValue, 1)
        let denominator = max(rows.count - 1, 1)

        return rows.enumerated().map { index, row in
            let x = xPadding + usableWidth * CGFloat(index) / CGFloat(denominator)
            let value = NSDecimalNumber(decimal: row.cumulative).doubleValue
            let ratio = min(max(value / maxValue, 0), 1)
            let y = yPadding + usableHeight * CGFloat(1 - ratio)
            return CGPoint(x: x, y: y)
        }
    }
}

private enum DailyCheckInMood: String, CaseIterable, Identifiable {
    case calm
    case neutral
    case stressed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm: return "Calm"
        case .neutral: return "Neutral"
        case .stressed: return "Stressed"
        }
    }

    var systemImage: String {
        switch self {
        case .calm: return "leaf.fill"
        case .neutral: return "face.smiling"
        case .stressed: return "exclamationmark.triangle.fill"
        }
    }

    var summary: String {
        switch self {
        case .calm: return "Calm"
        case .neutral: return "Neutral"
        case .stressed: return "Under pressure"
        }
    }
}

private enum WeeklyDecisionSurface: String, CaseIterable, Identifiable {
    case trimTopCategory
    case delayPurchase
    case increasePayment

    var id: String { rawValue }

    var title: String {
        switch self {
        case .trimTopCategory: return "Trim top category"
        case .delayPurchase: return "Delay a purchase"
        case .increasePayment: return "Increase a payment"
        }
    }

    var systemImage: String {
        switch self {
        case .trimTopCategory: return "scissors"
        case .delayPurchase: return "clock.arrow.circlepath"
        case .increasePayment: return "arrow.up.circle.fill"
        }
    }

    func detail(for state: FinanceDashboardState, growth: DashboardGrowthSnapshot, weekSpend: Decimal, nextBill: BillRecord?) -> String {
        switch self {
        case .trimTopCategory:
            let category = state.topCategory?.category.rawValue.lowercased() ?? "your top category"
            return "The quickest relief is usually inside \(category). Keep \(weekSpend.formatted(.currency(code: "USD"))) of weekly spend from turning into another spike."
        case .delayPurchase:
            return growth.riskState == .urgent
                ? "Push one discretionary expense to next week and protect cash before the month tightens further."
                : "Delay one non-essential purchase so this week stays calm and your runway stays comfortable."
        case .increasePayment:
            if let bill = nextBill {
                return "Use the current runway to move more toward \(bill.title) and keep future obligations lighter."
            }
            return "If bills are quiet, move extra cash into savings or the next account bucket."
        }
    }
}

private enum QuestBoardStatus: String {
    case pending = "Pending"
    case ready = "Ready"
    case completed = "Completed"
    case skipped = "Skipped"

    var tint: Color {
        switch self {
        case .pending:
            return BrandTheme.muted
        case .ready:
            return Color(red: 0.78, green: 0.53, blue: 0.16)
        case .completed:
            return BrandTheme.primary
        case .skipped:
            return BrandTheme.muted
        }
    }
}

private struct TrendPoint: Identifiable {
    let id: String
    let label: String
    let total: Decimal
    let cumulative: Decimal
}

private struct CheckInChipStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .foregroundStyle(isSelected ? .white : BrandTheme.ink)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? BrandTheme.primary : BrandTheme.surfaceTint)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(isSelected ? BrandTheme.primary : BrandTheme.line.opacity(0.9), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct WeeklyDecisionChipStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(isSelected ? .white : BrandTheme.ink)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? BrandTheme.primary : BrandTheme.surfaceTint)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? BrandTheme.primary : BrandTheme.line.opacity(0.9), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

private struct DashboardMissionCard: View {
    let mission: GrowthMission
    let status: QuestBoardStatus
    let skipTokensRemaining: Int
    let onComplete: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                BrandBadge(text: mission.cadenceLabel, systemImage: mission.systemImage)
                Spacer()
                Text(status.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(status.tint)
            }

            Text(mission.title)
                .font(.title3.weight(.bold))
                .foregroundStyle(BrandTheme.ink)

            HStack(spacing: 8) {
                MissionMetaChip(title: inferredFocusTag, systemImage: "target")
                MissionMetaChip(title: mission.cadenceLabel, systemImage: "arrow.triangle.2.circlepath")
                MissionMetaChip(title: inferredDifficulty, systemImage: "dial.medium")
                MissionMetaChip(title: inferredMinutes, systemImage: "clock")
            }

            Text(mission.detail)
                .font(.subheadline)
                .foregroundStyle(BrandTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            ProgressView(value: mission.progressRatio)
                .tint(status.tint)

            HStack {
                Text(mission.progressText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BrandTheme.ink)
                Spacer()
                Text("+\(mission.rewardXP) XP")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(status.tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Why now")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BrandTheme.muted)
                Text(mission.coachNote)
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
            }

            if status == .completed || status == .skipped {
                BrandFeatureRow(
                    systemImage: status == .completed ? "checkmark.seal.fill" : "forward.fill",
                    title: status == .completed ? "Quest completed" : "Quest skipped",
                    detail: status == .completed
                        ? "The reward is counted locally and the next move can surface from the ledger."
                        : "Skip tokens stay visible at the top of the board so the next call stays honest."
                )
            } else {
                HStack(spacing: 10) {
                    Button("Complete") {
                        onComplete()
                    }
                    .buttonStyle(PrimaryCTAStyle())

                    Button("Skip") {
                        onSkip()
                    }
                    .buttonStyle(SecondaryCTAStyle())
                    .disabled(skipTokensRemaining == 0)
                }

                Text(skipTokensRemaining == 0 ? "No skip tokens left." : "Skipping uses one local token.")
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(BrandTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(BrandTheme.line.opacity(0.78), lineWidth: 1)
        )
        .shadow(color: BrandTheme.shadow.opacity(0.06), radius: 12, x: 0, y: 8)
    }

    private var statusTint: Color {
        status.tint
    }

    private var inferredFocusTag: String {
        let text = "\(mission.title) \(mission.detail) \(mission.coachNote)".lowercased()
        if text.contains("bill") {
            return "Bills"
        }
        if text.contains("rule") {
            return "Rules"
        }
        if text.contains("account") {
            return "Accounts"
        }
        if text.contains("streak") || text.contains("check") {
            return "Check-in"
        }
        if text.contains("spend") || text.contains("expense") {
            return "Spend"
        }
        return "Focus"
    }

    private var inferredDifficulty: String {
        switch status {
        case .ready:
            return "Easy"
        case .pending:
            return mission.rewardXP >= 60 ? "Medium" : "Light"
        case .completed:
            return "Done"
        case .skipped:
            return "Paused"
        }
    }

    private var inferredMinutes: String {
        let minutes = max(5, min(30, (mission.progressTarget * 2) + (mission.rewardXP / 12)))
        return "\(minutes)m"
    }
}

private struct MissionMetaChip: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(BrandTheme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(BrandTheme.surfaceTint)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(BrandTheme.line.opacity(0.82), lineWidth: 1)
            )
    }
}

struct GrowthTrophyPlate: View {
    let trophy: GrowthTrophy
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: trophy.unlocked
                            ? [BrandTheme.accent.opacity(0.95), BrandTheme.glow.opacity(0.8)]
                            : [BrandTheme.surfaceTint, BrandTheme.surface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .stroke(trophy.unlocked ? BrandTheme.primary.opacity(0.22) : BrandTheme.line.opacity(0.9), lineWidth: 1)

            BrandAssetImage(
                source: BrandAssetCatalog.shared.badge(named: trophy.hybridBadgeAsset),
                fallbackSystemImage: trophy.systemImage,
                fallbackTint: trophy.unlocked ? BrandTheme.primary : BrandTheme.muted
            )
            .aspectRatio(contentMode: .fit)
            .padding(size * 0.16)
            .saturation(trophy.unlocked ? 1 : 0.12)
            .opacity(trophy.unlocked ? 1 : 0.72)

            if !trophy.unlocked {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.system(size: size * 0.18, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(size * 0.12)
                            .background(BrandTheme.ink.opacity(0.78))
                            .clipShape(Circle())
                    }
                }
                .padding(size * 0.08)
            }
        }
        .frame(width: size, height: size)
    }
}

struct DashboardTimelineRow: View {
    let event: GrowthEvent

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(BrandTheme.accent.opacity(0.22))
                Image(systemName: event.systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BrandTheme.primary)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text(event.detail)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                Text(event.occurredAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BrandTheme.primary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BrandTheme.surfaceTint)
        )
    }
}
