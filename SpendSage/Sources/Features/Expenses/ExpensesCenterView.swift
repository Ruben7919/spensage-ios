import SwiftUI

struct ExpensesCenterView: View {
    @ObservedObject var viewModel: AppViewModel
    @AppStorage(AppCurrencyFormat.defaultsKey) private var currencyCode = AppCurrencyFormat.defaultCode
    @State private var isPresentingGuide = false

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
        ledger?.categoryBreakdown(limit: 3) ?? []
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
                    recentLedgerCard
                    toolsHubCard
                    if !categoryBreakdown.isEmpty {
                        ExperienceDisclosureCard(
                            title: "More details",
                            summary: "Open the category mix only when you want a deeper read of the month.",
                            character: .mei,
                            expression: .thinking
                        ) {
                            categoryCard(for: state)
                        }
                    }
                    sponsorCard
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
        .sheet(isPresented: $isPresentingGuide) {
            GuideSheet(guide: GuideLibrary.guide(.expenses))
        }
        .task {
            if viewModel.dashboardState == nil {
                await viewModel.refreshDashboard()
            }
        }
    }

    private var headerCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        BrandBadge(
                            text: expenseRecords.isEmpty ? "Start here" : "This month",
                            systemImage: "creditcard.fill"
                        )

                        Text("Expenses")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)

                        Text("Add a purchase fast, check the month, and open more tools only when you need them.")
                            .foregroundStyle(BrandTheme.muted)
                    }

                    Spacer(minLength: 0)

                    Text(lastUpdatedLabel)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.muted)
                        .multilineTextAlignment(.trailing)
                }

                BrandArtworkSurface {
                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Manchas keeps this screen short: capture first, review second, detail later.")
                                .font(.subheadline)
                                .foregroundStyle(BrandTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)

                            BrandMetricTile(
                                title: "This month",
                                value: totalSpentThisMonth.formatted(.currency(code: currencyCode)),
                                systemImage: "creditcard.fill"
                            )

                            BrandBadge(
                                text: AppLocalization.localized("%d entries", arguments: expenseRecords.count),
                                systemImage: "list.bullet.rectangle"
                            )
                        }

                        BrandAssetImage(
                            source: BrandAssetCatalog.shared.guide("guide_02_log_expense_manchas"),
                            fallbackSystemImage: "receipt.fill"
                        )
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 126, height: 126)
                    }
                }

                MascotSpeechCard(
                    character: .manchas,
                    expression: expenseRecords.isEmpty ? .thinking : .happy,
                    title: "Manchas",
                    message: expenseRecords.isEmpty
                        ? "Start with one real expense. The rest gets useful as soon as the first entry lands."
                        : "Check the summary, review the latest entries, and go deeper only if something looks off."
                )

                HStack(spacing: 12) {
                    Button("Add expense") {
                        viewModel.presentAddExpense()
                    }
                    .buttonStyle(PrimaryCTAStyle())

                    NavigationLink("Scan receipt") {
                        FinanceReceiptScanToolView(viewModel: viewModel)
                    }
                    .buttonStyle(SecondaryCTAStyle())
                }

                BrandBadge(
                    text: AppLocalization.localized("Ledger ready %d", arguments: expenseRecords.count),
                    systemImage: "checkmark.seal.fill"
                )
            }
        }
    }

    private func snapshotCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "This month",
                    detail: "The shortest useful read of your spending right now."
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
                        value: averageExpense.formatted(.currency(code: currencyCode)),
                        systemImage: "chart.bar.fill"
                    )
                    BrandMetricTile(
                        title: "Largest",
                        value: largestExpense?.amount.formatted(.currency(code: currencyCode)) ?? "None".appLocalized,
                        systemImage: "arrow.up.right.circle.fill"
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Budget pace")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(BrandTheme.ink)
                        Spacer()
                        Text(paceLabel(for: state).appLocalized)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(BrandTheme.muted)
                    }

                    ProgressView(value: min(max(state.utilizationRatio, 0), 1))
                        .tint(BrandTheme.primary)

                    HStack {
                        Text(
                            AppLocalization.localized(
                                "Per day %@",
                                arguments: monthlySpendPerDay.formatted(.currency(code: currencyCode))
                            )
                        )
                        Spacer()
                        Text(
                            AppLocalization.localized(
                                "Remaining %@",
                                arguments: state.budgetSnapshot.remaining.formatted(.currency(code: currencyCode))
                            )
                        )
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
                        detail: AppLocalization.localized("%d expenses this month", arguments: recentMonthExpenses.count),
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
                        : AppLocalization.localized("%d transactions are shaping the month.", arguments: state.transactionCount)
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

    private var sponsorCard: some View {
        Group {
            if case .guest = viewModel.session {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sponsor-supported free mode")
                                    .font(.headline)
                                    .foregroundStyle(BrandTheme.ink)
                                Text("This sponsor surface stays visible in free mode, between the capture tools and the recent ledger, so the experience remains supported and upgrade-ready.")
                                    .font(.subheadline)
                                    .foregroundStyle(BrandTheme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)

                            BrandBadge(text: "Free mode", systemImage: "sparkles")
                        }

                        HStack(spacing: 12) {
                            NavigationLink {
                                PremiumView(viewModel: viewModel)
                            } label: {
                                Label("Unlock premium", systemImage: "sparkles")
                            }
                            .buttonStyle(PrimaryCTAStyle())

                            Button("Why this appears") {
                                isPresentingGuide = true
                            }
                            .buttonStyle(SecondaryCTAStyle())
                        }
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
                        : "Latest entries from your account ledger."
                )

                if expenseRecords.isEmpty {
                    emptyRow(
                        title: "Recent activity will show up here",
                        detail: "Once the ledger moves, this list becomes the fastest way to audit what just happened."
                    )
                } else {
                    ForEach(expenseRecords.prefix(6)) { expense in
                        expenseRow(expense)
                    }
                }
            }
        }
    }

    private var toolsHubCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "More actions",
                    detail: "Open the tool you need instead of keeping every feature on the same screen."
                )

                NavigationLink {
                    FinanceReceiptScanToolView(viewModel: viewModel)
                } label: {
                    FinanceToolRowLabel(
                        title: "Scan receipts",
                        summary: "Turn a receipt photo into a draft expense you can review before saving.",
                        systemImage: "camera.viewfinder"
                    )
                }

                NavigationLink {
                    FinanceCsvImportToolView(viewModel: viewModel)
                } label: {
                    FinanceToolRowLabel(
                        title: "CSV import",
                        summary: "Bring in multiple expenses when you already have a spreadsheet export.",
                        systemImage: "square.and.arrow.down.on.square.fill"
                    )
                }

                NavigationLink {
                    FinanceAccountsToolView(viewModel: viewModel)
                } label: {
                    FinanceToolRowLabel(
                        title: "Accounts",
                        summary: "Review cash, cards, and manual balances in one place.",
                        systemImage: "wallet.pass.fill"
                    )
                }

                NavigationLink {
                    FinanceBillsToolView(viewModel: viewModel)
                } label: {
                    FinanceToolRowLabel(
                        title: "Bills",
                        summary: "Track recurring payments and due dates without crowding the main screen.",
                        systemImage: "calendar.badge.clock"
                    )
                }

                NavigationLink {
                    FinanceRulesToolView(viewModel: viewModel)
                } label: {
                    FinanceToolRowLabel(
                        title: "Rules",
                        summary: "Save merchant rules so repeated expenses stay organized automatically.",
                        systemImage: "slider.horizontal.3"
                    )
                }

                Button("Open budget wizard") {
                    viewModel.presentBudgetWizard()
                }
                .buttonStyle(SecondaryCTAStyle())
            }
        }
    }

    private var loadingCard: some View {
        MascotLoadingCard(
            badgeText: "Loading ledger",
            title: "Your expense data is being prepared.",
            summary: "Once the dashboard snapshot arrives, this screen will show your summary, recent activity, and deeper tools.",
            character: .manchas,
            expression: .thinking
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
                Text(title.appLocalized)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BrandTheme.ink)
                Text(detail.appLocalized)
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
                    Text(category.category.localizedTitle)
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Text(categoryCountLabel(for: category.count))
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
                Text(
                    AppLocalization.localized(
                        "%@ · %@",
                        arguments: expense.category.localizedTitle,
                        expense.date.formatted(date: .abbreviated, time: .omitted)
                    )
                )
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
            Text(title.appLocalized)
                .font(.headline)
                .foregroundStyle(BrandTheme.ink)
            Text(detail.appLocalized)
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

    private func categoryCountLabel(for count: Int) -> String {
        if count == 1 {
            return AppLocalization.localized("%d expense", arguments: count)
        }
        return AppLocalization.localized("%d expenses", arguments: count)
    }

    private func nextBillText(for bill: BillRecord) -> String {
        let dueDate = ledger?.dueDate(for: bill)
        let dueText = dueDate.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "Soon".appLocalized
        return AppLocalization.localized(
            "%@ · %@ · %@",
            arguments: bill.title,
            bill.amount.formatted(.currency(code: currencyCode)),
            dueText
        )
    }

    private var lastUpdatedLabel: String {
        guard let updatedAt = ledger?.updatedAt else {
            return "Updating".appLocalized
        }
        return AppLocalization.localized("Updated %@", arguments: updatedAt.formatted(date: .abbreviated, time: .shortened))
    }
}
