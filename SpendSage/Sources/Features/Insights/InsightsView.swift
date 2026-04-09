import Charts
import SwiftUI
import UIKit

struct InsightsView: View {
    @ObservedObject var viewModel: AppViewModel
    @AppStorage(AppCurrencyFormat.defaultsKey) private var currencyCode = AppCurrencyFormat.defaultCode
    @Environment(\.shellBottomInset) private var shellBottomInset

    @State private var exportNotice: String?
    @State private var selectedPeriod: InsightsPeriod = .week
    @State private var selectedMetric: InsightsMetric = .expense
    @State private var generatedInsight: GeneratedInsightResult?
    @State private var isPresentingGuide = false
    @State private var budgetDraft: [ExpenseCategory: String] = [:]
    @State private var plannerNotice: String?
    @State private var selectedChartIndex: Int?
    @State private var hasAppliedDebugChartSelection = false

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

    private var selectedChartPoint: InsightsSeriesPoint? {
        guard let selectedChartIndex else { return nil }
        return selectedSeries.first(where: { $0.index == selectedChartIndex })
    }

    private var plannerCategories: [ExpenseCategory] {
        Array(ExpenseCategory.allCases.prefix(6))
    }

    private var prefersCompactInsights: Bool {
        GuideProgressStore.isSeen(.insights) || recentExpenses.count >= 5
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
                        title: "Herramientas extra de Ludo",
                        summary: prefersCompactInsights
                            ? "Planificador, exportaciones y herramientas relacionadas se quedan ocultas hasta que las necesites."
                            : "Planificador, exportaciones y herramientas relacionadas viven aquí cuando quieres más control.",
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
            .padding(.bottom, shellBottomInset + 18)
        }
        .accessibilityIdentifier("insights.screen")
        .overlay(alignment: .topLeading) {
            AccessibilityProbe(identifier: "insights.screen")
        }
        .background(
            ZStack {
                BrandTheme.canvas
                BrandBackdropView()
            }
            .ignoresSafeArea()
        )
        .navigationTitle("Análisis")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingGuide) {
            GuideSheet(guide: GuideLibrary.guide(.insights))
        }
        .onChange(of: selectedPeriod) {
            selectedChartIndex = nil
        }
        .onChange(of: selectedMetric) {
            selectedChartIndex = nil
        }
        .onChange(of: selectedSeries.count) {
            applyDebugChartSelectionIfNeeded()
        }
        .task {
            seedBudgetDraftIfNeeded()
            applyDebugChartSelectionIfNeeded()
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
                    .padding(.bottom, shellBottomInset + 18)
            }
        }
    }

    private var heroCard: some View {
        BrandStoryCard(
            surface: .insights,
            title: "Análisis",
            message: prefersCompactInsights
                ? "Toca una barra para ver el valor exacto y abre detalle solo si algo pide acción."
                : "Mira qué cambió, qué categoría necesita atención y cuál es el siguiente paso que hace el mes más fácil de controlar.",
            highlights: [
                selectedPeriod.title,
                selectedMetric.title,
                currentState.map { paceLabel(for: $0) } ?? "Cargando"
            ],
            showsNarrativeFooter: !prefersCompactInsights
        )
    }

    private var filtersCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                CompactSectionHeader(
                    title: "Rango y foco",
                    detail: prefersCompactInsights
                        ? "Elige la ventana y el número que quieres mirar."
                        : "Elige la ventana de tiempo y el número que quieres entender."
                )

                Picker("Periodo", selection: $selectedPeriod) {
                    ForEach(InsightsPeriod.allCases) { period in
                        Text(period.title).tag(period)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Métrica", selection: $selectedMetric) {
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
                    title: "Lo importante ahora",
                    detail: prefersCompactInsights
                        ? "Total, margen restante y un chequeo de ritmo."
                        : "Mantén el resumen práctico: total, margen restante y una lectura clara del ritmo."
                )

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(
                        title: "Total elegido",
                        value: filteredMetricTotal.formatted(.currency(code: currencyCode)),
                        systemImage: selectedMetric.systemImage
                    )
                    BrandMetricTile(
                        title: "Restante",
                        value: state.budgetSnapshot.remaining.formatted(.currency(code: currencyCode)),
                        systemImage: "banknote.fill"
                    )
                    BrandMetricTile(
                        title: "Tasa de ahorro",
                        value: savingsRate.map { String(format: "%.0f%%", $0 * 100) } ?? "n/d",
                        systemImage: "percent"
                    )
                    BrandMetricTile(
                        title: "Patrimonio",
                        value: netWorthTotal.formatted(.currency(code: currencyCode)),
                        systemImage: "scale.3d"
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Ritmo del presupuesto")
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
                        Text(AppLocalization.localized("Gasto/día %@", arguments: spendPerDay.formatted(.currency(code: currencyCode))))
                        Spacer()
                        Text(AppLocalization.localized("Presupuesto/día %@", arguments: budgetPerDay.formatted(.currency(code: currencyCode))))
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(BrandTheme.muted)
                }

                if let nextBill {
                    BrandFeatureRow(
                        systemImage: "calendar.badge.clock",
                        title: "Próxima factura",
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
                    title: "Gráfico principal",
                    detail: prefersCompactInsights
                        ? "Toca una barra para ver el valor exacto."
                        : "Usa el gráfico para ver el patrón rápido. Abre el detalle solo si quieres la lectura completa."
                )

                if selectedSeries.isEmpty {
                    BrandFeatureRow(
                        systemImage: "chart.bar.fill",
                        title: "Todavía no hay señal",
                        detail: "Agrega algunos gastos y el gráfico empezará a mostrar un patrón más claro."
                    )
                } else {
                    if let selectedChartPoint {
                        BrandFeatureRow(
                            systemImage: selectedMetric.systemImage,
                            title: AppLocalization.localized("%@ seleccionado", arguments: selectedChartPoint.label),
                            detail: formattedChartValue(selectedChartPoint.value)
                        )
                        .overlay(alignment: .topLeading) {
                            AccessibilityProbe(identifier: "insights.chart.selection")
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("insights.chart.selection")
                        .accessibilityValue(formattedChartValue(selectedChartPoint.value))
                    } else {
                        BrandFeatureRow(
                            systemImage: "hand.tap.fill",
                            title: "Toca una barra",
                            detail: "El valor exacto aparece aquí cuando presionas un bloque."
                        )
                        .overlay(alignment: .topLeading) {
                            AccessibilityProbe(identifier: "insights.chart.prompt")
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("insights.chart.prompt")
                    }

                    Chart(selectedSeries) { row in
                        BarMark(
                            x: .value("Bloque", row.index),
                            y: .value("Valor", row.value)
                        )
                        .foregroundStyle(selectedChartIndex == row.index ? BrandTheme.accent : BrandTheme.primary)
                        .opacity(selectedChartIndex == nil || selectedChartIndex == row.index ? 1 : 0.45)
                        .cornerRadius(6)
                        .annotation(position: .top, spacing: 8) {
                            if selectedChartIndex == row.index {
                                Text(formattedChartValue(row.value))
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(BrandTheme.ink)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(BrandTheme.surface, in: Capsule())
                            }
                        }
                    }
                    .frame(height: 220)
                    .accessibilityIdentifier("insights.mainChart")
                    .chartXAxis {
                        AxisMarks(values: selectedSeries.map(\.index)) { value in
                            AxisGridLine()
                            AxisTick()
                            if let index = value.as(Int.self),
                               let point = selectedSeries.first(where: { $0.index == index }) {
                                AxisValueLabel(point.label)
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartOverlay { proxy in
                        GeometryReader { geometry in
                            if let plotFrame = proxy.plotFrame {
                                let plotArea = geometry[plotFrame]

                                ZStack {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .contentShape(Rectangle())
                                        .frame(width: plotArea.width, height: plotArea.height)
                                        .position(x: plotArea.midX, y: plotArea.midY)
                                        .gesture(
                                            DragGesture(minimumDistance: 0)
                                                .onChanged { value in
                                                    updateChartSelection(at: value.location, proxy: proxy, geometry: geometry)
                                                }
                                                .onEnded { value in
                                                    updateChartSelection(at: value.location, proxy: proxy, geometry: geometry)
                                                }
                                        )

                                    HStack(spacing: 0) {
                                        ForEach(selectedSeries) { point in
                                            Button {
                                                selectedChartIndex = point.index
                                            } label: {
                                                Color.clear
                                                    .contentShape(Rectangle())
                                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            }
                                            .buttonStyle(.plain)
                                            .accessibilityLabel(point.label)
                                            .accessibilityValue(formattedChartValue(point.value))
                                        }
                                    }
                                    .frame(width: plotArea.width, height: plotArea.height)
                                    .position(x: plotArea.midX, y: plotArea.midY)
                                }
                            }
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(selectedSeries) { point in
                                Button {
                                    selectedChartIndex = point.index
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(point.label)
                                            .font(.caption.weight(.semibold))
                                        Text(formattedChartValue(point.value))
                                            .font(.caption2)
                                            .foregroundStyle(BrandTheme.muted)
                                    }
                                    .frame(minWidth: 72, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(selectedChartIndex == point.index ? BrandTheme.accent.opacity(0.22) : BrandTheme.surfaceTint)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(selectedChartIndex == point.index ? BrandTheme.primary.opacity(0.35) : BrandTheme.line.opacity(0.75), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("insights.chart.bar.\(point.index)")
                                .accessibilityLabel(point.label)
                                .accessibilityValue(formattedChartValue(point.value))
                            }
                        }
                        .padding(.top, 4)
                    }

                    NavigationLink {
                        InsightsTrendDetailView(
                            monthlyTrendRows: monthlyTrendRows,
                            averageMonthlySpend: averageMonthlySpend,
                            strongestMonthLabel: strongestMonthLabel,
                            series: selectedSeries,
                            metric: selectedMetric,
                            currencyCode: currencyCode
                        )
                    } label: {
                        QuickActionTile(
                            title: "Abrir tendencia",
                            detail: "Mira el gasto promedio, el mejor mes y cada bloque reciente en una pantalla aparte.",
                            systemImage: "chart.bar.xaxis"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("insights.link.trend")
                }
            }
        }
    }

    private func applyDebugChartSelectionIfNeeded() {
        guard !hasAppliedDebugChartSelection else { return }
        guard !selectedSeries.isEmpty else { return }
        guard let rawValue = ProcessInfo.processInfo.environment["SPENDSAGE_DEBUG_INSIGHTS_SELECTION"],
              let requestedIndex = Int(rawValue) else {
            return
        }

        let resolvedIndex = selectedSeries.first(where: { $0.index == requestedIndex })?.index
            ?? selectedSeries.max(by: { $0.value < $1.value })?.index

        guard let resolvedIndex else { return }
        selectedChartIndex = resolvedIndex
        hasAppliedDebugChartSelection = true
    }

    private func categoryCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                CompactSectionHeader(
                    title: "Presión por categoría",
                    detail: prefersCompactInsights
                        ? "Empieza por las categorías más pesadas."
                        : "Empieza por las categorías principales. Abre el detalle cuando quieras el desglose completo."
                )

                if categoryBreakdown.isEmpty {
                    BrandFeatureRow(
                        systemImage: "square.grid.2x2.fill",
                        title: "Todavía no hay categorías",
                        detail: "Los primeros gastos van a revelar hacia dónde se inclina el presupuesto."
                    )
                } else {
                    ForEach(Array(categoryBreakdown.prefix(3))) { category in
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

                if let row = insightRows(for: state).first {
                    BrandFeatureRow(
                        systemImage: row.systemImage,
                        title: row.title,
                        detail: row.detail
                    )
                }

                NavigationLink {
                    InsightsCategoryDetailView(
                        categories: categoryBreakdown,
                        monthSpending: monthSpending,
                        currencyCode: currencyCode,
                        rows: insightRows(for: state)
                    )
                } label: {
                    QuickActionTile(
                        title: "Abrir categorías",
                        detail: "Mira la lista completa de categorías y las recomendaciones en una pantalla aparte.",
                        systemImage: "list.bullet.rectangle.portrait"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func plannerCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                CompactSectionHeader(
                    title: "Planificador",
                    detail: "Convierte el análisis en una acción realista sobre tu presupuesto."
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
                    Button("Aplicar mezcla sugerida") {
                        budgetDraft = suggestedBudgetDraft(from: state)
                        plannerNotice = "Se cargó la mezcla sugerida."
                    }
                    .buttonStyle(SecondaryCTAStyle())

                    Button("Guardar presupuesto local") {
                        Task {
                            let totalBudget = parsedBudgetDraftTotal()
                            guard totalBudget > 0 else {
                                plannerNotice = "Agrega al menos un monto por categoría antes de guardar."
                                return
                            }

                            await viewModel.saveBudget(
                                monthlyIncome: state.budgetSnapshot.monthlyIncome,
                                monthlyBudget: totalBudget
                            )
                            plannerNotice = "El presupuesto local se actualizó desde el planificador."
                        }
                    }
                    .buttonStyle(PrimaryCTAStyle())
                }

                Button("Abrir asistente de presupuesto") {
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
                    title: "Resumen y siguiente paso",
                    detail: "Mantén la lectura clara y la recomendación fácil de ejecutar."
                )

                Button("Generar sugerencias") {
                    generatedInsight = generatedSuggestion(for: state)
                }
                .buttonStyle(PrimaryCTAStyle())

                if let generatedInsight {
                    BrandFeatureRow(systemImage: "sparkles", title: "Resumen", detail: generatedInsight.summary)

                    ForEach(generatedInsight.alerts, id: \.self) { alert in
                        BrandFeatureRow(systemImage: "exclamationmark.triangle.fill", title: "Alerta", detail: alert)
                    }

                    ForEach(generatedInsight.actions, id: \.self) { action in
                        BrandFeatureRow(systemImage: "checkmark.circle.fill", title: "Acción", detail: action)
                    }
                }

                HStack(spacing: 12) {
                    Button("Copiar resumen") {
                        copyExport(LocalLedgerExportComposer.readableSummary(viewModel: viewModel), label: "Resumen copiado")
                    }
                    .buttonStyle(SecondaryCTAStyle())

                    Button("Copiar snapshot") {
                        copyExport(LocalLedgerExportComposer.jsonSnapshot(viewModel: viewModel), label: "Snapshot copiado")
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
                    title: "Herramientas relacionadas",
                    detail: "Abre una herramienta más profunda solo cuando el análisis te diga que vale la pena."
                )

                NavigationLink {
                    FinanceBillsToolView(viewModel: viewModel)
                } label: {
                    QuickActionTile(
                        title: "Facturas",
                        detail: "Revisa obligaciones recurrentes y fechas de vencimiento.",
                        systemImage: "calendar.badge.clock"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    FinanceAccountsToolView(viewModel: viewModel)
                } label: {
                    QuickActionTile(
                        title: "Cuentas",
                        detail: "Revisa saldos y exposición a deuda.",
                        systemImage: "wallet.pass.fill"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    FinanceRulesToolView(viewModel: viewModel)
                } label: {
                    QuickActionTile(
                        title: "Reglas",
                        detail: "Limpia comerciantes recurrentes y categorías.",
                        systemImage: "line.3.horizontal.decrease.circle.fill"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var loadingCard: some View {
        MascotLoadingCard(
            badgeText: "Cargando análisis",
            title: "Cargando análisis",
            summary: "Estamos preparando tu lectura local.",
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
        monthlyTrendRows.max { $0.net < $1.net }?.label ?? "n/d"
    }

    private func share(for category: CategoryBreakdown, total: Decimal) -> Double {
        let totalNumber = NSDecimalNumber(decimal: total).doubleValue
        guard totalNumber > 0 else { return 0 }
        return NSDecimalNumber(decimal: category.total).doubleValue / totalNumber
    }

    private func categoryCountLabel(for count: Int) -> String {
        if count == 1 {
            return "\(count) transacción"
        }
        return "\(count) transacciones"
    }

    private func formattedChartValue(_ value: Double) -> String {
        NSDecimalNumber(value: value).decimalValue.formatted(.currency(code: currencyCode))
    }

    private func updateChartSelection(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard !selectedSeries.isEmpty else {
            selectedChartIndex = nil
            return
        }

        guard let plotFrame = proxy.plotFrame else {
            selectedChartIndex = nil
            return
        }

        let plotArea = geometry[plotFrame]
        guard plotArea.contains(location) else {
            selectedChartIndex = nil
            return
        }

        let relativeX = location.x - plotArea.minX
        let stepWidth = plotArea.width / CGFloat(selectedSeries.count)
        guard stepWidth > 0 else { return }

        let rawIndex = Int(relativeX / stepWidth)
        let boundedIndex = min(max(rawIndex, 0), selectedSeries.count - 1)
        selectedChartIndex = selectedSeries[boundedIndex].index
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
                summary: "Empieza con un gasto para que Análisis pueda generar un resumen más específico.".appLocalized,
                alerts: ["Todavía no hay transacciones disponibles para leer el ritmo ni la presión por categoría.".appLocalized],
                actions: ["Agrega tu primer gasto para desbloquear el análisis completo.".appLocalized]
            )
        }

        if state.utilizationRatio >= 1 {
            return GeneratedInsightResult(
                summary: "Ya estás por encima del presupuesto este mes. Recorta primero la categoría principal y revisa la próxima factura antes de sumar gasto discrecional.".appLocalized,
                alerts: [
                    "La utilización mensual ya está por encima del presupuesto.".appLocalized,
                    state.topCategory.map {
                        AppLocalization.localized("%@ es la categoría más pesada ahora mismo.", arguments: $0.category.localizedTitle)
                    } ?? "La categoría principal es la que más presión está sumando.".appLocalized
                ],
                actions: [
                    "Reduce hoy una compra discrecional dentro de la categoría principal.".appLocalized,
                    "Revisa la próxima factura antes de la siguiente decisión de gasto.".appLocalized
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
                    "Mantén esta categoría estable durante los próximos días.".appLocalized,
                    "Abre el asistente de presupuesto si el tope actual se siente irreal.".appLocalized
                ]
            )
        }

        return GeneratedInsightResult(
            summary: "El mes sigue tranquilo. Aprovecha esta ventana para limpiar categorías, revisar facturas recurrentes y fijar una decisión de presupuesto.".appLocalized,
            alerts: ["El libro se ve lo bastante estable como para planificar en vez de reaccionar.".appLocalized],
            actions: [
                "Limpia una regla de comercio recurrente.".appLocalized,
                "Fija una decisión de presupuesto mientras el mes sigue tranquilo.".appLocalized
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
            return "Inicio"
        }
        if state.utilizationRatio < 0.82 {
            return "Ritmo tranquilo"
        }
        if state.utilizationRatio < 1 {
            return "Ritmo en observación"
        }
        return "Sobre presupuesto"
    }

    private func insightRows(for state: FinanceDashboardState) -> [InsightRow] {
        var rows: [InsightRow] = []

        if state.transactionCount == 0 {
            rows.append(
                InsightRow(
                    id: "first-expense",
                    title: "Agrega el primer gasto",
                    detail: "Una transacción desbloquea el ritmo, la mezcla por categoría y un análisis mensual más útil.",
                    systemImage: "plus.circle.fill"
                )
            )
        }

        if state.utilizationRatio >= 1 {
            rows.append(
                InsightRow(
                    id: "over-budget",
                    title: "Recorta la categoría principal",
                    detail: "El gasto ya está por encima del ritmo actual, así que el alivio más rápido suele vivir en el bloque más grande.",
                    systemImage: "exclamationmark.triangle.fill"
                )
            )
        } else if state.utilizationRatio >= 0.82 {
            rows.append(
                InsightRow(
                    id: "watch-pace",
                    title: "Vigila el ritmo",
                    detail: "El mes se está calentando; un pequeño recorte o una revisión de facturas mantiene el plan cómodo.",
                    systemImage: "speedometer"
                )
            )
        }

        if viewModel.rules.isEmpty && state.transactionCount >= 3 {
            rows.append(
                InsightRow(
                    id: "create-rule",
                    title: "Crea una regla de comercio",
                    detail: "Los comercios repetidos siguen siendo manuales, así que la siguiente regla va a limpiar el libro rápidamente.",
                    systemImage: "slider.horizontal.3"
                )
            )
        }

        if viewModel.bills.isEmpty {
            rows.append(
                InsightRow(
                    id: "add-bill",
                    title: "Haz visibles las obligaciones",
                    detail: "Las facturas recurrentes siguen ocultas. Agrega una para que la app pueda avisarte antes.",
                    systemImage: "calendar.badge.clock"
                )
            )
        }

        if viewModel.accounts.count < 2 {
            rows.append(
                InsightRow(
                    id: "add-account",
                    title: "Agrega otra cuenta",
                    detail: "Una segunda cuenta o bolsillo de efectivo le da al análisis una foto local mucho más completa.",
                    systemImage: "wallet.pass.fill"
                )
            )
        }

        if rows.isEmpty {
            rows.append(
                InsightRow(
                    id: "steady",
                    title: "Mantén el ritmo",
                    detail: "El análisis ya tiene suficiente señal. Sigue alimentándolo con transacciones limpias y el mes se mantendrá legible.",
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
    let index: Int
    let label: String
    let value: Double

    var id: Int { index }
}

private struct InsightsTrendDetailView: View {
    let monthlyTrendRows: [TrendRow]
    let averageMonthlySpend: Decimal
    let strongestMonthLabel: String
    let series: [InsightsSeriesPoint]
    let metric: InsightsMetric
    let currencyCode: String
    @Environment(\.shellBottomInset) private var shellBottomInset

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        CompactSectionHeader(
                            title: "Tendencia",
                            detail: "Aquí ves el contexto extra del rango actual sin cargar la pantalla principal."
                        )

                        HStack(spacing: 12) {
                            BrandMetricTile(
                                title: "Promedio",
                                value: averageMonthlySpend.formatted(.currency(code: currencyCode)),
                                systemImage: "chart.line.uptrend.xyaxis"
                            )
                            BrandMetricTile(
                                title: "Mejor mes",
                                value: strongestMonthLabel,
                                systemImage: "trophy.fill"
                            )
                        }
                    }
                }

                if !series.isEmpty {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            CompactSectionHeader(
                                title: "Bloques del rango",
                                detail: "Cada bloque muestra el total exacto de \(metric.title.lowercased()) en el rango elegido."
                            )

                            ForEach(series) { point in
                                detailRow(title: point.label, value: formattedCurrency(point.value))
                            }
                        }
                    }
                }

                if !monthlyTrendRows.isEmpty {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            CompactSectionHeader(
                                title: "Vista de seis meses",
                                detail: "El gasto mensual reciente y el flujo neto viven aquí en vez de cargar el gráfico principal."
                            )

                            ForEach(monthlyTrendRows) { row in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(row.label)
                                            .font(.headline)
                                            .foregroundStyle(BrandTheme.ink)

                                        Spacer()

                                        Text(formattedCurrency(row.expense))
                                            .font(.headline)
                                            .foregroundStyle(BrandTheme.ink)
                                    }

                                    detailRow(title: "Neto", value: formattedCurrency(row.net))
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, shellBottomInset + 18)
        }
        .background(
            ZStack {
                BrandTheme.canvas
                BrandBackdropView()
            }
            .ignoresSafeArea()
        )
        .overlay(alignment: .topLeading) {
            AccessibilityProbe(identifier: "insightsTrend.screen")
        }
        .accessibilityIdentifier("insightsTrend.screen")
        .navigationTitle("Tendencia")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formattedCurrency(_ value: Double) -> String {
        NSDecimalNumber(value: value).decimalValue.formatted(.currency(code: currencyCode))
    }

    @ViewBuilder
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BrandTheme.ink)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct InsightsCategoryDetailView: View {
    let categories: [CategoryBreakdown]
    let monthSpending: Decimal
    let currencyCode: String
    let rows: [InsightRow]
    @Environment(\.shellBottomInset) private var shellBottomInset

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        CompactSectionHeader(
                            title: "Categorías",
                            detail: "Aquí vive la presión completa por categoría y las recomendaciones asociadas."
                        )

                        if categories.isEmpty {
                            BrandFeatureRow(
                                systemImage: "square.grid.2x2.fill",
                                title: "Todavía no hay categorías",
                                detail: "Agrega algunos gastos y el desglose aparecerá aquí."
                            )
                        } else {
                            ForEach(categories) { category in
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

                                    ProgressView(value: share(for: category))
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
                    }
                }

                if !rows.isEmpty {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            CompactSectionHeader(
                                title: "Siguientes pasos",
                                detail: "Estas son las acciones recomendadas que nacen del análisis actual."
                            )

                            ForEach(rows) { row in
                                BrandFeatureRow(
                                    systemImage: row.systemImage,
                                    title: row.title,
                                    detail: row.detail
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, shellBottomInset + 18)
        }
        .background(
            ZStack {
                BrandTheme.canvas
                BrandBackdropView()
            }
            .ignoresSafeArea()
        )
        .navigationTitle("Categorías")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func share(for category: CategoryBreakdown) -> Double {
        let total = NSDecimalNumber(decimal: monthSpending).doubleValue
        guard total > 0 else { return 0 }
        return NSDecimalNumber(decimal: category.total).doubleValue / total
    }

    private func categoryCountLabel(for count: Int) -> String {
        if count == 1 {
            return AppLocalization.localized("%d transaction", arguments: count)
        }
        return AppLocalization.localized("%d transactions", arguments: count)
    }
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
                index: offset,
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
                index: offset,
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
                index: offset,
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
