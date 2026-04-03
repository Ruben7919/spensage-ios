import SwiftUI

struct ExpensesCenterView: View {
    @ObservedObject var viewModel: AppViewModel

    private let currencyCode = "USD"

    private var ledger: LocalFinanceLedger? {
        viewModel.ledger
    }

    private var expenseRecords: [ExpenseRecord] {
        (ledger?.expenses ?? []).sorted { $0.date > $1.date }
    }

    private var recentMonthExpenses: [ExpenseRecord] {
        let calendar = Calendar.autoupdatingCurrent
        return expenseRecords.filter { calendar.isDate($0.date, equalTo: .now, toGranularity: .month) }
    }

    private var currentState: FinanceDashboardState? {
        viewModel.dashboardState
    }

    private var categoryBreakdown: [CategoryBreakdown] {
        ledger?.categoryBreakdown(limit: 6) ?? []
    }

    private var totalSpentThisMonth: Decimal {
        currentState?.budgetSnapshot.monthlySpent ?? recentMonthExpenses.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var averageExpense: Decimal {
        guard !recentMonthExpenses.isEmpty else { return 0 }
        return totalSpentThisMonth / Decimal(recentMonthExpenses.count)
    }

    private var largestExpense: ExpenseRecord? {
        recentMonthExpenses.max { $0.amount < $1.amount }
    }

    private var nextBill: BillRecord? {
        ledger?.upcomingBills().first
    }

    private var daysElapsedInMonth: Int {
        let calendar = Calendar.autoupdatingCurrent
        return max(calendar.component(.day, from: .now), 1)
    }

    private var monthlySpendPerDay: Decimal {
        guard daysElapsedInMonth > 0 else { return 0 }
        return totalSpentThisMonth / Decimal(daysElapsedInMonth)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerCard

                if let state = currentState {
                    snapshotCard(for: state)
                    categoryCard(for: state)
                    recentLedgerCard
                    importAndScanCard
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
        .navigationTitle("Expenses")
        .navigationBarTitleDisplayMode(.large)
        .task {
            if viewModel.dashboardState == nil {
                await viewModel.refreshDashboard()
            }
        }
    }

    private var headerCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        BrandBadge(
                            text: expenseRecords.isEmpty ? "Fresh local ledger" : "Local ledger",
                            systemImage: "iphone.gen3"
                        )

                        Text("Expense center")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)

                        Text("Add expenses quickly, review the month, and keep the local-first ledger moving.")
                            .foregroundStyle(BrandTheme.muted)
                    }

                    Spacer(minLength: 0)

