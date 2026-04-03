import UIKit
import SwiftUI

struct AddExpenseView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var merchant = ""
    @State private var amount = ""
    @State private var category = ExpenseCategory.groceries
    @State private var date = Date()
    @State private var note = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    previewCard

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            field(label: "Merchant or title", placeholder: "Supermarket", text: $merchant)
                            field(label: "Amount", placeholder: "24.50", text: $amount, keyboard: .decimalPad)

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

                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .tint(BrandTheme.primary)

                            field(label: "Note", placeholder: "Optional note", text: $note)
                        }
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
    }

    private var canSave: Bool {
        !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && Decimal(string: amount) != nil
    }

    private var previewCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Summary")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.muted)

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: category.symbolName)
                        .frame(width: 40, height: 40)
                        .foregroundStyle(BrandTheme.primary)
                        .background(BrandTheme.primary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(merchant.isEmpty ? "Merchant" : merchant)
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text(category.rawValue)
                            .font(.footnote)
                            .foregroundStyle(BrandTheme.muted)
                    }

                    Spacer()

                    Text(previewAmount, format: .currency(code: "USD"))
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                }
            }
        }
    }

    private var previewAmount: Decimal {
        Decimal(string: amount) ?? 0
    }

    private func field(label: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)

            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding()
                .background(Color.black.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func saveExpense() async {
        guard let amountValue = Decimal(string: amount) else {
            errorMessage = "Enter a valid amount."
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
