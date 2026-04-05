import SwiftUI
import StoreKit

struct AppRootView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.requestReview) private var requestReview
    @State private var showLaunchExperience = true

    private var shouldShowSplash: Bool {
        viewModel.debugRoute == nil
            && ProcessInfo.processInfo.environment["SPENDSAGE_DEBUG_SKIP_SPLASH"] == nil
    }

    private var shouldHoldSplashForQA: Bool {
        ProcessInfo.processInfo.environment["SPENDSAGE_DEBUG_HOLD_SPLASH"] != nil
    }

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

            if showLaunchExperience && shouldShowSplash {
                LaunchExperienceView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
                    .zIndex(10)
            }

            if let celebration = viewModel.activeCelebration {
                GrowthCelebrationOverlay(
                    celebration: celebration,
                    queuedCount: viewModel.queuedCelebrationCount
                ) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        viewModel.dismissCelebration()
                    }
                }
                .zIndex(30)
            }
        }
        .task {
            guard shouldShowSplash else {
                showLaunchExperience = false
                return
            }

            guard !shouldHoldSplashForQA else {
                return
            }

            try? await Task.sleep(nanoseconds: 1_350_000_000)
            withAnimation(.easeInOut(duration: 0.32)) {
                showLaunchExperience = false
            }
        }
        .onChange(of: viewModel.reviewPromptToken) { _, token in
            guard token != nil else { return }
            requestReview()
            viewModel.consumeReviewPrompt()
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
        case .premium:
            PremiumView(viewModel: viewModel)
        case .profile:
            ProfileView(viewModel: viewModel)
        case .advanced:
            AdvancedSettingsView(viewModel: viewModel)
        case .support:
            SupportCenterView(viewModel: viewModel)
        case .help:
            HelpCenterView(viewModel: viewModel)
        case .legal:
            LegalCenterView()
        case .brand:
            BrandGalleryView()
        case .budget:
            BudgetWizardView(viewModel: viewModel)
        }
    }
}
