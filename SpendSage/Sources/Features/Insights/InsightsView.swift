import Charts
import SwiftUI
import UIKit

struct InsightsView: View {
    @ObservedObject var viewModel: AppViewModel
    @AppStorage(AppCurrencyFormat.defaultsKey) private var currencyCode = AppCurrencyFormat.defaultCode

    @State private var exportNotice: String?
    @State private var selectedPeriod: InsightsPeriod = .week
    @State private var selectedMetric: InsightsMetric = .expense
    @State private var generatedInsight: GeneratedInsightResult?
    @State private var isPresentingGuide = false
    @State private var budgetDraft: [ExpenseCategory: String] = [:]
    @State private var plannerNotice: String?

    private var currentState: FinanceDashboardState? {
        viewModel.dashboardState
    }

    private var ledger: LocalFinanceLedger? {
        viewModel.ledger
    }

    private var recentExpenses: [ExpenseRecord] {
        (ledger?.expenses ?? []).sorted { $0.date > $1.date }
    }

    private var monthExpenses: [ExpenseRecord] {
        let calendar = Calendar.autoupdatingCurrent
        return recentExpenses.filter { calendar.isDate($0.date, equalTo: .now, toGranularity: .month) }
    }

    private var monthSpending: Decimal {
        currentState?.budgetSnapshot.monthlySpent ?? monthExpenses.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var categoryBreakdown: [CategoryBreakdown] {
        currentState?.categoryBreakdown ?? ledger?.categoryBreakdown(limit: 6) ?? []
    }

    private var nextBill: BillRecord? {
        ledger?.upcomingBills().first
    }

    private var filteredExpenses: [ExpenseRecord] {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()

        return recentExpenses.filter { expense in
            switch selectedPeriod {
            case .day:
                return calendar.isDate(expense.date, inSameDayAs: now)
            case .week:
                return calendar.isDate(expense.date, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(expense.date, equalTo: now, toGranularity: .month)
            }
        }
    }

    private var filteredMetricTotal: Decimal {
        filteredExpenses.reduce(Decimal.zero) { partial, expense in
            switch selectedMetric {
            case .expense:
                return partial + max(expense.amount, 0)
            case .refund:
                return partial + (expense.amount < 0 ? -expense.amount : 0)
            case .income:
                return partial + min(expense.amount, 0) * -1
            }
        }
    }

    private var expenseTotal: Decimal {
        filteredExpenses.reduce(Decimal.zero) { $0 + max($1.amount, 0) }
    }

    private var refundTotal: Decimal {
        filteredExpenses.reduce(Decimal.zero) { $0 + ($1.amount < 0 ? -$1.amount : 0) }
    }

    private var incomeTotal: Decimal {
        if let monthlyIncome = currentState?.budgetSnapshot.monthlyIncome, monthlyIncome > 0 {
            switch selectedPeriod {
            case .day:
                return monthlyIncome / Decimal(max(daysInMonth, 1))
            case .week:
                return monthlyIncome / 4
            case .month:
                return monthlyIncome
            }
        }

        return 0
    }

    private var assetsTotal: Decimal {
        ledger?.liquidAccountBalance() ?? 0
    }

    private var liabilitiesTotal: Decimal {
        ledger?.creditExposure() ?? 0
    }

    private var netWorthTotal: Decimal {
        assetsTotal - liabilitiesTotal
    }

    private var daysInMonth: Int {
        let calendar = Calendar.autoupdatingCurrent
        guard let range = calendar.range(of: .day, in: .month, for: .now) else { return 0 }
        return range.count
    }

    private var daysElapsedInMonth: Int {
        let calendar = Calendar.autoupdatingCurrent
        return max(calendar.component(.day, from: .now), 1)
    }

    private var spendPerDay: Decimal {
        guard daysElapsedInMonth > 0 else { return 0 }
        return monthSpending / Decimal(daysElapsedInMonth)
    }

    private var budgetPerDay: Decimal {
        guard daysInMonth > 0 else { return 0 }
        return (currentState?.budgetSnapshot.monthlyBudget ?? 0) / Decimal(daysInMonth)
    }

    private var savingsRate: Double? {
        guard let monthlyIncome = currentState?.budgetSnapshot.monthlyIncome, monthlyIncome > 0 else {
            return nil
        }

        let income = NSDecimalNumber(decimal: monthlyIncome).doubleValue
        let spent = NSDecimalNumber(decimal: currentState?.budgetSnapshot.monthlySpent ?? monthSpending).doubleValue
        guard income > 0 else { return nil }
        return max(-1, min(1, (income - spent) / income))
    }

    private var monthlyTrendRows: [TrendRow] {
        let calendar = Calendar.autoupdatingCurrent

        return (0..<6).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: -offset, to: .now) else { return nil }
            let label = date.formatted(.dateTime.month(.abbreviated))
            let expense = recentExpenses
                .filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }
                .reduce(Decimal.zero) { $0 + max($1.amount, 0) }
            let net = (currentState?.budgetSnapshot.monthlyIncome ?? 0) - expense

            return TrendRow(
                label: label,
                expense: NSDecimalNumber(decimal: expense).doubleValue,
                net: NSDecimalNumber(decimal: net).doubleValue
            )
        }
    }

    private var selectedSeries: [InsightsSeriesPoint] {
        buildSeries(for: selectedPeriod, metric: selectedMetric, expenses: recentExpenses)
    }

    private var plannerCategories: [ExpenseCategory] {
        Array(ExpenseCategory.allCases.prefix(6))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                heroCard

                if let currentState {
                    filtersCard
                    overviewCard(for: currentState)
                    chartCard
                    categoryCard(for: currentState)
                    ExperienceDisclosureCard(
                        title: "Ludo's deeper tools",
                        summary: "Planner edits, exports, and related tools stay here when you want more control.",
                        character: .mei,
                        expression: .thinking
                    ) {
                        plannerCard(for: currentState)
                        exportCard(for: currentState)
                        toolsCard
                    }
                } else {
                    loadingCard
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
        .navigationTitle("Insights".appLocalized)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $isPresentingGuide) {
            GuideSheet(guide: GuideLibrary.guide(.insights))
        }
        .task {
            seedBudgetDraftIfNeeded()
        }
        .overlay(alignment: .bottom) {
            if let exportNotice {
                Text(exportNotice)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(BrandTheme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(BrandTheme.surface)
                    .clipShape(Capsule(style: .continuous))
                    .shadow(color: BrandTheme.shadow.opacity(0.12), radius: 12, x: 0, y: 6)
                    .padding(.bottom, 18)
            }
        }
    }

    private var heroCard: some View {
        BrandStoryCard(
            surface: .insights,
            title: "Insights",
            message: "See what changed, which category needs attention, and which next move makes the month easier to control.",
            highlights: [
                selectedPeriod.title,
                selectedMetric.title,
                currentState.map { paceLabel(for: $0) } ?? "Loading".appLocalized
            ]
        )
    }

    private var filtersCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                CompactSectionHeader(
                    title: "Range and focus",
                    detail: "Choose the time window and the number you want to understand."
                )

                Picker("Period", selection: $selectedPeriod) {
                    ForEach(InsightsPeriod.allCases) { period in
                        Text(period.title).tag(period)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Metric", selection: $selectedMetric) {
                    ForEach(InsightsMetric.allCases) { metric in
                        Text(metric.title).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private func overviewCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                CompactSectionHeader(
                    title: "What matters right now",
                    detail: "Keep the summary practical: total, remaining room, and one clear pace check."
                )

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(
                        title: "Selected total",
                        value: filteredMetricTotal.formatted(.currency(code: currencyCode)),
                        systemImage: selectedMetric.systemImage
                    )
                    BrandMetricTile(
                        title: "Remaining",
                        value: state.budgetSnapshot.remaining.formatted(.currency(code: currencyCode)),
                        systemImage: "banknote.fill"
                    )
                    BrandMetricTile(
                        title: "Net worth",
                        value: netWorthTotal.formatted(.currency(code: currencyCode)),
                        systemImage: "scale.3d"
                    )
                    BrandMetricTile(
                        title: "Savings rate",
                        value: savingsRate.map { String(format: "%.0f%%", $0 * 100) } ?? "n/a".appLocalized,
                        systemImage: "percent"
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Budget pace")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(BrandTheme.ink)

                        Spacer()

                        Text(paceLabel(for: state))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(BrandTheme.primary)
                    }

                    ProgressView(value: min(max(state.utilizationRatio, 0), 1))
                        .tint(BrandTheme.primary)

                    HStack {
                        Text(AppLocalization.localized("Spend/day %@", arguments: spendPerDay.formatted(.currency(code: currencyCode))))
                        Spacer()
                        Text(AppLocalization.localized("Budget/day %@", arguments: budgetPerDay.formatted(.currency(code: currencyCode))))
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(BrandTheme.muted)
                }

                if let nextBill {
                    BrandFeatureRow(
                        systemImage: "calendar.badge.clock",
                        title: "Next bill",
                        detail: "\(nextBill.title) · \(FinanceToolFormatting.dueDateText(for: nextBill, ledger: ledger))"
                    )
                }

                MascotSpeechCard(
                    character: .mei,
                    expression: state.utilizationRatio >= 1 ? .warning : .thinking,
                    title: "Ludo",
                    message: generatedSuggestion(for: state).summary
                )
            }
        }
    }

    private var chartCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                CompactSectionHeader(
                    title: "Main chart",
                    detail: "One visual is enough when it makes the pattern obvious."
                )

                if selectedSeries.isEmpty {
                    BrandFeatureRow(
                        systemImage: "chart.bar.fill",
                        title: "No chart signal yet",
                        detail: "Add a few expenses and the chart will start showing a clearer pattern."
                    )
                } else {
                    Chart(selectedSeries) { row in
                        BarMark(
                            x: .value("Bucket", row.label),
                            y: .value("Value", row.value)
                        )
                        .foregroundStyle(BrandTheme.primary)
                        .cornerRadius(6)
                    }
                    .frame(height: 220)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }

                    if !monthlyTrendRows.isEmpty {
                        HStack(spacing: 12) {
                            BrandMetricTile(
                                title: "Avg spend",
                                value: averageMonthlySpend.formatted(.currency(code: currencyCode)),
                                systemImage: "chart.line.uptrend.xyaxis"
                            )
                            BrandMetricTile(
                                title: "Best month",
                                value: strongestMonthLabel,
                                systemImage: "trophy.fill"
                            )
                        }
                    }
                }
            }
        }
    }

    private func categoryCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                CompactSectionHeader(
                    title: "Category pressure",
                    detail: "Focus on the categories that deserve attention, not every detail at once."
                )

                if categoryBreakdown.isEmpty {
                    BrandFeatureRow(
                        systemImage: "square.grid.2x2.fill",
                        title: "No category signal yet",
                        detail: "The first expenses will reveal where the budget is tilting."
                    )
                } else {
                    ForEach(categoryBreakdown) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(category.category.localizedTitle)
                                    .font(.headline)
                                    .foregroundStyle(BrandTheme.ink)

                                Spacer()

                                Text(category.total.formatted(.currency(code: currencyCode)))
                                    .font(.headline)
                                    .foregroundStyle(BrandTheme.ink)
                            }

                            ProgressView(value: share(for: category, total: monthSpending))
                                .tint(BrandTheme.primary)

                            Text(categoryCountLabel(for: category.count))
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BrandTheme.muted)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(BrandTheme.surfaceTint)
                        )
                    }
                }

                ForEach(insightRows(for: state)) { row in
                    BrandFeatureRow(
                        systemImage: row.systemImage,
                        title: row.title,
                        detail: row.detail
                    )
                }
            }
        }
    }

    private func plannerCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                CompactSectionHeader(
                    title: "Budget planner",
                    detail: "Turn the analysis into one realistic budget action."
                )

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(plannerCategories, id: \.rawValue) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category.localizedTitle)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BrandTheme.muted)

                            TextField(
                                "0",
                                text: Binding(
                                    get: { budgetDraft[category] ?? "" },
                                    set: { budgetDraft[category] = $0 }
                                )
                            )
                            .keyboardType(.decimalPad)
                            .textInputAutocapitalization(.never)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(BrandTheme.surfaceTint)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
                            )
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button("Apply suggested mix") {
                        budgetDraft = suggestedBudgetDraft(from: state)
                        plannerNotice = "Suggested category mix loaded.".appLocalized
                    }
                    .buttonStyle(SecondaryCTAStyle())

                    Button("Save local budget") {
                        Task {
                            let totalBudget = parsedBudgetDraftTotal()
                            guard totalBudget > 0 else {
                                plannerNotice = "Add at least one category amount before saving.".appLocalized
                                return
                            }

                            await viewModel.saveBudget(
                                monthlyIncome: state.budgetSnapshot.monthlyIncome,
                                monthlyBudget: totalBudget
                            )
                            plannerNotice = "Local budget updated from planner categories.".appLocalized
                        }
                    }
                    .buttonStyle(PrimaryCTAStyle())
                }

                Button("Open budget wizard") {
                    viewModel.presentBudgetWizard()
                }
                .buttonStyle(SecondaryCTAStyle())

                if let plannerNotice {
                    Text(plannerNotice.appLocalized)
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }
            }
        }
    }

    private func exportCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                CompactSectionHeader(
                    title: "Summary and next move",
                    detail: "Keep the takeaway clear and the recommendation easy to act on."
                )

                Button("Generate suggestions") {
                    generatedInsight = generatedSuggestion(for: state)
                }
                .buttonStyle(PrimaryCTAStyle())

                if let generatedInsight {
                    BrandFeatureRow(systemImage: "sparkles", title: "Summary", detail: generatedInsight.summary)

                    ForEach(generatedInsight.alerts, id: \.self) { alert in
                        BrandFeatureRow(systemImage: "exclamationmark.triangle.fill", title: "Alert", detail: alert)
                    }

                    ForEach(generatedInsight.actions, id: \.self) { action in
                        BrandFeatureRow(systemImage: "checkmark.circle.fill", title: "Action", detail: action)
                    }
                }

                HStack(spacing: 12) {
                    Button("Copy summary") {
                        copyExport(LocalLedgerExportComposer.readableSummary(viewModel: viewModel), label: "Summary export copied")
                    }
                    .buttonStyle(SecondaryCTAStyle())

                    Button("Copy snapshot") {
                        copyExport(LocalLedgerExportComposer.jsonSnapshot(viewModel: viewModel), label: "Snapshot export copied")
                    }
                    .buttonStyle(SecondaryCTAStyle())
                }
            }
        }
    }

    private var toolsCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                CompactSectionHeader(
                    title: "Related tools",
                    detail: "Open a deeper tool only when the analysis tells you it matters."
                )

                NavigationLink {
                    FinanceBillsToolView(viewModel: viewModel)
                } label: {
                    QuickActionTile(
                        title: "Bills",
                        detail: "Check recurring obligations and due dates.",
                        systemImage: "calendar.badge.clock"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    FinanceAccountsToolView(viewModel: viewModel)
                } label: {
                    QuickActionTile(
                        title: "Accounts",
                        detail: "Review balances and debt exposure.",
                        systemImage: "wallet.pass.fill"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    FinanceRulesToolView(viewModel: viewModel)
                } label: {
                    QuickActionTile(
                        title: "Rules",
                        detail: "Clean recurring merchants and categories.",
                        systemImage: "line.3.horizontal.decrease.circle.fill"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var loadingCard: some View {
        MascotLoadingCard(
            badgeText: "Loading insights",
            title: "Loading insights",
            summary: "We are preparing your local analysis.",
            character: .mei,
            expression: .thinking
        )
    }

    private var averageMonthlySpend: Decimal {
        guard !monthlyTrendRows.isEmpty else { return 0 }
        let total = monthlyTrendRows.reduce(0.0) { $0 + $1.expense }
        return Decimal(total / Double(monthlyTrendRows.count))
    }

    private var strongestMonthLabel: String {
        monthlyTrendRows.max { $0.net < $1.net }?.label ?? "n/a".appLocalized
    }

    private func share(for category: CategoryBreakdown, total: Decimal) -> Double {
        let totalNumber = NSDecimalNumber(decimal: total).doubleValue
        guard totalNumber > 0 else { return 0 }
        return NSDecimalNumber(decimal: category.total).doubleValue / totalNumber
    }

    private func categoryCountLabel(for count: Int) -> String {
        if count == 1 {
            return AppLocalization.localized("%d transaction", arguments: count)
        }
        return AppLocalization.localized("%d transactions", arguments: count)
    }

    private func copyExport(_ text: String, label: String) {
        UIPasteboard.general.string = text
        exportNotice = label

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            if exportNotice == label {
                exportNotice = nil
            }
        }
    }

    private func generatedSuggestion(for state: FinanceDashboardState) -> GeneratedInsightResult {
        if state.transactionCount == 0 {
            return GeneratedInsightResult(
                summary: "Start with one expense so Insights can generate a more specific summary.".appLocalized,
                alerts: ["No transactions are available yet for pacing or category pressure.".appLocalized],
                actions: ["Add your first expense to unlock the full analysis.".appLocalized]
            )
        }

        if state.utilizationRatio >= 1 {
            return GeneratedInsightResult(
                summary: "You are already over budget this month. Trim the top category first and review the next bill before adding new discretionary spend.".appLocalized,
                alerts: [
                    "Monthly utilization is already above budget.".appLocalized,
                    state.topCategory.map {
                        AppLocalization.localized("%@ is the heaviest category right now.", arguments: $0.category.localizedTitle)
                    } ?? "The top category is adding the strongest pressure.".appLocalized
                ],
                actions: [
                    "Reduce one discretionary purchase in the top category today.".appLocalized,
                    "Review the next bill before the next spend decision.".appLocalized
                ]
            )
        }

        if let topCategory = state.topCategory {
            return GeneratedInsightResult(
                summary: AppLocalization.localized(
                    "%@ is the strongest pressure point right now. Keep the next %d days focused there.",
                    arguments: topCategory.category.localizedTitle,
                    max(state.remainingDaysInMonth, 1)
                ),
                alerts: [
                    AppLocalization.localized(
                        "%@ is leading the month at %@.",
                        arguments: topCategory.category.localizedTitle,
                        topCategory.total.formatted(.currency(code: currencyCode))
                    )
                ],
                actions: [
                    "Hold this category flat for the next few days.".appLocalized,
                    "Open the budget wizard if the current cap feels unrealistic.".appLocalized
                ]
            )
        }

        return GeneratedInsightResult(
            summary: "The month is still calm. Use this window to clean categories, review recurring bills, and lock one budget decision.".appLocalized,
            alerts: ["The ledger looks stable enough to plan ahead instead of reacting.".appLocalized],
            actions: [
                "Clean one recurring merchant rule.".appLocalized,
                "Lock one budget decision while the month is still calm.".appLocalized
            ]
        )
    }

    private func seedBudgetDraftIfNeeded() {
        guard budgetDraft.isEmpty, let currentState else { return }
        budgetDraft = suggestedBudgetDraft(from: currentState)
    }

    private func suggestedBudgetDraft(from state: FinanceDashboardState) -> [ExpenseCategory: String] {
        let totalBudget = state.budgetSnapshot.monthlyBudget
        let fallbackShare = plannerCategories.isEmpty ? 0 : totalBudget / Decimal(plannerCategories.count)

        return Dictionary(uniqueKeysWithValues: plannerCategories.map { category in
            let categorySpend = state.categoryBreakdown.first(where: { $0.category == category })?.total ?? fallbackShare
            let suggested = max(categorySpend, fallbackShare)
            return (category, NSDecimalNumber(decimal: suggested).stringValue)
        })
    }

    private func parsedBudgetDraftTotal() -> Decimal {
        plannerCategories.reduce(Decimal.zero) { partial, category in
            let raw = budgetDraft[category] ?? ""
            let parsed = Decimal(string: raw.replacingOccurrences(of: ",", with: ".")) ?? 0
            return partial + max(parsed, 0)
        }
    }

    private func paceLabel(for state: FinanceDashboardState) -> String {
        if state.transactionCount == 0 {
            return "Kickoff".appLocalized
        }
        if state.utilizationRatio < 0.82 {
            return "Calm pace".appLocalized
        }
        if state.utilizationRatio < 1 {
            return "Watch pace".appLocalized
        }
        return "Over budget".appLocalized
    }

    private func insightRows(for state: FinanceDashboardState) -> [InsightRow] {
        var rows: [InsightRow] = []

        if state.transactionCount == 0 {
            rows.append(
                InsightRow(
                    id: "first-expense",
                    title: "Add the first expense",
                    detail: "One transaction unlocks pacing, category mix, and a more useful monthly analysis.",
                    systemImage: "plus.circle.fill"
                )
            )
        }

        if state.utilizationRatio >= 1 {
            rows.append(
                InsightRow(
                    id: "over-budget",
                    title: "Trim the top category",
                    detail: "Spending is already above the current budget track, so the fastest relief is usually in the largest bucket.",
                    systemImage: "exclamationmark.triangle.fill"
                )
            )
        } else if state.utilizationRatio >= 0.82 {
            rows.append(
                InsightRow(
                    id: "watch-pace",
                    title: "Watch the pace",
                    detail: "The month is heating up; one small trim or one bill review keeps the plan comfortable.",
                    systemImage: "speedometer"
                )
            )
        }

        if viewModel.rules.isEmpty && state.transactionCount >= 3 {
            rows.append(
                InsightRow(
                    id: "create-rule",
                    title: "Create a merchant rule",
                    detail: "Repeated merchants are still manual, so the next rule will clean up the ledger quickly.",
                    systemImage: "slider.horizontal.3"
                )
            )
        }

        if viewModel.bills.isEmpty {
            rows.append(
                InsightRow(
                    id: "add-bill",
                    title: "Make obligations visible",
                    detail: "Recurring bills are still hidden. Add one so the app can warn you earlier.",
                    systemImage: "calendar.badge.clock"
                )
            )
        }

        if viewModel.accounts.count < 2 {
            rows.append(
                InsightRow(
                    id: "add-account",
                    title: "Add another account bucket",
                    detail: "A second account or cash bucket gives the analysis a fuller local snapshot.",
                    systemImage: "wallet.pass.fill"
                )
            )
        }

        if rows.isEmpty {
            rows.append(
                InsightRow(
                    id: "steady",
                    title: "Keep the rhythm",
                    detail: "The analysis already has enough signal. Keep feeding it clean transactions and the month will stay readable.",
                    systemImage: "checkmark.seal.fill"
                )
            )
        }

        return Array(rows.prefix(4))
    }
}

private struct GeneratedInsightResult {
    let summary: String
    let alerts: [String]
    let actions: [String]
}

private struct InsightRow: Identifiable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String
}

private struct TrendRow: Identifiable {
    let label: String
    let expense: Double
    let net: Double

    var id: String { label }
}

private struct InsightsSeriesPoint: Identifiable {
    let label: String
    let value: Double

    var id: String { label }
}

private enum InsightsPeriod: String, CaseIterable, Identifiable {
    case day
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day:
            return "Day".appLocalized
        case .week:
            return "Week".appLocalized
        case .month:
            return "Month".appLocalized
        }
    }
}

