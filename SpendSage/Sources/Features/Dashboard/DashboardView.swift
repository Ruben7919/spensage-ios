import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: AppViewModel
    @AppStorage(AppCurrencyFormat.defaultsKey) private var currencyCode = AppCurrencyFormat.defaultCode
    var onOpenGuide: (() -> Void)? = nil

    @State private var isPresentingGuide = false
    @State private var hasPresentedInitialGuide = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                heroCard

                if let state = viewModel.dashboardState {
                    todayCard(for: state)
                    strategyCard(growth: growthSnapshot)
                    recentSpendCard(for: state)
                    missionSummaryCard(growth: growthSnapshot)
                    if !growthSnapshot.highlightedTrophies.isEmpty {
                        trophiesSection(growth: growthSnapshot)
                    }

                    ExperienceDisclosureCard(
                        title: "Power view",
                        summary: "Bills and deeper money analysis stay here, while the game loop remains visible above.",
                        character: .tikki,
                        expression: .thinking
                    ) {
                        if !viewModel.bills.isEmpty {
                            billsSection
                        }

                        if !state.categoryBreakdown.isEmpty {
                            categorySection(for: state)
                        }
                    }
                } else {
                    loadingCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
        .background(FinanceScreenBackground())
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

    private var heroCard: some View {
        JourneyHeroCard(
            eyebrow: "Daily money loop",
            title: growthSnapshot.greetingTitle,
            summary: "Start with one clear number, one next move, and the part of the month that needs attention now.",
            character: .manchas,
            expression: dashboardExpression,
            sceneKey: "guide_01_dashboard_game_manchas",
            scenePrompt: nil,
            metrics: [
                BrandHeroMetric(
                    title: "This week",
                    value: weeklySafeToSpendValue,
                    systemImage: "banknote.fill"
                ),
                BrandHeroMetric(
                    title: "Streak",
                    value: "\(growthSnapshot.streakDays)d",
                    systemImage: "flame.fill"
                ),
                BrandHeroMetric(
                    title: "Days left",
                    value: "\(viewModel.dashboardState?.remainingDaysInMonth ?? 0)",
                    systemImage: "calendar"
                )
            ]
        ) {
            Button("Add expense") {
                viewModel.presentAddExpense()
            }
            .buttonStyle(PrimaryCTAStyle())

            Button("Budget wizard") {
                viewModel.presentBudgetWizard()
            }
            .buttonStyle(SecondaryCTAStyle())

            guideButton
        }
    }

    private var guideButton: some View {
        Group {
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

    private func todayCard(for state: FinanceDashboardState) -> some View {
        ExperienceSectionCard(
            title: "Today",
            summary: growthSnapshot.coachBody,
            badgeText: growthSnapshot.riskState.label,
            badgeSystemImage: "sparkles"
        ) {
            BrandFeatureRow(
                systemImage: "banknote.fill",
                title: "Safe to spend now",
                detail: AppLocalization.localized(
                    "You still have %@ left in the monthly plan.",
                    arguments: state.budgetSnapshot.remaining.formatted(.currency(code: currencyCode))
                )
            )

            BrandFeatureRow(
                systemImage: "arrow.triangle.branch",
                title: "Best next move",
                detail: growthSnapshot.coachAction
            )

            ProgressView(value: min(max(state.utilizationRatio, 0), 1))
                .tint(BrandTheme.primary)
        }
    }

    private func strategyCard(growth: DashboardGrowthSnapshot) -> some View {
        GuidedSectionCard(
            title: "Savings playbook",
            summary: "A short list of local moves that can protect cash without turning the dashboard into a dense report.",
            character: .mei,
            expression: growth.riskState == .urgent ? .warning : .thinking,
            systemImage: "brain.head.profile"
        ) {
            if growth.strategies.isEmpty {
                FinanceEmptyStateCard(
                    title: "Savings strategies will show up here",
                    summary: "Once the ledger has a little more history, the coach will surface the best money-saving move for this week.",
                    systemImage: "sparkles"
                )
            } else {
                ForEach(growth.strategies) { strategy in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 12) {
                            Label(strategy.title, systemImage: strategy.systemImage)
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)
                                .labelStyle(.titleAndIcon)

                            Spacer(minLength: 0)

                            BrandBadge(text: strategy.badgeText, systemImage: strategy.badgeSystemImage)
                        }

                        Text(strategy.detail)
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(strategy.footnote)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(BrandTheme.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(BrandTheme.surfaceTint)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(BrandTheme.line.opacity(0.82), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func missionSummaryCard(growth: DashboardGrowthSnapshot) -> some View {
        GuidedSectionCard(
            title: "Mission board",
            summary: "Keep the app feeling game-like, but only surface the few actions that matter right now.",
            character: .manchas,
            expression: .excited,
            systemImage: "checklist"
        ) {
            if growth.missions.isEmpty {
                FinanceEmptyStateCard(
                    title: "No missions yet",
                    summary: "Add your first activity and the game loop will wake up here.",
                    systemImage: "sparkles"
                )
            } else {
                ForEach(growth.missions.prefix(3)) { mission in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(mission.title)
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)
                            Spacer()
                            BrandBadge(text: mission.status.localizedTitle, systemImage: mission.systemImage)
                        }

                        Text(mission.detail)
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        ProgressView(value: mission.progressRatio)
                            .tint(BrandTheme.primary)

                        Text("\(mission.progressText) · \(mission.rewardXP) XP")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(BrandTheme.muted)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(BrandTheme.surfaceTint)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(BrandTheme.line.opacity(0.82), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func recentSpendCard(for state: FinanceDashboardState) -> some View {
        GuidedSectionCard(
            title: "Recent activity",
            summary: "Your latest entries and the shape of the month in one place.",
            character: .mei,
            expression: .thinking,
            systemImage: "list.bullet.rectangle"
        ) {
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
                    title: "Average",
                    value: state.averageExpense.formatted(.currency(code: currencyCode)),
                    systemImage: "chart.bar.fill"
                )
            }

            if state.recentExpenses.isEmpty {
                FinanceEmptyStateCard(
                    title: "Add the first expense",
                    summary: "Once the ledger moves, your recent activity and category signals will show up here.",
                    systemImage: "square.and.pencil"
                )
            } else {
                ForEach(state.recentExpenses.prefix(5)) { expense in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(BrandTheme.accent.opacity(0.18))
                            Image(systemName: "receipt.fill")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(BrandTheme.primary)
                        }
                        .frame(width: 42, height: 42)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(expense.title)
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)
                            Text(
                                AppLocalization.localized(
                                    "%@ · %@",
                                    arguments: localizedCategoryName(expense.category),
                                    expense.date.formatted(date: .abbreviated, time: .omitted)
                                )
                            )
                                .font(.subheadline)
                                .foregroundStyle(BrandTheme.muted)
                        }

                        Spacer(minLength: 0)

                        Text(expense.amount.formatted(.currency(code: currencyCode)))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(BrandTheme.ink)
                    }
                }
            }
        }
    }

    private var billsSection: some View {
        ExperienceSectionCard(
            title: "Bills radar",
            summary: "Upcoming due dates stay tucked away until you need them.",
            badgeText: "\(viewModel.bills.count)",
            badgeSystemImage: "calendar.badge.clock"
        ) {
            ForEach(viewModel.bills.prefix(3)) { bill in
                BrandFeatureRow(
                    systemImage: bill.paymentState(referenceDate: .now, ledger: viewModel.ledger).symbolName,
                    title: bill.title,
                    detail: "\(bill.amount.formatted(.currency(code: currencyCode))) · \(FinanceToolFormatting.dueDateText(for: bill, ledger: viewModel.ledger))"
                )
            }
        }
    }

    private func categorySection(for state: FinanceDashboardState) -> some View {
        ExperienceSectionCard(
            title: "Category pressure",
            summary: "The top categories are the fastest way to see where the month is leaning.",
            badgeText: state.topCategory?.category.localizedTitle ?? "Mix",
            badgeSystemImage: state.topCategory?.category.symbolName ?? "chart.pie.fill"
        ) {
            ForEach(state.categoryBreakdown.prefix(4)) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(item.category.localizedTitle, systemImage: item.category.symbolName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(BrandTheme.ink)
                        Spacer()
                        Text(item.total.formatted(.currency(code: currencyCode)))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(BrandTheme.ink)
                    }

                    ProgressView(value: categoryProgress(item.total, total: state.budgetSnapshot.monthlySpent))
                        .tint(BrandTheme.primary)

                    Text(categoryCountLabel(for: item.count))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.muted)
                }
            }
        }
    }

    private func trophiesSection(growth: DashboardGrowthSnapshot) -> some View {
        ExperienceSectionCard(
            title: "Recent trophies",
            summary: "Unlocked wins stay out of the way, but they are still part of the game loop.",
            badgeText: "\(growth.highlightedTrophies.count)",
            badgeSystemImage: "trophy.fill"
        ) {
            ForEach(growth.highlightedTrophies.prefix(3)) { trophy in
                BrandFeatureRow(
                    systemImage: trophy.systemImage,
                    title: trophy.title,
                    detail: trophy.celebration
                )
            }
        }
    }

    private var loadingCard: some View {
        MascotLoadingCard(
            badgeText: "Loading dashboard",
            title: "Loading dashboard",
            summary: "Pulling together the local ledger, coach guidance, and category signals.",
            character: .manchas,
            expression: .excited
        )
    }

    private var dashboardExpression: BrandExpression {
        switch growthSnapshot.riskState {
        case .calm:
            return .happy
        case .watch:
            return .thinking
        case .urgent:
            return .warning
        }
    }

    private var weeklySafeToSpendValue: String {
        guard let state = viewModel.dashboardState else { return Decimal.zero.formatted(.currency(code: currencyCode)) }
        return safeToSpendWeek(for: state).formatted(.currency(code: currencyCode))
    }

    private func safeToSpendWeek(for state: FinanceDashboardState) -> Decimal {
        let remaining = state.budgetSnapshot.remaining
        let daysLeft = max(state.remainingDaysInMonth, 1)
        let perDay = decimalDivide(remaining, by: daysLeft)
        return max(0, perDay * Decimal(7))
    }

    private func decimalDivide(_ value: Decimal, by divisor: Int) -> Decimal {
        guard divisor > 0 else { return 0 }
        return value / Decimal(divisor)
    }

    private func categoryProgress(_ value: Decimal, total: Decimal) -> Double {
        guard total > 0 else { return 0 }
        let lhs = NSDecimalNumber(decimal: value).doubleValue
        let rhs = NSDecimalNumber(decimal: total).doubleValue
        guard rhs > 0 else { return 0 }
        return min(1, max(0, lhs / rhs))
    }

    private func categoryCountLabel(for count: Int) -> String {
        if count == 1 {
            return AppLocalization.localized("%d transaction", arguments: count)
        }
        return AppLocalization.localized("%d transactions", arguments: count)
    }

    private func localizedCategoryName(_ rawValue: String) -> String {
        ExpenseCategory.allCases.first(where: { $0.rawValue == rawValue })?.localizedTitle ?? rawValue.appLocalized
    }
}
