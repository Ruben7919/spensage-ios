import SwiftUI

struct InsightsView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let state = viewModel.dashboardState {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Insights")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(BrandTheme.ink)

                            Text("See where your money is going and adjust your plan when needed.")
                                .foregroundStyle(BrandTheme.muted)

                            HStack(spacing: 12) {
                                currencyTile(title: "Remaining", value: state.budgetSnapshot.remaining, symbol: "banknote.fill")
                                countTile(title: "Days left", value: state.remainingDaysInMonth, symbol: "calendar")
                            }

                            Button("Adjust budget") {
                                viewModel.presentBudgetWizard()
                            }
                            .buttonStyle(PrimaryCTAStyle())
                        }
                    }

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Category mix")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)

                            ForEach(state.categoryBreakdown) { category in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(category.category.rawValue)
                                            .foregroundStyle(BrandTheme.ink)
                                        Spacer()
                                        Text(category.total, format: .currency(code: "USD"))
                                            .foregroundStyle(BrandTheme.ink)
                                    }
                                    ProgressView(value: barValue(for: category, state: state))
                                        .tint(BrandTheme.primary)
                                }
                            }
                        }
                    }

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("More money tools")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)

                            NavigationLink {
                                FinanceBillsToolView(viewModel: viewModel)
                            } label: {
                                FinanceToolRowLabel(
                                    title: "Bills",
                                    summary: "Track recurring bills, due dates, and payment history locally.",
                                    systemImage: "calendar.badge.clock"
                                )
                            }

                            NavigationLink {
                                FinanceAccountsToolView(viewModel: viewModel)
                            } label: {
                                FinanceToolRowLabel(
                                    title: "Accounts",
                                    summary: "See balances across checking, savings, cash, and cards.",
                                    systemImage: "wallet.pass.fill"
                                )
                            }

                            NavigationLink {
                                FinanceRulesToolView(viewModel: viewModel)
                            } label: {
                                FinanceToolRowLabel(
                                    title: "Rules",
                                    summary: "Map merchant keywords to categories for cleaner imports.",
                                    systemImage: "slider.horizontal.3"
                                )
                            }

                            NavigationLink {
                                FinanceCsvImportToolView(viewModel: viewModel)
                            } label: {
                                FinanceToolRowLabel(
                                    title: "CSV Import",
                                    summary: "Paste rows from a spreadsheet and preview them before saving.",
                                    systemImage: "tablecells.fill"
                                )
                            }

                            NavigationLink {
                                FinanceReceiptScanToolView(viewModel: viewModel)
                            } label: {
                                FinanceToolRowLabel(
                                    title: "Receipt Scan",
                                    summary: "Capture a receipt image and finish the expense draft manually.",
                                    systemImage: "camera.viewfinder"
                                )
                            }
                        }
                    }
                } else {
                    SurfaceCard {
                        Text("Loading insights...")
                            .foregroundStyle(BrandTheme.muted)
                    }
                }
            }
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
    }

    private func currencyTile(title: String, value: Decimal, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)
            Text(value, format: .currency(code: "USD"))
                .font(.title3.weight(.bold))
                .foregroundStyle(BrandTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(BrandTheme.surfaceTint)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func countTile(title: String, value: Int, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)
            Text("\(value)")
                .font(.title3.weight(.bold))
                .foregroundStyle(BrandTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(BrandTheme.surfaceTint)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func barValue(for category: CategoryBreakdown, state: FinanceDashboardState) -> Double {
        let total = NSDecimalNumber(decimal: state.budgetSnapshot.monthlySpent).doubleValue
        guard total > 0 else { return 0 }
        return NSDecimalNumber(decimal: category.total).doubleValue / total
    }
}