                    Text(lastUpdatedLabel)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.muted)
                        .multilineTextAlignment(.trailing)
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
            }
        }
    }

    private func snapshotCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Ledger snapshot",
                    detail: "The month at a glance, tuned for the local-first mode."
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
                        title: "Average",
                        value: averageExpense.formatted(.currency(code: currencyCode)),
                        systemImage: "chart.bar.fill"
                    )
                    BrandMetricTile(
                        title: "Largest",
                        value: largestExpense?.amount.formatted(.currency(code: currencyCode)) ?? "None",
                        systemImage: "arrow.up.right.circle.fill"
                    )
                    BrandMetricTile(
                        title: "Rules",
                        value: "\(ledger?.rules.count ?? 0)",
                        systemImage: "line.3.horizontal.decrease.circle.fill"
                    )
                    BrandMetricTile(
                        title: "Accounts",
                        value: "\(ledger?.accounts.count ?? 0)",
                        systemImage: "wallet.pass.fill"
                    )
                    BrandMetricTile(
                        title: "Bills",
                        value: "\(ledger?.bills.count ?? 0)",
                        systemImage: "calendar.badge.clock"
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
                            .foregroundStyle(BrandTheme.muted)
                    }

                    ProgressView(value: min(max(state.utilizationRatio, 0), 1))
                        .tint(BrandTheme.primary)

                    HStack {
                        Text("Per day \(monthlySpendPerDay.formatted(.currency(code: currencyCode)))")
                        Spacer()
                        Text("Remaining \(state.budgetSnapshot.remaining.formatted(.currency(code: currencyCode)))")
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(BrandTheme.muted)
                }

                HStack(alignment: .top, spacing: 12) {
                    infoPill(
                        title: "Next bill",
                        detail: nextBill.map { nextBillText(for: $0) } ?? "No recurring bills yet",
                        systemImage: "calendar.badge.clock"
                    )

                    infoPill(
                        title: "Velocity",
                        detail: "\(recentMonthExpenses.count) expenses this month",
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
                    detail: state.categoryBreakdown.isEmpty
                        ? "Add an expense to see category pressure and share."
                        : "\(state.transactionCount) transactions are shaping the month."
                )

                if categoryBreakdown.isEmpty {
                    emptyRow(
                        title: "No category signal yet",
                        detail: "The first few expenses will reveal where the budget is tilting."
                    )
                } else {
                    ForEach(categoryBreakdown) { category in
                        categoryRow(category, total: totalSpentThisMonth)
                    }
                }
            }
        }
    }

    private var recentLedgerCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Recent ledger",
                    detail: expenseRecords.isEmpty
                        ? "The newest activity lands here first."
                        : "Latest entries from the local ledger."
                )

                if expenseRecords.isEmpty {
                    emptyRow(
                        title: "Recent activity will show up here",
                        detail: "Once the ledger moves, this list becomes the fastest way to audit what just happened."
                    )
                } else {
                    ForEach(expenseRecords.prefix(8)) { expense in
                        expenseRow(expense)
                    }
                }
            }
        }
    }

    private var importAndScanCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Import and scan",
                    detail: "Seed the local ledger with receipts or spreadsheet data."
                )

                NavigationLink("CSV Import") {
                    FinanceCsvImportToolView(viewModel: viewModel)
                }

                NavigationLink("Scan Receipts") {
                    FinanceReceiptScanToolView(viewModel: viewModel)
                }
            }
        }
    }

    private var toolsCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Finance tools",
                    detail: "Accounts, bills, and rules stay close so the ledger feels complete."
                )

                NavigationLink {
                    FinanceAccountsToolView(viewModel: viewModel)
                } label: {
                    FinanceToolRowLabel(
                        title: "Accounts",
                        summary: "Add cash, cards, and manual balances for a fuller local snapshot.",
                        systemImage: "wallet.pass.fill"
                    )
                }

                NavigationLink {
                    FinanceBillsToolView(viewModel: viewModel)
                } label: {
                    FinanceToolRowLabel(
                        title: "Bills",
                        summary: "Track recurring payments and mark them paid into the ledger.",
                        systemImage: "calendar.badge.clock"
                    )
                }

                NavigationLink {
                    FinanceRulesToolView(viewModel: viewModel)
                } label: {
                    FinanceToolRowLabel(
                        title: "Rules",
                        summary: "Save merchant keywords to auto-categorize imported expenses.",
                        systemImage: "slider.horizontal.3"
                    )
                }
            }
        }
    }

    private var loadingCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                BrandBadge(text: "Loading ledger", systemImage: "sparkles")
                Text("Your local expense data is being prepared.")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text("Once the dashboard snapshot arrives, this center will surface totals, pacing, and category pressure.")
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

    private func infoPill(title: String, detail: String, systemImage: String) -> some View {
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

    private func categoryRow(_ category: CategoryBreakdown, total: Decimal) -> some View {
        let share = total > 0
            ? NSDecimalNumber(decimal: category.total).doubleValue / NSDecimalNumber(decimal: total).doubleValue
            : 0

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
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

            ProgressView(value: share)
                .tint(BrandTheme.primary)
        }
    }

    private func expenseRow(_ expense: ExpenseRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: expense.category.symbolName)
                .frame(width: 34, height: 34)
                .foregroundStyle(BrandTheme.primary)
                .background(BrandTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.merchant)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text("\(expense.category.rawValue) · \(expense.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }
            }

            Spacer()

            Text(expense.amount, format: .currency(code: currencyCode))
                .font(.headline)
                .foregroundStyle(BrandTheme.ink)
        }
        .padding(.vertical, 4)
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

    private func nextBillText(for bill: BillRecord) -> String {
        let dueDate = ledger?.dueDate(for: bill)
        let dueText = dueDate.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "Soon"
        return "\(bill.title) · \(bill.amount.formatted(.currency(code: currencyCode))) · \(dueText)"
    }

    private var lastUpdatedLabel: String {
        guard let updatedAt = ledger?.updatedAt else {
            return "Updating locally"
        }
        return "Updated \(updatedAt.formatted(date: .abbreviated, time: .shortened))"
    }
}
