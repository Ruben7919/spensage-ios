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
                NavigationStack {
                    AuthView(viewModel: viewModel)
                }
            case .app:
                NativeAppShellView(viewModel: viewModel)
            }
        }
    }
}
