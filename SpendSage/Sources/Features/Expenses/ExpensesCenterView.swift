import SwiftUI

struct ExpensesCenterView: View {
    @ObservedObject var viewModel: AppViewModel
    @AppStorage(AppCurrencyFormat.defaultsKey) private var currencyCode = AppCurrencyFormat.defaultCode
    @Environment(\.shellBottomInset) private var shellBottomInset
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
                    toolsDisclosureCard
                    if !categoryBreakdown.isEmpty {
                        ExperienceDisclosureCard(
                            title: "Más detalle",
                            summary: "Abre la mezcla por categoría solo cuando quieras una lectura más profunda del mes.",
                            character: .mei,
                            expression: .thinking
                        ) {
                            categoryCard(for: state)
                        }
                    }

                    if case .guest = viewModel.session {
                        sponsorCard
                    }
                } else {
                    loadingCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, shellBottomInset > 0 ? 12 : 40)
        }
        .background(
            ZStack {
                BrandTheme.canvas
                BrandBackdropView()
            }
            .ignoresSafeArea()
        )
        .navigationTitle("Gastos")
        .navigationBarTitleDisplayMode(.inline)
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
                BrandCardHeader(
                    badgeText: expenseRecords.isEmpty ? "Empieza aquí" : "Este mes",
                    badgeSystemImage: "creditcard.fill",
                    title: "Gastos",
                    summary: "Registra una compra rápido, revisa el mes y abre más herramientas solo cuando haga falta."
                ) {
                    Text(lastUpdatedLabel)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.muted)
                        .multilineTextAlignment(.trailing)
                }

                BrandArtworkSurface {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Manchas mantiene esta pantalla corta: primero capturas, luego revisas y al final profundizas si hace falta.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        BrandMetricTile(
                            title: "Este mes",
                            value: totalSpentThisMonth.formatted(.currency(code: currencyCode)),
                            systemImage: "creditcard.fill"
                        )

                        BrandBadge(
                            text: AppLocalization.localized("%d registros", arguments: expenseRecords.count),
                            systemImage: "list.bullet.rectangle"
                        )

                        BrandAssetImage(
                            source: BrandAssetCatalog.shared.guide("guide_02_log_expense_manchas"),
                            fallbackSystemImage: "receipt.fill"
                        )
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 132, alignment: .center)
                    }
                }

                MascotSpeechCard(
                    character: .manchas,
                    expression: expenseRecords.isEmpty ? .thinking : .happy,
                    title: "Manchas",
                    message: expenseRecords.isEmpty
                        ? "Empieza con un gasto real. Todo lo demás se vuelve útil en cuanto cae el primer registro."
                        : "Revisa el resumen, mira los últimos movimientos y profundiza solo si algo se ve raro."
                )

                HStack(spacing: 12) {
                    Button("Agregar gasto") {
                        viewModel.presentAddExpense()
                    }
                    .buttonStyle(PrimaryCTAStyle())

                    Button("Escanear recibo") {
                        viewModel.startScanFlow()
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
                    title: "Este mes",
                    detail: "La lectura más corta y útil de tu gasto ahora mismo."
                )

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(
                        title: "Gastado",
                        value: state.budgetSnapshot.monthlySpent.formatted(.currency(code: currencyCode)),
                        systemImage: "creditcard.fill"
                    )
                    BrandMetricTile(
                        title: "Restante",
                        value: state.budgetSnapshot.remaining.formatted(.currency(code: currencyCode)),
                        systemImage: "banknote.fill"
                    )
                    BrandMetricTile(
                        title: "Promedio",
                        value: averageExpense.formatted(.currency(code: currencyCode)),
                        systemImage: "chart.bar.fill"
                    )
                    BrandMetricTile(
                        title: "Mayor",
                        value: largestExpense?.amount.formatted(.currency(code: currencyCode)) ?? "Ninguno",
                        systemImage: "arrow.up.right.circle.fill"
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Ritmo del presupuesto")
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
                                "Por día %@",
                                arguments: monthlySpendPerDay.formatted(.currency(code: currencyCode))
                            )
                        )
                        Spacer()
                        Text(
                            AppLocalization.localized(
                                "Restante %@",
                                arguments: state.budgetSnapshot.remaining.formatted(.currency(code: currencyCode))
                            )
                        )
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(BrandTheme.muted)
                }

                HStack(alignment: .top, spacing: 12) {
                    infoPill(
                        title: "Próxima factura",
                        detail: nextBill.map { nextBillText(for: $0) } ?? "Todavía no hay facturas recurrentes",
                        systemImage: "calendar.badge.clock"
                    )

                    infoPill(
                        title: "Ritmo",
                        detail: AppLocalization.localized("%d gastos este mes", arguments: recentMonthExpenses.count),
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
                    title: "Mezcla por categoría",
                    detail: state.categoryBreakdown.isEmpty
                        ? "Agrega un gasto para ver la presión y el peso por categoría."
                        : AppLocalization.localized("%d transacciones están dando forma al mes.", arguments: state.transactionCount)
                )

                if categoryBreakdown.isEmpty {
                    emptyRow(
                        title: "Todavía no hay señal por categoría",
                        detail: "Los primeros gastos van a revelar hacia dónde se inclina el presupuesto."
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
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Modo gratis con patrocinio")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text("Esta superficie patrocinada se mantiene visible en modo gratis, entre las herramientas de captura y el libro reciente, para sostener la experiencia y dejar clara la mejora futura.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    BrandBadge(text: "Modo gratis", systemImage: "sparkles")
                }

                HStack(spacing: 12) {
                    NavigationLink {
                        PremiumView(viewModel: viewModel)
                    } label: {
                        Label("Desbloquear premium", systemImage: "sparkles")
                    }
                    .buttonStyle(PrimaryCTAStyle())

                    Button("Por qué aparece") {
                        isPresentingGuide = true
                    }
                    .buttonStyle(SecondaryCTAStyle())
                }
            }
        }
    }

    private var recentLedgerCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Libro reciente",
                    detail: expenseRecords.isEmpty
                        ? "La actividad más nueva aterriza aquí primero."
                        : "Últimos registros de tu libro de gastos."
                )

                if expenseRecords.isEmpty {
                    emptyRow(
                        title: "La actividad reciente aparecerá aquí",
                        detail: "Cuando el libro se mueva, esta lista será la forma más rápida de auditar lo que acaba de pasar."
                    )
                } else {
                    ForEach(expenseRecords.prefix(6)) { expense in
                        expenseRow(expense)
                    }
                }
            }
        }
    }

    private var toolsDisclosureCard: some View {
        ExperienceDisclosureCard(
            title: "Más herramientas",
            summary: "Escanear queda a un toque. Cuentas, reglas, facturas, importaciones y el asistente se quedan plegados hasta que los necesites.",
            character: .manchas,
            expression: .thinking
        ) {
            toolsHubContent
        }
    }

    private var toolsHubContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                viewModel.startScanFlow()
            } label: {
                FinanceToolRowLabel(
                    title: "Escanear recibos",
                    summary: "Convierte una foto del recibo en un borrador que puedes revisar antes de guardar.",
                    systemImage: "camera.viewfinder"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                FinanceCsvImportToolView(viewModel: viewModel)
            } label: {
                FinanceToolRowLabel(
                    title: "Importar CSV",
                    summary: "Trae varios gastos cuando ya tienes una exportación en hoja de cálculo.",
                    systemImage: "square.and.arrow.down.on.square.fill"
                )
            }

            NavigationLink {
                FinanceAccountsToolView(viewModel: viewModel)
            } label: {
                FinanceToolRowLabel(
                    title: "Cuentas",
                    summary: "Revisa efectivo, tarjetas y saldos manuales en un solo lugar.",
                    systemImage: "wallet.pass.fill"
                )
            }

            NavigationLink {
                FinanceBillsToolView(viewModel: viewModel)
            } label: {
                FinanceToolRowLabel(
                    title: "Facturas",
                    summary: "Sigue pagos recurrentes y vencimientos sin saturar la pantalla principal.",
                    systemImage: "calendar.badge.clock"
                )
            }

            NavigationLink {
                FinanceRulesToolView(viewModel: viewModel)
            } label: {
                FinanceToolRowLabel(
                    title: "Reglas",
                    summary: "Guarda reglas por comercio para que los gastos repetidos se organicen automáticamente.",
                    systemImage: "slider.horizontal.3"
                )
            }

            Button("Abrir asistente de presupuesto") {
                viewModel.presentBudgetWizard()
            }
            .buttonStyle(SecondaryCTAStyle())
        }
    }

    private var loadingCard: some View {
        MascotLoadingCard(
            badgeText: "Loading ledger",
            title: "Estamos preparando tus gastos.",
            summary: "Cuando llegue el snapshot del dashboard, esta pantalla mostrará tu resumen, actividad reciente y herramientas más profundas.",
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
