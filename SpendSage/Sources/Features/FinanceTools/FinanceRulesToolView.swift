import SwiftUI

struct FinanceRulesToolView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var name = ""
    @State private var merchantContains = ""
    @State private var category = ExpenseCategory.other
    @State private var paymentMethod = ""
    @State private var note = ""
    @State private var errorMessage: String?
    @State private var editingRuleID: UUID?
    @AppStorage("native.rules.presentationMetadata") private var presentationMetadataJSON = "{}"

    private var matchedTransactions: Int {
        guard let ledger = viewModel.ledger else { return 0 }
        return viewModel.rules.reduce(0) { $0 + ledger.matchingExpensesCount(for: $1) }
    }

    private var disabledRuleCount: Int {
        viewModel.rules.filter { !$0.isEnabled }.count
    }

    private var activeRuleCount: Int {
        viewModel.rules.filter { $0.isEnabled }.count
    }

    private var activeRules: [RuleRecord] {
        viewModel.rules.filter { $0.isEnabled }
    }

    private var pausedRules: [RuleRecord] {
        viewModel.rules.filter { !$0.isEnabled }
    }

    private var editingRule: RuleRecord? {
        guard let editingRuleID else { return nil }
        return viewModel.rules.first(where: { $0.id == editingRuleID })
    }

    private var presentationMetadata: [String: RulePresentationMetadata] {
        decodePresentationMetadata(presentationMetadataJSON)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Auto-categorization",
                    title: "Rules",
                    summary: "Create lightweight merchant rules so local imports and receipt drafts land in the right category automatically. Keep useful rules active, pause the noisy ones, and edit without rebuilding the whole match.",
                    systemImage: "slider.horizontal.3"
                )

                if let notice = viewModel.notice {
                    FinanceNoticeCard(message: notice)
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Rules performance")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                            spacing: 12
                        ) {
                            BrandMetricTile(
                                title: "Rules",
                                value: "\(viewModel.rules.count)",
                                systemImage: "line.3.horizontal.decrease.circle.fill"
                            )
                            BrandMetricTile(
                                title: "Matches",
                                value: "\(matchedTransactions)",
                                systemImage: "wand.and.stars"
                            )
                            BrandMetricTile(
                                title: "Active",
                                value: "\(activeRuleCount)",
                                systemImage: "play.circle.fill"
                            )
                            BrandMetricTile(
                                title: "Paused",
                                value: "\(disabledRuleCount)",
                                systemImage: "pause.circle.fill"
                            )
                        }

                        BrandFeatureRow(
                            systemImage: "square.and.pencil",
                            title: "Edit-friendly",
                            detail: "Changing a rule keeps the merchant keyword around, while pause lets you keep it ready for later instead of deleting it outright."
                        )
                    }
                }

                if viewModel.rules.isEmpty {
                    FinanceEmptyStateCard(
                        title: "No rules yet",
                        summary: "Add merchant keywords like Uber, Whole Foods, or Apple to keep imported expenses cleaner.",
                        systemImage: "wand.and.rays.inverse"
                    )
                } else {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Active automation rules")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)

                            if activeRules.isEmpty {
                                Text("No active rules right now. Paused rules stay visible below.")
                                    .font(.footnote)
                                    .foregroundStyle(BrandTheme.muted)
                            }

                            ForEach(activeRules) { rule in
                                ruleRow(rule)

                                if rule.id != activeRules.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                if !pausedRules.isEmpty {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Paused rules")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)

                            Text("Paused rules stay saved and can be resumed without rewriting the merchant match.")
                                .font(.footnote)
                                .foregroundStyle(BrandTheme.muted)

                            ForEach(pausedRules) { rule in
                                ruleRow(rule)

                                if rule.id != pausedRules.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(editingRuleID == nil ? "Add rule" : "Edit rule")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        FinanceField(label: "Rule name", placeholder: "Ride share", text: $name)

                        FinanceField(label: "Merchant contains", placeholder: "Uber", text: $merchantContains)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BrandTheme.muted)

                            Picker("Category", selection: $category) {
                                ForEach(ExpenseCategory.allCases) { item in
                                    Label(item.rawValue, systemImage: item.symbolName)
                                        .tag(item)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        FinanceField(
                            label: "Payment method (optional)",
                            placeholder: "Apple Pay, Visa, cash...",
                            text: $paymentMethod
                        )

                        FinanceMultilineField(
                            label: "Note / context (optional)",
                            placeholder: "Optional context for this rule",
                            text: $note
                        )

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Text("Active rules keep matching silently. Paused rules stay saved for later, so you can bring them back instead of rewriting them.")
                            .font(.footnote)
                            .foregroundStyle(BrandTheme.muted)

                        Button(editingRuleID == nil ? "Save rule" : "Save changes") {
                            Task { await saveRule() }
                        }
                        .buttonStyle(PrimaryCTAStyle())

                        if editingRuleID != nil {
                            Button("Cancel edit") {
                                resetForm()
                            }
                            .buttonStyle(SecondaryCTAStyle())
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .navigationTitle("Rules")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.ledger == nil {
                await viewModel.refreshDashboard()
            }
        }
    }

    private func ruleRow(_ rule: RuleRecord) -> some View {
        let matches = viewModel.ledger?.matchingExpensesCount(for: rule) ?? 0
        let displayName = ruleDisplayName(for: rule)
        let paymentMethod = rulePaymentMethod(for: rule)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)

                    Text(rule.merchantKeyword)
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)

                    Text("\(matches) matching local transaction\(matches == 1 ? "" : "s")")
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Label(rule.category.rawValue, systemImage: rule.category.symbolName)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.primary)

                    ruleChip(
                        title: rule.isEnabled ? "Active" : "Paused",
                        systemImage: rule.isEnabled ? "play.circle.fill" : "pause.circle.fill",
                        color: rule.isEnabled ? BrandTheme.primary : .orange
                    )
                }
            }

            HStack(spacing: 8) {
                Button("Edit") {
                    beginEdit(rule)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                if !paymentMethod.isEmpty {
                    ruleChip(title: paymentMethod, systemImage: "creditcard.fill", color: BrandTheme.muted)
                }
                Spacer()
            }

            Text("Merchant contains: \(rule.merchantKeyword)")
                .font(.footnote)
                .foregroundStyle(BrandTheme.muted)

            if let note = rule.note, !note.isEmpty {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Button(rule.isEnabled ? "Pause" : "Resume") {
                    Task { await viewModel.toggleRuleEnabled(rule.id) }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button(role: .destructive) {
                    Task { await viewModel.deleteRule(rule.id) }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private func beginEdit(_ rule: RuleRecord) {
        editingRuleID = rule.id
        name = ruleDisplayName(for: rule)
        merchantContains = rule.merchantKeyword
        category = rule.category
        paymentMethod = rulePaymentMethod(for: rule)
        note = rule.note ?? ""
        errorMessage = nil
    }

    private func resetForm() {
        editingRuleID = nil
        name = ""
        merchantContains = ""
        category = .other
        paymentMethod = ""
        note = ""
        errorMessage = nil
    }

    private func ruleChip(title: String, systemImage: String, color: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func saveRule() async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMerchantContains = merchantContains.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPaymentMethod = paymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedMerchantContains.isEmpty else {
            errorMessage = "Add a rule name and a merchant match value."
            return
        }

        let wasEnabled = editingRule?.isEnabled ?? true
        let originalEditingID = editingRuleID
        let previousIDs = Set(viewModel.rules.map(\.id))
        errorMessage = nil

        if let originalEditingID {
            await viewModel.deleteRule(originalEditingID)
        }

        await viewModel.addRule(
            RuleDraft(
                merchantKeyword: trimmedMerchantContains,
                category: category,
                note: note
            )
        )

        let newRuleID = Set(viewModel.rules.map(\.id)).subtracting(previousIDs).first

        if let newRuleID {
            updatePresentationMetadata(for: newRuleID) { metadata in
                metadata.name = trimmedName
                metadata.paymentMethod = trimmedPaymentMethod
            }
            if let originalEditingID {
                removePresentationMetadata(for: originalEditingID)
            }
        } else if let originalEditingID {
            updatePresentationMetadata(for: originalEditingID) { metadata in
                metadata.name = trimmedName
                metadata.paymentMethod = trimmedPaymentMethod
            }
        }

        if !wasEnabled, let newRuleID {
            await viewModel.toggleRuleEnabled(newRuleID)
        }

        resetForm()
    }

    private func ruleDisplayName(for rule: RuleRecord) -> String {
        presentationMetadata[rule.id.uuidString]?.name.trimmingCharacters(in: .whitespacesAndNewlines)
            .nonEmpty ?? rule.merchantKeyword
    }

    private func rulePaymentMethod(for rule: RuleRecord) -> String {
        presentationMetadata[rule.id.uuidString]?.paymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
            .nonEmpty ?? ""
    }

    private func decodePresentationMetadata(_ raw: String) -> [String: RulePresentationMetadata] {
        guard let data = raw.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: RulePresentationMetadata].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private func encodePresentationMetadata(_ metadata: [String: RulePresentationMetadata]) -> String {
        guard let data = try? JSONEncoder().encode(metadata),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }

    private func updatePresentationMetadata(for ruleID: UUID, mutate: (inout RulePresentationMetadata) -> Void) {
        var metadata = presentationMetadata
        var entry = metadata[ruleID.uuidString] ?? RulePresentationMetadata()
        mutate(&entry)
        metadata[ruleID.uuidString] = entry
        presentationMetadataJSON = encodePresentationMetadata(metadata)
    }

    private func removePresentationMetadata(for ruleID: UUID) {
        var metadata = presentationMetadata
        metadata.removeValue(forKey: ruleID.uuidString)
        presentationMetadataJSON = encodePresentationMetadata(metadata)
    }
}

private struct RulePresentationMetadata: Codable {
    var name: String
    var paymentMethod: String

    init(name: String = "", paymentMethod: String = "") {
        self.name = name
        self.paymentMethod = paymentMethod
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
