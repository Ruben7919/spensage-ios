import SwiftUI

struct BudgetWizardView: View {
    private enum WizardStep: Int, CaseIterable {
        case income
        case target
        case review

        var title: String {
            switch self {
            case .income: return "Income baseline"
            case .target: return "Budget target"
            case .review: return "Review plan"
            }
        }

        var body: String {
            switch self {
            case .income:
                return "Start with the monthly income that actually lands in your hands so the rest of the plan stays honest."
            case .target:
                return "Choose a spending ceiling you can realistically defend. The goal is control, not punishment."
            case .review:
                return "Check the plan before saving so the month feels intentional from day one."
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

    @State private var step: WizardStep = .income
    @State private var income = ""
    @State private var budget = ""
    @State private var note: String?
    @State private var isPresentingGuide = false
    @State private var hasPresentedInitialGuide = false

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
            .navigationTitle("Budget Wizard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        viewModel.dismissBudgetWizard()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Guide") {
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

            guard !hasPresentedInitialGuide else { return }
            hasPresentedInitialGuide = true
            if !GuideProgressStore.isSeen(.budgetWizard) {
                isPresentingGuide = true
            }
        }
    }

    private var heroCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                BrandBadge(text: "3-step setup", systemImage: "wand.and.stars")

                Text("Budget wizard")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandTheme.ink)

                Text("Set income, choose a monthly target, and review the plan before it becomes the default frame for the app.")
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
                Text("Progress")
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
                    Text("Step 1 · Monthly income")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)

                    Text("Use the amount that normally lands after taxes or fees so the rest of the budget stays grounded.")
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)

                    budgetField(title: "Monthly income", value: $income, placeholder: "4200")

                    if let suggestedBudget {
                        BrandMetricTile(
                            title: "Suggested safe budget",
                            value: suggestedBudget.formatted(.currency(code: "USD")),
                            systemImage: "leaf.fill"
                        )
                    }

                    stepControls(primaryTitle: "Next")
                }
            }
        case .target:
            SurfaceCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Step 2 · Target budget")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)

                    Text("Choose the amount you want the month to run on. This becomes the ceiling the dashboard and coach cues work against.")
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)

                    budgetField(title: "Monthly budget", value: $budget, placeholder: "2800")

                    HStack(spacing: 12) {
                        BrandMetricTile(
                            title: "Income",
                            value: (parsedIncome ?? 0).formatted(.currency(code: "USD")),
                            systemImage: "banknote.fill"
                        )
                        BrandMetricTile(
                            title: "Projected buffer",
                            value: projectedRemaining.formatted(.currency(code: "USD")),
                            systemImage: "shield.lefthalf.filled"
                        )
                    }

                    stepControls(primaryTitle: "Review")
                }
            }
        case .review:
            SurfaceCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Step 3 · Review the plan")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)

                    Text("This summary is what the dashboard will use to frame safe-to-spend, progress, and next actions.")
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        BrandMetricTile(
                            title: "Income",
                            value: (parsedIncome ?? 0).formatted(.currency(code: "USD")),
                            systemImage: "banknote.fill"
                        )
                        BrandMetricTile(
                            title: "Budget",
                            value: (parsedBudget ?? 0).formatted(.currency(code: "USD")),
                            systemImage: "chart.bar.fill"
                        )
                        BrandMetricTile(
                            title: "Buffer",
                            value: projectedRemaining.formatted(.currency(code: "USD")),
                            systemImage: "lock.shield.fill"
                        )
                        BrandMetricTile(
                            title: "Mode",
                            value: viewModel.session == .guest ? "Guest local" : "Signed in",
                            systemImage: "iphone.gen3"
                        )
                    }

                    BrandFeatureRow(
                        systemImage: "checkmark.circle.fill",
                        title: "You can change this later",
                        detail: "Budget Wizard is a setup aid, not a one-time lock. You can reopen it from Settings whenever the month changes."
                    )

                    stepControls(primaryTitle: "Save local budget", isFinal: true)
                }
            }
        }
    }

    private var summaryCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("What happens next")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                BrandFeatureRow(
                    systemImage: "house.fill",
                    title: "Dashboard gets recalibrated",
                    detail: "Safe-to-spend, monthly progress, and coach cues will use this budget right away."
                )

                BrandFeatureRow(
                    systemImage: "sparkles.rectangle.stack.fill",
                    title: "Missions get sharper",
                    detail: "Goals become clearer when the app knows the spending ceiling you want to defend."
                )
            }
        }
    }

    private func budgetField(title: String, value: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)

            TextField(placeholder, text: value)
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
                Button("Back") {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.92)) {
                        step = WizardStep(rawValue: step.rawValue - 1) ?? .income
                    }
                }
                .buttonStyle(SecondaryCTAStyle())
            }

            Button(primaryTitle) {
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
            note = "Use valid decimal numbers."
            return
        }

        guard incomeValue > 0, budgetValue > 0 else {
            note = "Income and budget must be greater than zero."
            return
        }

        note = nil
        await viewModel.saveBudget(monthlyIncome: incomeValue, monthlyBudget: budgetValue)
    }
}
