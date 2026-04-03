import SwiftUI

struct OnboardingView: View {
    let onContinue: () -> Void

    @AppStorage("native.settings.language") private var language = "en"
    @State private var monthlyIncome = ""
    @State private var fixedBills = ""
    @State private var currentBalance = ""
    @State private var goalTrack: GoalTrack = .savings
    @State private var goalTarget = ""
    @State private var goalTargetDate = Calendar.current.date(byAdding: .day, value: 90, to: .now) ?? .now
    @State private var persona: Persona = .youngProfessional
    @State private var isPreviewVisible = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                if isPreviewVisible, snapshot != nil {
                    previewCard
                } else {
                    setupCard
                }
            }
            .padding(24)
        }
        .background(
            ZStack {
                BrandTheme.canvas
                BrandBackdropView()
            }
            .ignoresSafeArea()
        )
        .overlay(alignment: .topLeading) {
            languagePicker
                .padding(.leading, 24)
                .padding(.top, 12)
        }
    }

    private var heroCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                BrandBadge(text: "First win in under a minute", systemImage: "sparkles")

                VStack(alignment: .leading, spacing: 10) {
                    Text("See your first safe-to-spend result fast")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandTheme.ink)

                    Text("Add income, fixed bills, and one goal. The result flips in place like a first-win card, and current balance stays optional.")
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 12) {
                    BrandMetricTile(title: "Setup", value: "Income + goal", systemImage: "bolt.fill")
                    BrandMetricTile(title: "Result", value: "Safe to spend", systemImage: "banknote.fill")
                    BrandMetricTile(title: "Mode", value: "Local first", systemImage: "iphone.gen3")
                }
            }
        }
    }

    private var setupCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                BrandBadge(text: "First win in under a minute", systemImage: "sparkles")

                VStack(alignment: .leading, spacing: 10) {
                    Text("See your first safe-to-spend result fast")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandTheme.ink)

                    Text("Add income, fixed bills, and one goal. The result flips in place like a first-win card, and current balance stays optional.")
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 12) {
                    BrandMetricTile(title: "Setup", value: "Income + goal", systemImage: "bolt.fill")
                    BrandMetricTile(title: "Result", value: "Safe to spend", systemImage: "banknote.fill")
                    BrandMetricTile(title: "Mode", value: "Local first", systemImage: "iphone.gen3")
                }

                sectionHeader(
                    number: "01",
                    title: "Build the first win",
                    summary: "Fill the setup, flip to the result, then continue or edit anytime."
                )

                moneyField(title: "Monthly income", placeholder: "3000", text: $monthlyIncome)

                moneyField(title: "Fixed bills", placeholder: "1200", text: $fixedBills)

                moneyField(title: "Current balance", placeholder: "650", text: $currentBalance, allowsEmpty: true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Goal track")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.muted)

                    Picker("Goal track", selection: $goalTrack) {
                        ForEach(GoalTrack.allCases) { track in
                            Text(track.title).tag(track)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                moneyField(title: "Goal target", placeholder: "800", text: $goalTarget)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Goal target date")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.muted)

                    DatePicker(
                        "Goal target date",
                        selection: $goalTargetDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.black.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Persona")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.muted)

                    Picker("Persona", selection: $persona) {
                        ForEach(Persona.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Button {
                    isPreviewVisible = true
                } label: {
                    Label(isPreviewVisible ? "Refresh preview" : "Show my first win", systemImage: "arrow.right.circle.fill")
                }
                .buttonStyle(PrimaryCTAStyle())
                .disabled(snapshot == nil)
            }
        }
    }

    private var previewCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                if let snapshot = snapshot {
                    BrandArtworkSurface {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Your first win")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)

                            Text(currency(snapshot.safeToSpendWeekCents))
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(BrandTheme.primary)

                            BrandBadge(text: snapshot.goalTrack.title, systemImage: "arrow.triangle.branch")

                            Text(snapshot.nextAction)
                                .font(.subheadline)
                                .foregroundStyle(BrandTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("Confidence \(snapshot.confidence)%")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BrandTheme.muted)
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            onContinue()
                        } label: {
                            Label("Get started", systemImage: "arrow.right.circle.fill")
                        }
                        .buttonStyle(PrimaryCTAStyle())

                        Button("Edit inputs") {
                            isPreviewVisible = false
                        }
                        .buttonStyle(SecondaryCTAStyle())
                    }
                }
            }
        }
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
            nextAction = "Set aside \(currency(goalReserveCents)) each month and keep your weekly spending inside \(currency(weeklyGuardrail))."
        case .debt:
            nextAction = "Use \(currency(weeklyGuardrail)) as the guardrail and send the extra room toward debt payoff."
        case .impulseControl:
            nextAction = "Keep one weekly spending lane and pause non-essential purchases before you tap buy."
        case .emergencyFund:
            nextAction = "Build the buffer first, then keep the weekly guardrail steady until your target date."
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
        (Decimal(cents) / 100).formatted(.currency(code: "USD"))
    }

    private var languagePicker: some View {
        Menu {
            Button("English") { language = "en" }
            Button("Español") { language = "es" }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                Text(language.uppercased())
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
                Text(title)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text(summary)
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
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)

            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(Color.black.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
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
