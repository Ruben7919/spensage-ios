import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if let state = viewModel.dashboardState {
                    summaryCard(for: state)
                    categoryCard(for: state)
                    recentExpensesCard(for: state)
                } else {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Loading local finance data...")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)
                            Text("Your seeded preview ledger and on-device persistence will appear here.")
                                .foregroundStyle(BrandTheme.muted)
                        }
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .task {
            if viewModel.dashboardState == nil {
                await viewModel.refreshDashboard()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Local finance")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandTheme.ink)

                    switch viewModel.session {
                    case .guest:
                        Text("Guest local mode with on-device persistence.")
                            .foregroundStyle(BrandTheme.muted)
                    case let .signedIn(email, provider):
                        Text(provider.map { "\(email) via \($0)" } ?? email)
                            .foregroundStyle(BrandTheme.muted)
                    case .signedOut:
                        EmptyView()
                    }
                }

                Spacer()

                Button("Sign out") {
                    viewModel.signOut()
                }
                .foregroundStyle(BrandTheme.primary)
            }

            Button("Add expense") {
                viewModel.presentAddExpense()
            }
            .buttonStyle(PrimaryCTAStyle())

            Button("Open budget wizard") {
                viewModel.presentBudgetWizard()
            }
            .buttonStyle(SecondaryCTAStyle())
        }
    }

    private func summaryCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Safe budget this month")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.muted)

                Text(state.budgetSnapshot.remaining, format: .currency(code: "USD"))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandTheme.ink)

                ProgressView(value: state.utilizationRatio)
                    .tint(BrandTheme.primary)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 14) {
                    metric(title: "Spent", value: state.budgetSnapshot.monthlySpent)
                    metric(title: "Budget", value: state.budgetSnapshot.monthlyBudget)
                    metric(title: "Income", value: state.budgetSnapshot.monthlyIncome)
                    metric(title: "Avg expense", value: state.averageExpense)
                }
            }
        }
    }

    private func categoryCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Top categories")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Spacer()
                    Text("\(state.transactionCount) tx")
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }

                if state.categoryBreakdown.isEmpty {
                    Text("Add a local expense to see category trends.")
                        .foregroundStyle(BrandTheme.muted)
                } else {
                    ForEach(state.categoryBreakdown) { category in
                        HStack(spacing: 12) {
                            Image(systemName: category.category.symbolName)
                                .frame(width: 28, height: 28)
                                .foregroundStyle(BrandTheme.primary)
                                .background(BrandTheme.primary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.category.rawValue)
                                    .font(.headline)
                                    .foregroundStyle(BrandTheme.ink)
                                Text("\(category.count) expense\(category.count == 1 ? "" : "s")")
                                    .font(.footnote)
                                    .foregroundStyle(BrandTheme.muted)
                            }

                            Spacer()

                            Text(category.total, format: .currency(code: "USD"))
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)
                        }
                    }
                }
            }
        }
    }

    private func recentExpensesCard(for state: FinanceDashboardState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Recent expenses")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Spacer()
                    if let largestExpense = state.largestExpense {
                        Text("Largest \(largestExpense.amount, format: .currency(code: "USD"))")
                            .font(.footnote)
                            .foregroundStyle(BrandTheme.muted)
                    }
                }

                if state.recentExpenses.isEmpty {
                    Text("Your saved local ledger will show up here.")
                        .foregroundStyle(BrandTheme.muted)
                } else {
                    ForEach(state.recentExpenses) { expense in
                        expenseRow(expense)
                    }
                }
            }
        }
    }

    private func metric(title: String, value: Decimal) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(BrandTheme.muted)
            Text(value, format: .currency(code: "USD"))
                .font(.headline)
                .foregroundStyle(BrandTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func expenseRow(_ expense: ExpenseItem) -> some View {
        let category = ExpenseCategory(rawValue: expense.category) ?? .other

        return HStack(spacing: 12) {
            Image(systemName: category.symbolName)
                .frame(width: 32, height: 32)
                .foregroundStyle(BrandTheme.primary)
                .background(BrandTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text("\(category.rawValue) · \(expense.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
            }

            Spacer()

            Text(expense.amount, format: .currency(code: "USD"))
                .font(.headline)
                .foregroundStyle(BrandTheme.ink)
        }
        .padding(.vertical, 2)
    }
}
