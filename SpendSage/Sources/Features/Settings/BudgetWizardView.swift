import SwiftUI

struct BudgetWizardView: View {
    private enum WizardStep: Int, CaseIterable {
        case income
        case target
        case review

        var title: String {
            switch self {
            case .income: return "Base de ingresos"
            case .target: return "Objetivo de presupuesto"
            case .review: return "Revisión del plan"
            }
        }

        var body: String {
            switch self {
            case .income:
                return "Empieza con el ingreso mensual que realmente llega a tus manos para que el resto del plan se mantenga honesto."
            case .target:
                return "Elige un tope de gasto que realmente puedas sostener. La meta es control, no castigo."
            case .review:
                return "Revisa el plan antes de guardarlo para que el mes se sienta intencional desde el primer día."
            }
        }

        var character: BrandCharacterID {
            switch self {
            case .income: return .manchas
            case .target: return .tikki
            case .review: return .mei
            }
        }

        var expression: BrandExpression {
            switch self {
            case .income: return .happy
            case .target: return .proud
            case .review: return .thinking
            }
        }

        var guideKey: String {
            switch self {
            case .income: return "guide_03_budgets_tikki"
            case .target: return "guide_03_budgets_tikki"
            case .review: return "guide_06_sharing_family_manchas"
            }
        }
    }

    @ObservedObject var viewModel: AppViewModel
    @AppStorage(AppCurrencyFormat.defaultsKey) private var currencyCode = AppCurrencyFormat.defaultCode

    @State private var step: WizardStep = .income
    @State private var income = ""
    @State private var budget = ""
    @State private var note: String?
    @State private var isPresentingGuide = false

    private var parsedIncome: Decimal? {
        Decimal(string: income.replacingOccurrences(of: ",", with: "."))
    }

    private var parsedBudget: Decimal? {
        Decimal(string: budget.replacingOccurrences(of: ",", with: "."))
    }

    private var canAdvance: Bool {
        switch step {
        case .income:
            return (parsedIncome ?? 0) > 0
        case .target:
            return (parsedBudget ?? 0) > 0
        case .review:
            return true
        }
    }

    private var suggestedBudget: Decimal? {
        guard let parsedIncome, parsedIncome > 0 else { return nil }
        return (parsedIncome * 75) / 100
    }

