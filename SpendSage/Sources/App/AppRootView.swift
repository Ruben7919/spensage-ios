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

            switch viewModel.screen {
            case .onboarding:
                OnboardingView {
                    viewModel.completeOnboarding()
                }
            case .auth:
                AuthView(viewModel: viewModel)
            case .dashboard:
                DashboardView(viewModel: viewModel)
            }
        }
    }
}

