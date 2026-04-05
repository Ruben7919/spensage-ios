import UIKit
import SwiftUI

struct AddExpenseView: View {
    @ObservedObject var viewModel: AppViewModel
    @AppStorage(AppCurrencyFormat.defaultsKey) private var currencyCode = AppCurrencyFormat.defaultCode

    @State private var merchant = ""
    @State private var amount = ""
    @State private var category = ExpenseCategory.groceries
    @State private var date = Date()
    @State private var note = ""
    @State private var errorMessage: String?

    private var merchantAutofillSuggestion: MerchantAutofillSuggestion? {
        viewModel.ledger?.autofillSuggestion(for: merchant)
    }

    private var exactMerchantMatch: MerchantAutofillSuggestion? {
        viewModel.ledger?.exactMerchantMatch(for: merchant)
    }

    private var merchantSuggestions: [MerchantAutofillSuggestion] {
        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedMerchant.isEmpty {
            return viewModel.ledger?.merchantSuggestions(limit: 4) ?? []
        }
        return viewModel.ledger?.merchantSuggestions(matching: trimmedMerchant, limit: 4) ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    FinanceToolsHeaderCard(
                        eyebrow: "Quick capture",
                        title: "Add expense",
                        summary: "Enter the merchant and amount first. Smart fill appears only when it can save you time.",
                        systemImage: "plus.circle.fill",
                        character: .manchas,
                        expression: .happy,
                        sceneKey: "guide_02_log_expense_manchas"
                    )

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            FinanceField(
                                label: "Merchant or title",
                                placeholder: "Supermarket",
                                text: $merchant
                            )
                            FinanceField(
                                label: "Amount",
                                placeholder: "24.50",
                                text: $amount,
                                keyboard: .decimalPad,
                                capitalization: .never
                            )

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Category")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(BrandTheme.muted)

                                Picker("Category", selection: $category) {
                                    ForEach(ExpenseCategory.allCases) { item in
                                        Label(item.localizedTitle, systemImage: item.symbolName)
                                            .tag(item)
                                    }
                                }
                                .pickerStyle(.menu)
                            }

                            DatePicker(selection: $date, displayedComponents: .date) {
                                Text("Date")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(BrandTheme.muted)
                            }
                            .tint(BrandTheme.primary)

                            FinanceField(
                                label: "Note",
                                placeholder: "Optional note",
                                text: $note,
                                capitalization: .sentences
                            )
                        }
                    }

                    if shouldShowSmartAssist {
                        smartAssistCard
                    }

                    if shouldShowPreview {
                        previewCard
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button("Save expense") {
                        Task { await saveExpense() }
                    }
                    .buttonStyle(PrimaryCTAStyle())
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.6)
                }
                .padding(20)
            }
            .background(FinanceScreenBackground())
            .navigationTitle("Add expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.dismissAddExpense()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            errorMessage = nil
        }
        .onChange(of: merchant) { _, newValue in
            applyMerchantAutofillIfNeeded(for: newValue)
        }
    }

    private var canSave: Bool {
        !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (FinanceToolFormatting.decimal(from: amount) ?? 0) > 0
    }

    private var shouldShowPreview: Bool {
        !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || (FinanceToolFormatting.decimal(from: amount) ?? 0) > 0
    }

    private var shouldShowSmartAssist: Bool {
        merchantAutofillSuggestion != nil || !merchantSuggestions.isEmpty
    }

    private var previewCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Draft preview")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Spacer()
                    BrandBadge(text: "Local draft", systemImage: "iphone.gen3")
                }

                Text("Review the merchant, category, and amount before saving.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)

                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(BrandTheme.accent.opacity(0.18))
                        Image(systemName: category.symbolName)
                            .foregroundStyle(BrandTheme.primary)
                    }
                    .frame(width: 42, height: 42)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(merchant.isEmpty ? "Merchant" : merchant)
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text(category.localizedTitle)
                            .font(.footnote)
                            .foregroundStyle(BrandTheme.muted)
                    }

                    Spacer()

                    Text(previewAmount, format: .currency(code: currencyCode))
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                }
            }
        }
    }

    private var smartAssistCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Smart fill")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Spacer()
                    BrandBadge(text: "1 tap", systemImage: "sparkles")
                }

                Text("Reuse the category, amount, and note from a known merchant so logging stays fast.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                if let suggestion = merchantAutofillSuggestion {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: suggestion.category.symbolName)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(BrandTheme.primary)
                            .frame(width: 40, height: 40)
                            .background(BrandTheme.accent.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(suggestion.merchant)
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)
                            Text(
                                AppLocalization.localized(
                                    "%@ · %@ · %@",
                                    arguments: suggestion.category.localizedTitle,
                                    suggestion.lastAmount.formatted(.currency(code: currencyCode)),
                                    suggestion.frequencyLabel
                                )
                            )
                            .font(.footnote)
                            .foregroundStyle(BrandTheme.muted)
                        }

                        Spacer()

                        Button("Use") {
                            applySuggestion(suggestion, includeMerchant: false)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(14)
                    .background(BrandTheme.surfaceTint)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(BrandTheme.line.opacity(0.75), lineWidth: 1)
                    )
                }

                if !merchantSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Recent merchants" : "Matching merchants")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(BrandTheme.muted)

                        FlowStack(spacing: 8, rowSpacing: 8) {
                            ForEach(merchantSuggestions) { suggestion in
                                Button {
                                    applySuggestion(suggestion, includeMerchant: true)
                                } label: {
                                    Text(suggestion.merchant)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(BrandTheme.primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(BrandTheme.primary.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private var previewAmount: Decimal {
        Decimal(string: amount) ?? 0
    }

    private func applySuggestion(_ suggestion: MerchantAutofillSuggestion, includeMerchant: Bool) {
        if includeMerchant {
            merchant = suggestion.merchant
        }
        amount = formatAmount(suggestion.lastAmount)
        category = suggestion.category
        if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let lastNote = suggestion.lastNote, !lastNote.isEmpty {
            note = lastNote
        }
        errorMessage = nil
    }

    private func applyMerchantAutofillIfNeeded(for value: String) {
        guard let suggestion = exactMerchantMatch else { return }

        if amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            amount = formatAmount(suggestion.lastAmount)
        }

        category = suggestion.category

        if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let lastNote = suggestion.lastNote, !lastNote.isEmpty {
            note = lastNote
        }
    }

    private func formatAmount(_ value: Decimal) -> String {
        value.formatted(.number.precision(.fractionLength(2)))
    }

    private func saveExpense() async {
        guard let amountValue = Decimal(string: amount) else {
            errorMessage = "Enter a valid amount.".appLocalized
            return
        }

        errorMessage = nil
        let draft = ExpenseDraft(
            merchant: merchant,
            amount: amountValue,
            category: category,
            date: date,
            note: note
        )
        await viewModel.addExpense(draft)
    }
}