    private var projectedRemaining: Decimal {
        max(0, (parsedIncome ?? 0) - (parsedBudget ?? 0))
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    heroCard
                    progressCard
                    stepCard
                    summaryCard

                    if let note {
                        Text(note)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(24)
            }
            .background(BrandTheme.canvas)
            .navigationTitle("Presupuesto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        viewModel.dismissBudgetWizard()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Guía") {
                        isPresentingGuide = true
                    }
                }
            }
            .sheet(isPresented: $isPresentingGuide) {
                GuideSheet(guide: GuideLibrary.guide(.budgetWizard))
            }
        }
        .onAppear {
            if let ledger = viewModel.ledger {
                income = NSDecimalNumber(decimal: ledger.monthlyIncome).stringValue
                budget = NSDecimalNumber(decimal: ledger.monthlyBudget).stringValue
            }
        }
    }

    private var heroCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                BrandBadge(text: "Configuración en 3 pasos", systemImage: "wand.and.stars")

                Text("Asistente de presupuesto")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandTheme.ink)

                Text("Define ingresos, elige un objetivo mensual y revisa el plan antes de que se convierta en la base por defecto de la app.")
                    .foregroundStyle(BrandTheme.muted)

                BrandArtworkSurface {
                    BrandAssetImage(
                        source: BrandAssetCatalog.shared.guide(step.guideKey),
                        fallbackSystemImage: "chart.bar.doc.horizontal"
                    )
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                }

                MascotSpeechCard(
                    character: step.character,
                    expression: step.expression,
                    title: step.title,
                    message: step.body
                )
            }
        }
    }

    private var progressCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Progreso")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                HStack(spacing: 10) {
                    ForEach(Array(WizardStep.allCases.enumerated()), id: \.offset) { index, item in
                        VStack(alignment: .leading, spacing: 8) {
                            Capsule(style: .continuous)
                                .fill(index <= step.rawValue ? BrandTheme.primary : BrandTheme.line.opacity(0.65))
                                .frame(height: 8)

                            Text(item.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(index <= step.rawValue ? BrandTheme.ink : BrandTheme.muted)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var stepCard: some View {
        switch step {
        case .income:
            SurfaceCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Paso 1 · Ingreso mensual")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)

                    Text("Usa el monto que normalmente te queda después de impuestos o comisiones para que el resto del presupuesto se mantenga realista.")
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)

                    budgetField(title: "Ingreso mensual", value: $income, placeholder: "4200")

                    if let suggestedBudget {
                        BrandMetricTile(
                            title: "Presupuesto sugerido",
                            value: suggestedBudget.formatted(.currency(code: currencyCode)),
                            systemImage: "leaf.fill"
                        )
                    }

                    stepControls(primaryTitle: "Siguiente")
                }
            }
        case .target:
            SurfaceCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Paso 2 · Presupuesto objetivo")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)

                    Text("Elige el monto con el que quieres que corra el mes. Este será el techo sobre el que trabajan el dashboard y las sugerencias del coach.")
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)

                    budgetField(title: "Presupuesto mensual", value: $budget, placeholder: "2800")

                    HStack(spacing: 12) {
                        BrandMetricTile(
                            title: "Ingreso",
                            value: (parsedIncome ?? 0).formatted(.currency(code: currencyCode)),
                            systemImage: "banknote.fill"
                        )
                        BrandMetricTile(
                            title: "Colchón proyectado",
                            value: projectedRemaining.formatted(.currency(code: currencyCode)),
                            systemImage: "shield.lefthalf.filled"
                        )
                    }

                    stepControls(primaryTitle: "Revisar")
                }
            }
        case .review:
            SurfaceCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Paso 3 · Revisa el plan")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)

                    Text("Este resumen es lo que usará el dashboard para calcular disponible, progreso y siguientes pasos.")
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        BrandMetricTile(
                            title: "Ingreso",
                            value: (parsedIncome ?? 0).formatted(.currency(code: currencyCode)),
                            systemImage: "banknote.fill"
                        )
                        BrandMetricTile(
                            title: "Presupuesto",
                            value: (parsedBudget ?? 0).formatted(.currency(code: currencyCode)),
                            systemImage: "chart.bar.fill"
                        )
                        BrandMetricTile(
                            title: "Colchón",
                            value: projectedRemaining.formatted(.currency(code: currencyCode)),
                            systemImage: "lock.shield.fill"
                        )
                        BrandMetricTile(
                            title: "Modo",
                            value: viewModel.session.isAuthenticated ? "Sesión iniciada" : "Cuenta obligatoria",
                            systemImage: "iphone.gen3"
                        )
                    }

                    BrandFeatureRow(
                        systemImage: "checkmark.circle.fill",
                        title: "Puedes cambiarlo después",
                        detail: "El asistente es una ayuda de configuración, no un candado único. Puedes abrirlo otra vez desde Ajustes cuando el mes cambie."
                    )

                    stepControls(primaryTitle: "Guardar presupuesto local", isFinal: true)
                }
            }
        }
    }

    private var summaryCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Qué pasa después")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                BrandFeatureRow(
                    systemImage: "house.fill",
                    title: "Inicio se recalibra",
                    detail: "Disponible para gastar, progreso mensual y señales del coach usarán este presupuesto de inmediato."
                )

                BrandFeatureRow(
                    systemImage: "sparkles.rectangle.stack.fill",
                    title: "Las misiones se afilan",
                    detail: "Las metas se vuelven más claras cuando la app conoce el techo de gasto que quieres defender."
                )
            }
        }
    }

    private func budgetField(title: String, value: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.appLocalized)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)

            TextField(placeholder.appLocalized, text: value)
                .keyboardType(.decimalPad)
                .padding()
                .background(BrandTheme.surfaceTint)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(BrandTheme.line.opacity(0.82), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func stepControls(primaryTitle: String, isFinal: Bool = false) -> some View {
        HStack(spacing: 12) {
            if step != .income {
                Button("Atrás") {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.92)) {
                        step = WizardStep(rawValue: step.rawValue - 1) ?? .income
                    }
                }
                .buttonStyle(SecondaryCTAStyle())
            }

            Button(primaryTitle.appLocalized) {
                if isFinal {
                    Task { await save() }
                } else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.92)) {
                        step = WizardStep(rawValue: step.rawValue + 1) ?? .review
                    }
                }
            }
            .buttonStyle(PrimaryCTAStyle())
            .disabled(!canAdvance)
            .opacity(canAdvance ? 1 : 0.72)
        }
    }

    private func save() async {
        guard let incomeValue = parsedIncome, let budgetValue = parsedBudget else {
            note = "Usa números decimales válidos.".appLocalized
            return
        }

        guard incomeValue > 0, budgetValue > 0 else {
            note = "Ingreso y presupuesto deben ser mayores que cero.".appLocalized
            return
        }

        note = nil
        await viewModel.saveBudget(monthlyIncome: incomeValue, monthlyBudget: budgetValue)
    }
}