private enum InsightsMetric: String, CaseIterable, Identifiable {
    case expense
    case refund
    case income

    var id: String { rawValue }

    var title: String {
        switch self {
        case .expense:
            return "Expense".appLocalized
        case .refund:
            return "Refund".appLocalized
        case .income:
            return "Income".appLocalized
        }
    }

    var systemImage: String {
        switch self {
        case .expense:
            return "arrow.down.circle.fill"
        case .refund:
            return "arrow.uturn.backward.circle.fill"
        case .income:
            return "arrow.up.circle.fill"
        }
    }
}

private func buildSeries(for period: InsightsPeriod, metric: InsightsMetric, expenses: [ExpenseRecord]) -> [InsightsSeriesPoint] {
    let calendar = Calendar.autoupdatingCurrent
    let now = Date()

    switch period {
    case .day:
        return Array(0..<6).map { offset in
            let start = calendar.date(bySettingHour: offset * 4, minute: 0, second: 0, of: now) ?? now
            let end = calendar.date(byAdding: .hour, value: 4, to: start) ?? start
            return InsightsSeriesPoint(
                label: start.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted))),
                value: metricValue(
                    for: expenses.filter { $0.date >= start && $0.date < end },
                    metric: metric
                )
            )
        }
    case .week:
        return Array(0..<7).map { offset in
            let start = calendar.date(byAdding: .day, value: -(6 - offset), to: calendar.startOfDay(for: now)) ?? now
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
            return InsightsSeriesPoint(
                label: start.formatted(.dateTime.weekday(.abbreviated)),
                value: metricValue(
                    for: expenses.filter { $0.date >= start && $0.date < end },
                    metric: metric
                )
            )
        }
    case .month:
        return Array(0..<4).map { offset in
            let weekStart = calendar.date(byAdding: .day, value: -(21 - (offset * 7)), to: calendar.startOfDay(for: now)) ?? now
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            return InsightsSeriesPoint(
                label: "W\(offset + 1)",
                value: metricValue(
                    for: expenses.filter { $0.date >= weekStart && $0.date < weekEnd },
                    metric: metric
                )
            )
        }
    }
}

private func metricValue(for expenses: [ExpenseRecord], metric: InsightsMetric) -> Double {
    let total = expenses.reduce(Decimal.zero) { partial, expense in
        switch metric {
        case .expense:
            return partial + max(expense.amount, 0)
        case .refund:
            return partial + (expense.amount < 0 ? -expense.amount : 0)
        case .income:
            return partial + min(expense.amount, 0) * -1
        }
    }

    return NSDecimalNumber(decimal: total).doubleValue
}
