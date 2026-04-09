import SwiftUI
import UIKit

struct OnboardingView: View {
    let onContinue: () -> Void

    private enum Step: Int, CaseIterable, Identifiable {
        case basics
        case goal
        case preview

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .basics:
                return "Basics"
            case .goal:
                return "Goal"
            case .preview:
                return "Preview"
            }
        }
    }

    @AppStorage("native.settings.language") private var language = "auto"
    @AppStorage(AppCurrencyFormat.defaultsKey) private var currencyCode = AppCurrencyFormat.defaultCode
    @State private var monthlyIncome = ""
    @State private var fixedBills = ""
    @State private var currentBalance = ""
    @State private var goalTrack: GoalTrack = .savings
    @State private var goalTarget = ""
    @State private var goalTargetDate = Calendar.current.date(byAdding: .day, value: 90, to: .now) ?? .now
    @State private var persona: Persona = .youngProfessional
    @State private var step: Step = .basics

    private var story: BrandNarrativeSpec {
        BrandStoryCatalog.spec(for: .onboarding)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                stepRail
                currentStepCard
            }
            .padding(24)
            .padding(.bottom, 120)
        }
        .scrollDismissesKeyboard(.interactively)
        .accessibilityIdentifier("onboarding.screen")
        .background(
            ZStack {
                BrandTheme.canvas
                BrandBackdropView()
            }
            .ignoresSafeArea()
        )
        .safeAreaInset(edge: .bottom, spacing: 0) {
            footerActions
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                languagePicker
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    dismissKeyboard()
                }
            }
        }
    }

    private var heroCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                BrandBadge(text: story.badgeText, systemImage: "sparkles")

                Text("Your first money win in 3 steps")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Start with income, fixed bills, and one goal. The crew guides the setup so the first plan feels quick and clear.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                BrandArtworkSurface {
                    BrandAssetImage(
                        source: story.sceneSource,
                        fallbackSystemImage: "person.3.fill"
                    )
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 144)
                }

                CharacterCrewRail(
                    members: [
                        CharacterCrewMember(
                            title: "Tikki",
                            role: "Plan guide",
                            detail: "Keeps the setup short and useful.",
                            character: .tikki,
                            expression: .proud
                        ),
                        CharacterCrewMember(
                            title: "Ludo",
                            role: "Strategy guide",
                            detail: "Turns a few inputs into a calmer weekly number.",
                            character: .mei,
                            expression: .thinking
                        ),
                        CharacterCrewMember(
                            title: "Manchas",
                            role: "Momentum keeper",
                            detail: "Makes the first win feel friendly instead of technical.",
                            character: .manchas,
                            expression: .happy
                        )
                    ]
                )
            }
        }
    }

    private var stepRail: some View {
        SurfaceCard {
            HStack(spacing: 10) {
                stepButton(.basics, number: "01")
                stepButton(.goal, number: "02")
                stepButton(.preview, number: "03")
            }
        }
    }

    @ViewBuilder
    private var currentStepCard: some View {
        switch step {
        case .basics:
            basicsCard
        case .goal:
            goalCard
        case .preview:
            previewCard
        }
    }

    private var basicsCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(
                    number: "01",
                    title: "Start with the month",
                    summary: "Just enough to estimate your first safe-to-spend number."
                )

                moneyField(title: "Monthly income", placeholder: "3000", text: $monthlyIncome)
                moneyField(title: "Fixed bills", placeholder: "1200", text: $fixedBills)
                moneyField(title: "Current balance", placeholder: "650", text: $currentBalance, allowsEmpty: true)

                BrandFeatureRow(
                    systemImage: "wand.and.stars",
                    title: "Simple start",
                    detail: "You do not need a full financial setup yet. Just the basics for the first useful result."
                )
            }
        }
    }

    private var goalCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(
                    number: "02",
                    title: "Pick one goal",
                    summary: "Choose the target that should shape your first weekly guardrail."
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Goal track")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.muted)

                    Picker("Goal track", selection: $goalTrack) {
                        ForEach(GoalTrack.allCases) { track in
                            Text(track.title.appLocalized).tag(track)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(BrandTheme.surfaceTint)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
                    )
                }

                moneyField(title: "Goal target", placeholder: "800", text: $goalTarget)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Goal target date")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.muted)

                    DatePicker("Goal target date", selection: $goalTargetDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(BrandTheme.surfaceTint)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Persona")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.muted)

                    Picker("Persona", selection: $persona) {
                        ForEach(Persona.allCases) { item in
                            Text(item.title.appLocalized).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    private var previewCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(
                    number: "03",
                    title: "Review your first win",
                    summary: "See the weekly number and the next move before entering the app."
                )

                if let snapshot {
                    BrandArtworkSurface {
                        VStack(alignment: .leading, spacing: 14) {
                            MascotSpeechCard(
                                character: .mei,
                                expression: .proud,
                                title: "Ludo",
                                message: snapshot.nextAction
                            )

                            Text(currency(snapshot.safeToSpendWeekCents))
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(BrandTheme.primary)

                            BrandBadge(text: "Safe to spend this week", systemImage: "banknote.fill")

                            HStack(spacing: 12) {
                                BrandMetricTile(
                                    title: "Goal reserve",
                                    value: currency(snapshot.goalReserveCents),
                                    systemImage: "target"
                                )
                                BrandMetricTile(
                                    title: "Target date",
                                    value: snapshot.goalTargetDate.formatted(.dateTime.month(.abbreviated).day()),
                                    systemImage: "calendar"
                                )
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(snapshot.persona.title.appLocalized)
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(BrandTheme.ink)
                                    Spacer()
                                    Text(AppLocalization.localized("Confidence %d%%", arguments: snapshot.confidence))
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(BrandTheme.muted)
                                }

                                ProgressView(value: snapshot.progressFraction)
                                    .tint(BrandTheme.primary)
                            }
                        }
                    }
                } else {
                    emptyPreviewCard
                }
            }
        }
    }

    private var emptyPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandFeatureRow(
                systemImage: "exclamationmark.triangle.fill",
                title: "Finish the setup first",
                detail: "Add income, bills, and one goal to generate the first preview."
            )

            Button("Back") {
                step = .goal
            }
            .buttonStyle(SecondaryCTAStyle())
            .accessibilityIdentifier("onboarding.action.emptyBack")
        }
    }

    private func stepButton(_ target: Step, number: String) -> some View {
        Button {
            if target == .preview, snapshot == nil {
                step = .goal
            } else {
                step = target
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(number)
                    .font(.caption.weight(.bold))
                Text(target.title.appLocalized)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(step == target ? BrandTheme.primary : BrandTheme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 58, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(step == target ? BrandTheme.accent.opacity(0.22) : BrandTheme.surfaceTint)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(step == target ? BrandTheme.primary.opacity(0.35) : BrandTheme.line.opacity(0.7), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var footerActions: some View {
        VStack(spacing: 0) {
            Divider()
                .background(BrandTheme.line.opacity(0.65))

            HStack(spacing: 12) {
                switch step {
                case .basics:
                    Button("Continue to goal") {
                        dismissKeyboard()
                        step = .goal
                    }
                    .buttonStyle(PrimaryCTAStyle())
                    .disabled(!canAdvanceToGoal)
                    .accessibilityIdentifier("onboarding.action.continueToGoal")

                case .goal:
                    Button("Back") {
                        dismissKeyboard()
                        step = .basics
                    }
                    .buttonStyle(SecondaryCTAStyle())
                    .accessibilityIdentifier("onboarding.action.backToBasics")

                    Button("Show preview") {
                        dismissKeyboard()
                        step = .preview
                    }
                    .buttonStyle(PrimaryCTAStyle())
                    .disabled(snapshot == nil)
                    .accessibilityIdentifier("onboarding.action.showPreview")

                case .preview:
                    Button("Back") {
                        dismissKeyboard()
                        step = .goal
                    }
                    .buttonStyle(SecondaryCTAStyle())
                    .accessibilityIdentifier("onboarding.action.backToGoal")

                    Button {
                        dismissKeyboard()
                        onContinue()
                    } label: {
                        Label("Get started", systemImage: "arrow.right.circle.fill")
                    }
                    .buttonStyle(PrimaryCTAStyle())
                    .disabled(snapshot == nil)
                    .accessibilityIdentifier("onboarding.action.getStarted")
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 20)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(BrandTheme.canvas.opacity(0.88))
            )
        }
    }

    private var canAdvanceToGoal: Bool {
        guard
            let monthlyIncomeCents = parseMoneyCents(monthlyIncome),
            monthlyIncomeCents > 0,
            let fixedBillsCents = parseMoneyCents(fixedBills),
            fixedBillsCents >= 0
        else {
            return false
        }
        return true
    }

    private var snapshot: FirstWinSnapshot? {
        guard
            let monthlyIncomeCents = parseMoneyCents(monthlyIncome),
            monthlyIncomeCents > 0,
            let fixedBillsCents = parseMoneyCents(fixedBills),
            fixedBillsCents >= 0,
            let goalTargetCents = parseMoneyCents(goalTarget),
            goalTargetCents > 0
        else {
            return nil
        }

        return buildSnapshot(
            monthlyIncomeCents: monthlyIncomeCents,
            fixedBillsCents: fixedBillsCents,
            currentBalanceCents: parseMoneyCents(currentBalance, allowsEmpty: true),
            goalTrack: goalTrack,
            goalTargetCents: goalTargetCents,
            goalTargetDate: goalTargetDate,
            persona: persona
        )
    }

    private func buildSnapshot(
        monthlyIncomeCents: Int,
        fixedBillsCents: Int,
        currentBalanceCents: Int?,
        goalTrack: GoalTrack,
        goalTargetCents: Int,
        goalTargetDate: Date,
        persona: Persona
    ) -> FirstWinSnapshot {
        let disposableCents = max(0, monthlyIncomeCents - fixedBillsCents)
        let balanceCents = max(0, currentBalanceCents ?? 0)
        let goalReserveCents = max(0, goalTargetCents / 6)
        let weeklyGuardrail = max(0, (disposableCents + (balanceCents / 4) - goalReserveCents) / 4)
        let daysToGoal = max(1, Calendar.current.dateComponents([.day], from: .now, to: goalTargetDate).day ?? 1)
        let confidence = min(
            95,
            max(
                55,
                64
                    + (currentBalanceCents == nil ? 0 : 8)
                    + (goalTrack == .debt ? 4 : 0)
                    + (goalTrack == .emergencyFund ? 6 : 0)
                    + (daysToGoal > 60 ? 6 : 0)
            )
        )

        let nextAction: String
        switch goalTrack {
        case .savings:
            nextAction = AppLocalization.localized(
                "Set aside %@ each month and keep your weekly spending inside %@.",
                arguments: currency(goalReserveCents), currency(weeklyGuardrail)
            )
        case .debt:
            nextAction = AppLocalization.localized(
                "Use %@ as the guardrail and send the extra room toward debt payoff.",
                arguments: currency(weeklyGuardrail)
            )
        case .impulseControl:
            nextAction = "Keep one weekly spending lane and pause non-essential purchases before you tap buy.".appLocalized
        case .emergencyFund:
            nextAction = "Build the buffer first, then keep the weekly guardrail steady until your target date.".appLocalized
        }

        return FirstWinSnapshot(
            safeToSpendWeekCents: weeklyGuardrail,
            goalReserveCents: goalReserveCents,
            goalTrack: goalTrack,
            goalTargetDate: goalTargetDate,
            persona: persona,
            confidence: confidence,
            nextAction: nextAction,
            progressFraction: min(1, Double(min(daysToGoal, 90)) / 90.0)
        )
    }

    private func parseMoneyCents(_ value: String, allowsEmpty: Bool = false) -> Int? {
        let normalized = value.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return allowsEmpty ? nil : nil }
        guard let decimal = Decimal(string: normalized), decimal >= 0 else { return nil }
        return NSDecimalNumber(decimal: decimal * 100).intValue
    }

    private func currency(_ cents: Int) -> String {
        (Decimal(cents) / 100).formatted(.currency(code: currencyCode))
    }

    private var languagePicker: some View {
        Menu {
            Button("Auto".appLocalized) { language = "auto" }
            Button("English".appLocalized) { language = "en" }
            Button("Español".appLocalized) { language = "es" }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                Text(AppLocalization.menuLabel(for: language))
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(BrandTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(BrandTheme.surface, in: Capsule())
            .overlay(
                Capsule(style: .continuous)
                    .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: BrandTheme.shadow.opacity(0.08), radius: 10, x: 0, y: 6)
        }
    }

    private func sectionHeader(number: String, title: String, summary: String) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.appLocalized)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text(summary.appLocalized)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Text(number)
                .font(.headline.weight(.bold))
                .foregroundStyle(BrandTheme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(BrandTheme.accent.opacity(0.18), in: Capsule())
        }
    }

    @ViewBuilder
    private func moneyField(title: String, placeholder: String, text: Binding<String>, allowsEmpty: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.appLocalized)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)

            TextField(placeholder.appLocalized, text: text)
                .keyboardType(.decimalPad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .accessibilityIdentifier(onboardingFieldIdentifier(for: title))
                .background(BrandTheme.surfaceTint)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
                )
        }
    }

    private func onboardingFieldIdentifier(for title: String) -> String {
        switch title {
        case "Monthly income":
            return "onboarding.field.monthlyIncome"
        case "Fixed bills":
            return "onboarding.field.fixedBills"
        case "Current balance":
            return "onboarding.field.currentBalance"
        case "Goal target":
            return "onboarding.field.goalTarget"
        default:
            return "onboarding.field.unknown"
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private struct FirstWinSnapshot {
    let safeToSpendWeekCents: Int
    let goalReserveCents: Int
    let goalTrack: GoalTrack
    let goalTargetDate: Date
    let persona: Persona
    let confidence: Int
    let nextAction: String
    let progressFraction: Double
}

private enum GoalTrack: String, CaseIterable, Identifiable {
    case savings
    case debt
    case impulseControl
    case emergencyFund

    var id: String { rawValue }

    var title: String {
        switch self {
        case .savings: return "Savings"
        case .debt: return "Debt"
        case .impulseControl: return "Impulse control"
        case .emergencyFund: return "Emergency fund"
        }
    }
}

private enum Persona: String, CaseIterable, Identifiable {
    case youngProfessional
    case family

    var id: String { rawValue }

    var title: String {
        switch self {
        case .youngProfessional: return "Young professional"
        case .family: return "Family"
        }
    }
}
