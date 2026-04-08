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
                    eyebrow: "Autocategorización",
                    title: "Reglas",
                    summary: "Crea reglas ligeras por comercio para que importaciones locales y borradores de recibos caigan solos en la categoría correcta. Mantén activas las útiles, pausa las ruidosas y edítalas sin reconstruir todo.",
                    systemImage: "slider.horizontal.3",
                    surface: .rules
                )

                if let notice = viewModel.notice {
                    FinanceNoticeCard(message: notice)
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Rendimiento de reglas")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                            spacing: 12
                        ) {
                            BrandMetricTile(
                                title: "Reglas",
                                value: "\(viewModel.rules.count)",
                                systemImage: "line.3.horizontal.decrease.circle.fill"
                            )
                            BrandMetricTile(
                                title: "Coincidencias",
                                value: "\(matchedTransactions)",
                                systemImage: "wand.and.stars"
                            )
                            BrandMetricTile(
                                title: "Activas",
                                value: "\(activeRuleCount)",
                                systemImage: "play.circle.fill"
                            )
                            BrandMetricTile(
                                title: "Pausadas",
                                value: "\(disabledRuleCount)",
                                systemImage: "pause.circle.fill"
                            )
                        }

                        BrandFeatureRow(
                            systemImage: "square.and.pencil",
                            title: "Fácil de editar",
                            detail: "Al editar una regla conservas la palabra clave del comercio, y pausar la deja lista para después sin tener que borrarla."
                        )
                    }
                }

                if viewModel.rules.isEmpty {
                    FinanceEmptyStateCard(
                        title: "Todavía no hay reglas",
                        summary: "Agrega palabras clave de comercios como Uber, Supermaxi o Apple para mantener más limpios los gastos importados.",
                        systemImage: "wand.and.rays.inverse"
                    )
                } else {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Reglas activas")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)

                            if activeRules.isEmpty {
                                Text("No hay reglas activas ahora mismo. Las pausadas siguen visibles abajo.")
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
                            Text("Reglas pausadas")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)

                            Text("Las reglas pausadas se guardan y pueden retomarse sin reescribir la coincidencia del comercio.")
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
                        Text(editingRuleID == nil ? "Agregar regla" : "Editar regla")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        FinanceField(label: "Nombre de la regla", placeholder: "Viaje compartido", text: $name)

                        FinanceField(label: "El comercio contiene", placeholder: "Uber", text: $merchantContains)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Categoría")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BrandTheme.muted)

                            Picker("Categoría", selection: $category) {
                                ForEach(ExpenseCategory.allCases) { item in
                                    Label(item.rawValue, systemImage: item.symbolName)
                                        .tag(item)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        FinanceField(
                            label: "Método de pago (opcional)",
                            placeholder: "Apple Pay, Visa, efectivo...",
                            text: $paymentMethod
                        )

                        FinanceMultilineField(
                            label: "Nota o contexto (opcional)",
                            placeholder: "Contexto opcional de esta regla",
                            text: $note
                        )

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Text("Las reglas activas siguen emparejando en silencio. Las pausadas quedan guardadas para después, así que puedes traerlas de vuelta sin reescribirlas.")
                            .font(.footnote)
                            .foregroundStyle(BrandTheme.muted)

                        Button(editingRuleID == nil ? "Guardar regla" : "Guardar cambios") {
                            Task { await saveRule() }
                        }
                        .buttonStyle(PrimaryCTAStyle())

                        if editingRuleID != nil {
                            Button("Cancelar edición") {
                                resetForm()
                            }
                            .buttonStyle(SecondaryCTAStyle())
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(FinanceScreenBackground())
        .navigationTitle("Reglas")
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

                    Text(AppLocalization.localized("%d transacción%@ local%@ coinciden", arguments: matches, matches == 1 ? "" : "es", matches == 1 ? "" : "n"))
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Label(rule.category.localizedTitle, systemImage: rule.category.symbolName)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.primary)

                    ruleChip(
                        title: rule.isEnabled ? "Activa" : "Pausada",
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
        errorMessage = nil

        if let originalEditingID {
            await viewModel.updateRule(
                originalEditingID,
                draft: RuleDraft(
                    merchantKeyword: trimmedMerchantContains,
                    category: category,
                    note: note
                )
            )
        } else {
            await viewModel.addRule(
                RuleDraft(
                    merchantKeyword: trimmedMerchantContains,
                    category: category,
                    note: note
                )
            )
        }

        let targetRuleID = originalEditingID
            ?? viewModel.rules.first(where: { $0.merchantKeyword == trimmedMerchantContains && $0.category == category })?.id

        if let targetRuleID {
            updatePresentationMetadata(for: targetRuleID) { metadata in
                metadata.name = trimmedName
                metadata.paymentMethod = trimmedPaymentMethod
            }
        }

        if let originalEditingID, let targetRuleID, originalEditingID != targetRuleID {
            removePresentationMetadata(for: originalEditingID)
        }

        if !wasEnabled, let targetRuleID {
            await viewModel.toggleRuleEnabled(targetRuleID)
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
