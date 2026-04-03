import SwiftUI

struct FinanceRulesToolView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var keyword = ""
    @State private var category = ExpenseCategory.other
    @State private var note = ""
    @State private var errorMessage: String?

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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Auto-categorization",
                    title: "Rules",
                    summary: "Create lightweight merchant rules so local imports and receipt drafts land in the right category automatically.",
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

                        HStack(spacing: 12) {
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
                                title: "Disabled",
                                value: "\(disabledRuleCount)",
                                systemImage: "pause.circle.fill"
                            )
                        }
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
                            Text("Saved rules")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)

                            ForEach(viewModel.rules) { rule in
                                ruleRow(rule)

                                if rule.id != viewModel.rules.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Add rule")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        FinanceField(label: "Merchant keyword", placeholder: "Uber", text: $keyword)

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

                        FinanceMultilineField(
                            label: "Internal note",
                            placeholder: "Optional context for this rule",
                            text: $note
                        )

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Button("Save rule") {
                            Task { await saveRule() }
                        }
                        .buttonStyle(PrimaryCTAStyle())
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
        let activityState = viewModel.ledger?.ruleActivityState(for: rule) ?? .dormant

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(rule.merchantKeyword)
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)

                    Text("\(matches) matching local transaction\(matches == 1 ? "" : "s")")
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }

                Spacer()

                Label(rule.category.rawValue, systemImage: rule.category.symbolName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(BrandTheme.primary)
            }

            HStack(spacing: 8) {
                ruleChip(title: activityState.rawValue, systemImage: activityState.symbolName, color: ruleChipColor(activityState))
                if let note = rule.note, !note.isEmpty {
                    ruleChip(title: "Note saved", systemImage: "note.text", color: BrandTheme.muted)
                }
                Spacer()
            }

            if let note = rule.note, !note.isEmpty {
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Button(rule.isEnabled ? "Disable" : "Enable") {
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

    private func ruleChip(title: String, systemImage: String, color: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func ruleChipColor(_ state: RuleActivityState) -> Color {
        switch state {
        case .active:
            return BrandTheme.primary
        case .quiet:
            return .orange
        case .dormant:
            return BrandTheme.muted
        case .disabled:
            return .red
        }
    }

    private func saveRule() async {
        guard !keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Add a merchant keyword."
            return
        }

        errorMessage = nil
        await viewModel.addRule(
            RuleDraft(
                merchantKeyword: keyword,
                category: category,
                note: note
            )
        )

        keyword = ""
        category = .other
        note = ""
    }
}
