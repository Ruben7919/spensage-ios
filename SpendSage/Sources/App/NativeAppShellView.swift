import SwiftUI

struct NativeAppShellView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            navigationShell(for: .dashboard) {
                DashboardView(viewModel: viewModel)
            }

            navigationShell(for: .expenses) {
                ExpensesCenterView(viewModel: viewModel)
            }

            navigationShell(for: .insights) {
                InsightsView(viewModel: viewModel)
            }

            navigationShell(for: .premium) {
                PremiumView(viewModel: viewModel)
            }

            navigationShell(for: .settings) {
                SettingsView(viewModel: viewModel)
            }
        }
        .tint(BrandTheme.primary)
        .sheet(isPresented: Binding(
            get: { viewModel.isPresentingAddExpense },
            set: { viewModel.isPresentingAddExpense = $0 }
        )) {
            AddExpenseView(viewModel: viewModel)
        }
        .sheet(isPresented: Binding(
            get: { viewModel.isPresentingBudgetWizard },
            set: { viewModel.isPresentingBudgetWizard = $0 }
        )) {
            BudgetWizardView(viewModel: viewModel)
        }
        .task {
            if viewModel.dashboardState == nil {
                await viewModel.refreshDashboard()
            }
        }
    }

    private func navigationShell<Content: View>(for tab: AppViewModel.AppTab, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content()
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(BrandTheme.background.opacity(0.92), for: .navigationBar)
        }
        .tabItem {
            Label(tab.title, systemImage: tab.systemImage)
        }
        .tag(tab)
    }
}
