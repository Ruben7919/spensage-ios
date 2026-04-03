import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: AppViewModel
    var onOpenGuide: (() -> Void)? = nil
    @State private var isPresentingGuide = false
    @State private var hasPresentedInitialGuide = false

    private let currencyCode = "USD"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header

                if let state = viewModel.dashboardState {
                    heroCard(for: state, growth: growthSnapshot)
                    coachCard(growth: growthSnapshot)
                    missionsSection(growth: growthSnapshot)
                    trophyShowcaseSection(growth: growthSnapshot)
                    timelineSection(growth: growthSnapshot)
                    summaryGrid(for: state, growth: growthSnapshot)
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
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(
                title: "Missions",
                detail: "Local-first quests tuned to the state of this ledger."
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(growth.missions) { mission in
                        DashboardMissionCard(mission: mission)
                            .frame(width: 292)
                    }
                }
                .padding(.vertical, 2)
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
}

private struct DashboardMissionCard: View {
    let mission: GrowthMission

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                BrandBadge(text: mission.cadenceLabel, systemImage: mission.systemImage)
                Spacer()
                Text(mission.status.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusTint)
            }

            Text(mission.title)
                .font(.title3.weight(.bold))
                .foregroundStyle(BrandTheme.ink)

            Text(mission.detail)
                .font(.subheadline)
                .foregroundStyle(BrandTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            ProgressView(value: mission.progressRatio)
                .tint(statusTint)

            HStack {
                Text(mission.progressText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BrandTheme.ink)
                Spacer()
                Text("+\(mission.rewardXP) XP")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusTint)
            }

            Text(mission.coachNote)
                .font(.footnote)
                .foregroundStyle(BrandTheme.muted)
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
        switch mission.status {
        case .pending:
            return BrandTheme.muted
        case .ready:
            return Color(red: 0.78, green: 0.53, blue: 0.16)
        case .completed:
            return BrandTheme.primary
        }
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
