import SwiftUI

struct AppRootView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [BrandTheme.background, BrandTheme.accent.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if let debugRoute = viewModel.debugRoute {
                NavigationStack {
                    debugRouteView(debugRoute)
                }
            } else {
                switch viewModel.screen {
                case .onboarding:
                    OnboardingView {
                        viewModel.completeOnboarding()
                    }
                case .auth:
                    NavigationStack {
                        AuthView(viewModel: viewModel)
                    }
                case .app:
                    NativeAppShellView(viewModel: viewModel)
                }
            }
        }
    }

    @ViewBuilder
    private func debugRouteView(_ route: AppViewModel.DebugRoute) -> some View {
        switch route {
        case .accounts:
            FinanceAccountsToolView(viewModel: viewModel)
        case .bills:
            FinanceBillsToolView(viewModel: viewModel)
        case .rules:
            FinanceRulesToolView(viewModel: viewModel)
        case .csv:
            FinanceCsvImportToolView(viewModel: viewModel)
        case .scan:
            FinanceReceiptScanToolView(viewModel: viewModel)
        case .profile:
            ProfileView(viewModel: viewModel)
        case .advanced:
            AdvancedSettingsView(viewModel: viewModel)
        case .support:
            SupportCenterView(viewModel: viewModel)
        case .legal:
            LegalCenterView()
        case .brand:
            BrandGalleryView()
        case .budget:
            BudgetWizardView(viewModel: viewModel)
        }
    }
}
