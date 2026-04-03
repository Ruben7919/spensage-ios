import SwiftUI

struct ExpensesCenterView: View {
    @ObservedObject var viewModel: AppViewModel

    private var expenseRecords: [ExpenseRecord] {
        (viewModel.ledger?.expenses ?? []).sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Track every local expense")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Text("Add expenses quickly, review recent activity, and keep your budget up to date.")
                        .foregroundStyle(BrandTheme.muted)

                    HStack(spacing: 12) {
                        Button("Add expense") {
                            viewModel.presentAddExpense()
                        }
                        .buttonStyle(PrimaryCTAStyle())

                        Button("Budget wizard") {
                            viewModel.presentBudgetWizard()
                        }
                        .buttonStyle(SecondaryCTAStyle())
                    }
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                .listRowBackground(Color.clear)
            }

            Section("Recent ledger") {
                if expenseRecords.isEmpty {
                    Text("Your local ledger is empty. Add the first expense to seed this center.")
                        .foregroundStyle(BrandTheme.muted)
                } else {
                    ForEach(expenseRecords) { expense in
                        expenseRow(expense)
                    }
                }
            }

            Section("Import and scan") {
                NavigationLink("CSV Import") {
                    FinanceCsvImportToolView(viewModel: viewModel)
                }

                NavigationLink("Scan Receipts") {
                    FinanceReceiptScanToolView(viewModel: viewModel)
                }
            }

            Section("Finance tools") {
                NavigationLink {
                    FinanceAccountsToolView(viewModel: viewModel)
                } label: {
                    FinanceToolRowLabel(
                        title: "Accounts",
                        summary: "Add cash, cards, and manual balances for a fuller local snapshot.",
                        systemImage: "wallet.pass.fill"
                    )
                }

                NavigationLink {
                    FinanceBillsToolView(viewModel: viewModel)
                } label: {
                    FinanceToolRowLabel(
                        title: "Bills",
                        summary: "Track recurring payments and mark them paid into the ledger.",
                        systemImage: "calendar.badge.clock"
                    )
                }

                NavigationLink {
                    FinanceRulesToolView(viewModel: viewModel)
                } label: {
                    FinanceToolRowLabel(
                        title: "Rules",
                        summary: "Save merchant keywords to auto-categorize imported expenses.",
                        systemImage: "slider.horizontal.3"
                    )
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(BrandTheme.canvas)
        .navigationTitle("Expenses")
        .navigationBarTitleDisplayMode(.large)
        .task {
            if viewModel.dashboardState == nil {
                await viewModel.refreshDashboard()
            }
        }
    }

    private func expenseRow(_ expense: ExpenseRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: expense.category.symbolName)
                .frame(width: 34, height: 34)
                .foregroundStyle(BrandTheme.primary)
                .background(BrandTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.merchant)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text("\(expense.category.rawValue) · \(expense.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }
            }

            Spacer()

            Text(expense.amount, format: .currency(code: "USD"))
                .font(.headline)
                .foregroundStyle(BrandTheme.ink)
        }
        .padding(.vertical, 4)
    }
}
