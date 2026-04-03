import SwiftUI

struct BudgetWizardView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var income = ""
    @State private var budget = ""
    @State private var note: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Budget wizard")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(BrandTheme.ink)

                            Text("Set your monthly income and target budget to keep your spending plan realistic.")
                                .foregroundStyle(BrandTheme.muted)

                            budgetField(title: "Monthly income", value: $income)
                            budgetField(title: "Monthly budget", value: $budget)

                            if let note {
                                Text(note)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            }

                            Button("Save local budget") {
                                Task { await save() }
                            }
                            .buttonStyle(PrimaryCTAStyle())
                        }
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
            }
        }
        .onAppear {
            if let ledger = viewModel.ledger {
                income = NSDecimalNumber(decimal: ledger.monthlyIncome).stringValue
                budget = NSDecimalNumber(decimal: ledger.monthlyBudget).stringValue
            }
        }
    }

    private func budgetField(title: String, value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)
            TextField("0", text: value)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color.black.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func save() async {
        guard let incomeValue = Decimal(string: income), let budgetValue = Decimal(string: budget) else {
            note = "Use valid decimal numbers."
            return
        }
        note = nil
        await viewModel.saveBudget(monthlyIncome: incomeValue, monthlyBudget: budgetValue)
    }
}
