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
                    Text("This is the native replacement for the hybrid expenses center. Manual entry already persists on-device, and import/scan hooks are mapped as next migration steps.")
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
                    FeatureStubView(
                        title: "CSV Import",
                        summary: "This route mirrors `/app/import-csv` from the hybrid app.",
                        readiness: "Phase 3",
                        bullets: [
                            "Map CSV columns into native ledger records",
                            "Preview row-level validation before import",
                            "Keep parity with backend import contracts"
                        ],
                        systemImage: "tablecells"
                    )
                }

                NavigationLink("Scan Receipts") {
                    FeatureStubView(
                        title: "Scan Receipts",
                        summary: "This route mirrors `/app/scan` and will move to native camera plus Vision/OCR.",
                        readiness: "Phase 4",
                        bullets: [
                            "Camera capture with receipt framing",
                            "Vision OCR extraction and confidence review",
                            "Optional backend enrichment after native parse"
                        ],
                        systemImage: "camera.viewfinder"
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
