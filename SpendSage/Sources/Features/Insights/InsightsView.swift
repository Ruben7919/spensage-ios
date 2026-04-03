import SwiftUI

struct InsightsView: View {
    @ObservedObject var viewModel: AppViewModel

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

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerCard

                if let state = currentState {
                    summaryCard(for: state)
                    pacingCard(for: state)
                    categoryCard(for: state)
                    nextMovesCard(for: state)
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

                    Button("Adjust budget") {
                        viewModel.presentBudgetWizard()
                    }
                    .buttonStyle(PrimaryCTAStyle())
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

    private func nextMovesCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Next moves",
                    detail: "The report turns into action when the local ledger gives you a few signals."
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

    private func categoryRow(_ category: CategoryBreakdown, total: Decimal) -> some View {
        let share = total > 0
            ? NSDecimalNumber(decimal: category.total).doubleValue / NSDecimalNumber(decimal: total).doubleValue
            : 0

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.category.rawValue)
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
