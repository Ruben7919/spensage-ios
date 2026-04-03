import SwiftUI
import UIKit

struct InsightsView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var exportNotice: String?
    @State private var selectedPeriod: InsightsPeriod = .month
    @State private var selectedMetric: InsightsMetric = .expense
    @State private var generatedInsight: GeneratedInsightResult?
    @State private var isPresentingGuide = false
    @State private var budgetDraft: [ExpenseCategory: String] = [:]
    @State private var plannerNotice: String?

    private let currencyCode = "USD"

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
                return partial + expense.amount
            case .refund:
                return partial + (expense.amount < 0 ? -expense.amount : 0)
            case .income:
                return partial + (expense.amount > 0 ? expense.amount : 0)
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
                return monthlyIncome / Decimal(4)
            case .month:
                return monthlyIncome
            }
        }

        return filteredExpenses.reduce(Decimal.zero) { $0 + max($1.amount, 0) }
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

    private var savingsRate: Double? {
        guard let monthlyIncome = currentState?.budgetSnapshot.monthlyIncome, monthlyIncome > 0 else {
            return nil
        }

        let income = NSDecimalNumber(decimal: monthlyIncome).doubleValue
        let spent = NSDecimalNumber(decimal: currentState?.budgetSnapshot.monthlySpent ?? monthSpending).doubleValue
        guard income > 0 else { return nil }
        return max(-1, min(1, (income - spent) / income))
    }

    private var monthlyTrendRows: [(label: String, expense: Decimal, net: Decimal)] {
        let calendar = Calendar.autoupdatingCurrent

        return (0..<6).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: -offset, to: .now) else { return nil }
            let label = date.formatted(.dateTime.month(.abbreviated))
            let expense = recentExpenses
                .filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }
                .reduce(Decimal.zero) { $0 + max($1.amount, 0) }
            let net = (currentState?.budgetSnapshot.monthlyIncome ?? 0) - expense
            return (label: label, expense: expense, net: net)
        }
    }

    private var monthlyAverageSpend: Decimal {
        guard !monthlyTrendRows.isEmpty else { return 0 }
        return monthlyTrendRows.reduce(Decimal.zero) { $0 + $1.expense } / Decimal(monthlyTrendRows.count)
    }

    private var monthlyAverageNet: Decimal {
        guard !monthlyTrendRows.isEmpty else { return 0 }
        return monthlyTrendRows.reduce(Decimal.zero) { $0 + $1.net } / Decimal(monthlyTrendRows.count)
    }

    private var strongestMonthLabel: String {
        monthlyTrendRows.max { lhs, rhs in
            (lhs.net as NSDecimalNumber).doubleValue < (rhs.net as NSDecimalNumber).doubleValue
        }?.label ?? "n/a"
    }

    private var plannerCategories: [ExpenseCategory] {
        Array(ExpenseCategory.allCases.prefix(6))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerCard

                if let state = currentState {
                    reportPulseCard(for: state)
                    filtersCard(for: state)
                    summaryCard(for: state)
                    balanceSheetCard
                    pacingCard(for: state)
                    trendCard
                    categoryCard(for: state)
                    nextMovesCard(for: state)
                    plannerCard(for: state)
                    generatedActionsCard(for: state)
                    exportCard(for: state)
                    toolsCard
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
        .navigationTitle("Insights")
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

    private var headerCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        BrandBadge(text: "On-device report", systemImage: "chart.xyaxis.line")

                        Text("Insights")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)

                        Text("See where your money is going, how fast the month is moving, and what to fix next.")
                            .foregroundStyle(BrandTheme.muted)
                    }

                    Spacer(minLength: 0)

                    HStack(spacing: 10) {
                        Button {
                            isPresentingGuide = true
                        } label: {
                            Label("Guide", systemImage: "questionmark.circle")
                        }
                        .buttonStyle(SecondaryCTAStyle())

                        Button("Adjust budget") {
                            viewModel.presentBudgetWizard()
                        }
                        .buttonStyle(PrimaryCTAStyle())
                    }
                }

                HStack(spacing: 12) {
                    BrandMetricTile(
                        title: "Days left",
                        value: "\(stateRemainingDays)",
                        systemImage: "calendar"
                    )
                    BrandMetricTile(
                        title: "Transactions",
                        value: "\(currentState?.transactionCount ?? 0)",
                        systemImage: "receipt.fill"
                    )
                }
            }
        }
    }

    private func summaryCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Report summary",
                    detail: "A concise view of the current month with local-only data."
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
                        title: "Remaining",
                        value: state.budgetSnapshot.remaining.formatted(.currency(code: currencyCode)),
                        systemImage: "banknote.fill"
                    )
                    BrandMetricTile(
                        title: "Average",
                        value: state.averageExpense.formatted(.currency(code: currencyCode)),
                        systemImage: "chart.bar.fill"
                    )
                    BrandMetricTile(
                        title: "Largest",
                        value: state.largestExpense?.amount.formatted(.currency(code: currencyCode)) ?? "None",
                        systemImage: "arrow.up.right.circle.fill"
                    )
                }

                if let nextBill {
                    let dueText = ledger.map { $0.dueDate(for: nextBill).formatted(date: .abbreviated, time: .omitted) } ?? "soon"
                    BrandFeatureRow(
                        systemImage: "calendar.badge.clock",
                        title: "Next bill",
                        detail: "\(nextBill.title) due \(dueText) for \(nextBill.amount.formatted(.currency(code: currencyCode)))"
                    )
                }
            }
        }
    }

    private func filtersCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Range and metric",
                    detail: "Start by choosing the timeframe and signal you want to review."
                )

                HStack(spacing: 12) {
                    Picker("Timeframe", selection: $selectedPeriod) {
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

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(title: "Expense", value: expenseTotal.formatted(.currency(code: currencyCode)), systemImage: InsightsMetric.expense.systemImage)
                    BrandMetricTile(title: "Refund", value: refundTotal.formatted(.currency(code: currencyCode)), systemImage: InsightsMetric.refund.systemImage)
                    BrandMetricTile(title: "Income", value: incomeTotal.formatted(.currency(code: currencyCode)), systemImage: InsightsMetric.income.systemImage)
                }

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(title: "Selected", value: filteredMetricTotal.formatted(.currency(code: currencyCode)), systemImage: selectedMetric.systemImage)
                    BrandMetricTile(title: "Transactions", value: "\(filteredExpenses.count)", systemImage: "list.bullet.rectangle")
                    BrandMetricTile(title: "Net cashflow", value: (state.budgetSnapshot.monthlyIncome - state.budgetSnapshot.monthlySpent).formatted(.currency(code: currencyCode)), systemImage: "arrow.left.arrow.right")
                }

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(
                        title: "Savings rate",
                        value: savingsRate.map { String(format: "%.0f%%", $0 * 100) } ?? "n/a",
                        systemImage: "percent"
                    )
                    BrandMetricTile(
                        title: "Net worth",
                        value: netWorthTotal.formatted(.currency(code: currencyCode)),
                        systemImage: "scale.3d"
                    )
                }
            }
        }
    }

    private var balanceSheetCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Balance sheet",
                    detail: viewModel.accounts.isEmpty
                        ? "No manual accounts yet. Add balances to track net worth and debt payoff progress here."
                        : "\(viewModel.accounts.count) active manual account\(viewModel.accounts.count == 1 ? "" : "s") are included in this snapshot."
                )

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(title: "Assets", value: assetsTotal.formatted(.currency(code: currencyCode)), systemImage: "arrow.up.circle.fill")
                    BrandMetricTile(title: "Liabilities", value: liabilitiesTotal.formatted(.currency(code: currencyCode)), systemImage: "arrow.down.circle.fill")
                    BrandMetricTile(title: "Net worth", value: netWorthTotal.formatted(.currency(code: currencyCode)), systemImage: "scale.3d")
                }

                NavigationLink {
                    FinanceAccountsToolView(viewModel: viewModel)
                } label: {
                    Label("Open accounts", systemImage: "wallet.pass.fill")
                }
                .buttonStyle(SecondaryCTAStyle())
            }
        }
    }

    private func reportPulseCard(for state: FinanceDashboardState) -> some View {
        let alerts = insightRows(for: state)
        let status = paceLabel(for: state)
        let nextBillDetail: String
        if let nextBill, let ledger {
            let dueText = ledger.dueDate(for: nextBill).formatted(date: .abbreviated, time: .omitted)
            nextBillDetail = "\(nextBill.title) due \(dueText) for \(nextBill.amount.formatted(.currency(code: currencyCode)))."
        } else {
            nextBillDetail = "The report can stay focused on spend and category pressure for now."
        }

        return SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        sectionHeading(
                            title: "Report pulse",
                            detail: "A local report is ready to review, export, and turn into the next move."
                        )
                    }

                    Spacer(minLength: 0)

                    BrandBadge(text: status, systemImage: "doc.text.magnifyingglass")
                }

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(title: "Status", value: status, systemImage: "chart.line.uptrend.xyaxis")
                    BrandMetricTile(title: "Alerts", value: "\(alerts.count)", systemImage: "exclamationmark.triangle.fill")
                    BrandMetricTile(title: "Exports", value: "4 ready", systemImage: "square.and.arrow.up")
                }

                BrandFeatureRow(
                    systemImage: "calendar.badge.clock",
                    title: nextBill.map { "Next bill: \($0.title)" } ?? "No bills queued",
                    detail: nextBillDetail
                )
            }
        }
    }

    private func pacingCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Pacing",
                    detail: "Compare how fast you are spending against the month that remains."
                )

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Budget utilization")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(BrandTheme.ink)
                        Spacer()
                        Text(paceLabel(for: state))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(BrandTheme.muted)
                    }

                    ProgressView(value: min(max(state.utilizationRatio, 0), 1))
                        .tint(BrandTheme.primary)

                    HStack {
                        Text("Spend/day \(spendPerDay.formatted(.currency(code: currencyCode)))")
                        Spacer()
                        Text("Budget/day \(budgetPerDay.formatted(.currency(code: currencyCode)))")
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(BrandTheme.muted)
                }

                HStack(spacing: 12) {
                    BrandMetricTile(
                        title: "Days in month",
                        value: "\(daysInMonth)",
                        systemImage: "calendar.circle.fill"
                    )
                    BrandMetricTile(
                        title: "Pace ratio",
                        value: "\(Int((min(max(state.utilizationRatio, 0), 1) * 100).rounded()))%",
                        systemImage: "speedometer"
                    )
                }
            }
        }
    }

    private func categoryCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Category mix",
                    detail: categoryBreakdown.isEmpty
                        ? "No categories yet. Add an expense to reveal the mix."
                        : "\(state.transactionCount) transactions are shaping the month."
                )

                if categoryBreakdown.isEmpty {
                    emptyRow(
                        title: "No category signal yet",
                        detail: "The first few expenses will reveal where the budget is tilting."
                    )
                } else {
                    ForEach(categoryBreakdown) { category in
                        categoryRow(category, total: monthSpending)
                    }
                }
            }
        }
    }

    private var trendCard: some View {
        let rows = monthlyTrendRows
        let maxValue = rows.map(\.expense).max() ?? 1

        return SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Six-month trend",
                    detail: "See how spending, cashflow, and category pressure have shifted over recent months."
                )

                if rows.isEmpty {
                    emptyRow(
                        title: "Not enough history yet",
                        detail: "As more months accumulate, the trend view will show whether spend is improving."
                    )
                } else {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        BrandMetricTile(title: "Avg monthly spend", value: monthlyAverageSpend.formatted(.currency(code: currencyCode)), systemImage: "chart.bar.fill")
                        BrandMetricTile(title: "Avg net cashflow", value: monthlyAverageNet.formatted(.currency(code: currencyCode)), systemImage: "arrow.left.arrow.right")
                        BrandMetricTile(title: "Strongest month", value: strongestMonthLabel, systemImage: "trophy.fill")
                    }

                    ForEach(rows, id: \.label) { row in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(row.label)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(BrandTheme.ink)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(row.expense.formatted(.currency(code: currencyCode)))
                                    Text("Net \(row.net.formatted(.currency(code: currencyCode)))")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(BrandTheme.muted)
                                }
                                    .font(.footnote.weight(.semibold))
                            }

                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(BrandTheme.surfaceTint)
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(BrandTheme.primary)
                                        .frame(width: max(18, proxy.size.width * CGFloat((row.expense as NSDecimalNumber).doubleValue / max((maxValue as NSDecimalNumber).doubleValue, 1))))
                                }
                            }
                            .frame(height: 10)
                        }
                    }
                }
            }
        }
    }

    private func nextMovesCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Alerts and decisions",
                    detail: "Warnings, opportunities, and the next practical move the report wants you to notice."
                )

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
                sectionHeading(
                    title: "Budget planner",
                    detail: "Turn what you see here into a workable category plan without leaving this report."
                )

                BrandFeatureRow(
                    systemImage: "target",
                    title: "Top pressure area",
                    detail: state.topCategory.map {
                        AppLocalization.localized(
                            "%@ is currently leading the month at %@.",
                            arguments: $0.category.localizedTitle,
                            $0.total.formatted(.currency(code: currencyCode))
                        )
                    }
                        ?? "Add more expenses to reveal where category pressure is landing."
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
                            .background(Color.black.opacity(0.03), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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

    private func generatedActionsCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Generated suggestions",
                    detail: "Generate a quick summary of alerts and next moves from the data already in this report."
                )

                Button("Generate suggestions") {
                    generatedInsight = generatedSuggestion(for: state)
                }
                .buttonStyle(PrimaryCTAStyle())

                if let generatedInsight {
                    BrandFeatureRow(systemImage: "sparkles", title: "Summary", detail: generatedInsight.summary)

                    if !generatedInsight.alerts.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Alerts")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(BrandTheme.ink)
                            ForEach(generatedInsight.alerts, id: \.self) { alert in
                                BrandFeatureRow(systemImage: "exclamationmark.triangle.fill", title: "Watch this", detail: alert)
                            }
                        }
                    }

                    if !generatedInsight.actions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Actions")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(BrandTheme.ink)
                            ForEach(generatedInsight.actions, id: \.self) { action in
                                BrandFeatureRow(systemImage: "checkmark.circle.fill", title: "Do this next", detail: action)
                            }
                        }
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

    private func exportCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Export pack",
                    detail: "CSV, summary, category breakdown, and a full snapshot are all ready from the device."
                )

                BrandFeatureRow(
                    systemImage: "chart.line.uptrend.xyaxis",
                    title: "Report status: \(paceLabel(for: state))",
                    detail: "Everything below is generated from local data only."
                )

                BrandFeatureRow(
                    systemImage: "doc.text.fill",
                    title: "CSV export",
                    detail: "Best for bookkeeping, spreadsheets, or a quick handoff."
                )

                BrandFeatureRow(
                    systemImage: "square.and.arrow.up.on.square",
                    title: "Summary export",
                    detail: "A markdown review with cashflow context and recurring bills."
                )

                BrandFeatureRow(
                    systemImage: "chart.bar.fill",
                    title: "Snapshot export",
                    detail: "A fuller report that includes categories and account balances."
                )

                Text("Everything leaves local storage only when you choose to share it.")
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    Button("Copy CSV") {
                        copyExport(exportCSVText, label: "CSV export copied")
                    }
                    .buttonStyle(SecondaryCTAStyle())

                    Button("Copy summary") {
                        copyExport(exportSummaryText, label: "Summary export copied")
                    }
                    .buttonStyle(SecondaryCTAStyle())

                    Button("Copy categories") {
                        copyExport(exportCategoriesCSVText, label: "Category export copied")
                    }
                    .buttonStyle(SecondaryCTAStyle())

                    Button("Copy snapshot") {
                        copyExport(exportSnapshotText, label: "Snapshot export copied")
                    }
                    .buttonStyle(SecondaryCTAStyle())
                }
            }
        }
    }

    private var toolsCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "More money tools",
                    detail: "Jump directly into the related local workflows."
                )

                NavigationLink {
                    FinanceBillsToolView(viewModel: viewModel)
                } label: {
                    FinanceToolRowLabel(
                        title: "Bills",
                        summary: "Track recurring bills, due dates, and payment history locally.",
                        systemImage: "calendar.badge.clock"
                    )
                }

                NavigationLink {
                    FinanceAccountsToolView(viewModel: viewModel)
                } label: {
                    FinanceToolRowLabel(
                        title: "Accounts",
                        summary: "See balances across checking, savings, cash, and cards.",
                        systemImage: "wallet.pass.fill"
                    )
                }

                NavigationLink {
                    FinanceRulesToolView(viewModel: viewModel)
                } label: {
                    FinanceToolRowLabel(
                        title: "Rules",
                        summary: "Map merchant keywords to categories for cleaner imports.",
                        systemImage: "slider.horizontal.3"
                    )
                }

                NavigationLink {
                    FinanceCsvImportToolView(viewModel: viewModel)
                } label: {
                    FinanceToolRowLabel(
                        title: "CSV Import",
                        summary: "Paste rows from a spreadsheet and preview them before saving.",
                        systemImage: "tablecells.fill"
                    )
                }

                NavigationLink {
                    FinanceReceiptScanToolView(viewModel: viewModel)
                } label: {
                    FinanceToolRowLabel(
                        title: "Receipt Scan",
                        summary: "Capture a receipt image and finish the expense draft manually.",
                        systemImage: "camera.viewfinder"
                    )
                }
            }
        }
    }

    private var loadingCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                BrandBadge(text: "Loading insights", systemImage: "sparkles")
                Text("Your local report is being assembled.")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text("Once the dashboard snapshot arrives, these cards will show pacing, category share, and next actions.")
                    .foregroundStyle(BrandTheme.muted)
            }
        }
    }

    private var exportCSVText: String {
        let rows = recentExpenses
            .sorted { $0.date > $1.date }
            .map { expense in
                let note = (expense.note ?? "").replacingOccurrences(of: ",", with: " ")
                return [
                    expense.date.formatted(date: .numeric, time: .omitted),
                    expense.merchant,
                    expense.category.localizedTitle,
                    NSDecimalNumber(decimal: expense.amount).stringValue,
                    note
                ].joined(separator: ",")
            }
        return (["date,merchant,category,amount,note"] + rows).joined(separator: "\n")
    }

    private var exportCategoriesCSVText: String {
        let rows = categoryBreakdown.map { item in
            [
                item.category.localizedTitle,
                NSDecimalNumber(decimal: item.total).stringValue,
                "\(item.count)"
            ].joined(separator: ",")
        }
        return (["category,total,count"] + rows).joined(separator: "\n")
    }

    private var exportSummaryText: String {
        LocalLedgerExportComposer.readableSummary(viewModel: viewModel)
    }

    private var exportSnapshotText: String {
        LocalLedgerExportComposer.jsonSnapshot(viewModel: viewModel)
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
                summary: "Start with one expense so Insights can generate a more specific summary and alert stack.",
                alerts: ["No transactions are available yet for pacing or category pressure."],
                actions: ["Add your first expense to unlock the full report."]
            )
        }

        if state.utilizationRatio >= 1 {
            return GeneratedInsightResult(
                summary: "You are already over budget this month. Trim the top category first and review the next bill before adding new discretionary spend.",
                alerts: [
                    "Monthly utilization is already above budget.",
                    state.topCategory.map { AppLocalization.localized("%@ is the heaviest category right now.", arguments: $0.category.localizedTitle) } ?? "The top category is adding the strongest pressure."
                ],
                actions: [
                    "Reduce one discretionary purchase in the top category today.",
                    "Review the next bill before the next spend decision."
                ]
            )
        }

        if let topCategory = state.topCategory {
            return GeneratedInsightResult(
                summary: AppLocalization.localized(
                    "%@ is the strongest pressure point right now. Keep the next %d days focused there to protect the monthly runway.",
                    arguments: topCategory.category.localizedTitle,
                    safeSuggestionDaysLeft(for: state)
                ),
                alerts: [
                    AppLocalization.localized(
                        "%@ is leading the month at %@.",
                        arguments: topCategory.category.localizedTitle,
                        topCategory.total.formatted(.currency(code: currencyCode))
                    )
                ],
                actions: [
                    "Hold this category flat for the next few days.",
                    "Open the budget wizard if the current cap feels unrealistic."
                ]
            )
        }

        return GeneratedInsightResult(
            summary: "The month is still calm. Use this window to clean categories, review recurring bills, and lock one budget decision before the pace tightens.",
            alerts: ["The ledger looks stable enough to plan ahead instead of reacting."],
            actions: [
                "Clean one recurring merchant rule.",
                "Lock one budget decision while the month is still calm."
            ]
        )
    }

    private func sectionHeading(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.appLocalized)
                .font(.headline)
                .foregroundStyle(BrandTheme.ink)
            Text(detail.appLocalized)
                .font(.subheadline)
                .foregroundStyle(BrandTheme.muted)
        }
    }

    private func categoryRow(_ category: CategoryBreakdown, total: Decimal) -> some View {
        let share = total > 0
            ? NSDecimalNumber(decimal: category.total).doubleValue / NSDecimalNumber(decimal: total).doubleValue
            : 0

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.category.localizedTitle)
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Text("\(category.count) expense\(category.count == 1 ? "" : "s")")
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }

                Spacer()

                Text(category.total, format: .currency(code: currencyCode))
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
            }

            ProgressView(value: share)
                .tint(BrandTheme.primary)

            Text("\(Int((share * 100).rounded()))% of this month's spend")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BrandTheme.surfaceTint)
        )
    }

    private func seedBudgetDraftIfNeeded() {
        guard budgetDraft.isEmpty, let state = currentState else { return }
        budgetDraft = suggestedBudgetDraft(from: state)
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

    private func safeSuggestionDaysLeft(for state: FinanceDashboardState) -> Int {
        max(state.remainingDaysInMonth, 1)
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

    private func paceLabel(for state: FinanceDashboardState) -> String {
        if state.transactionCount == 0 {
            return "Kickoff"
        }
        if state.utilizationRatio < 0.82 {
            return "Calm pace"
        }
        if state.utilizationRatio < 1 {
            return "Watch pace"
        }
        return "Over budget"
    }

    private func insightRows(for state: FinanceDashboardState) -> [InsightRow] {
        var rows: [InsightRow] = []

        if state.transactionCount == 0 {
            rows.append(
                InsightRow(
                    id: "first-expense",
                    title: "Add the first expense",
                    detail: "One transaction unlocks pacing, category mix, and a more useful monthly report.",
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
                    detail: "The month is heating up; one small trim or one bill review keeps the report comfortable.",
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
                    detail: "Recurring bills are still hidden. Add one to let the report warn you earlier.",
                    systemImage: "calendar.badge.clock"
                )
            )
        }

        if viewModel.accounts.count < 2 {
            rows.append(
                InsightRow(
                    id: "add-account",
                    title: "Add another account bucket",
                    detail: "A second account or cash bucket gives the report a fuller local snapshot.",
                    systemImage: "wallet.pass.fill"
                )
            )
        }

        if rows.isEmpty {
            rows.append(
                InsightRow(
                    id: "steady",
                    title: "Keep the rhythm",
                    detail: "The report already has enough signal. Keep feeding it clean transactions and the month will stay readable.",
                    systemImage: "checkmark.seal.fill"
                )
            )
        }

        return rows.prefix(4).map { $0 }
    }

    private var stateRemainingDays: Int {
        currentState?.remainingDaysInMonth ?? 0
    }
}

private struct InsightRow: Identifiable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String
}

private struct GeneratedInsightResult {
    let summary: String
    let alerts: [String]
    let actions: [String]
}

private enum InsightsPeriod: String, CaseIterable, Identifiable {
    case day
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
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
        case .expense: return "Expense"
        case .refund: return "Refund"
        case .income: return "Income"
        }
    }

    var systemImage: String {
        switch self {
        case .expense: return "creditcard.fill"
        case .refund: return "arrow.uturn.backward.circle.fill"
        case .income: return "banknote.fill"
        }
    }
}
