import SwiftUI
import StoreKit

struct AppRootView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase
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
                case .profileSetup:
                    NavigationStack {
                        ProfileCompletionView(viewModel: viewModel)
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

            if viewModel.isRestoringRememberedSession && viewModel.session == .signedOut {
                SessionRestoreLoadingView()
                    .zIndex(35)
            }

            if viewModel.requiresSessionUnlock {
                SessionUnlockView(
                    biometricKind: viewModel.biometricKind,
                    errorMessage: viewModel.sessionUnlockError,
                    isLoading: viewModel.isRestoringRememberedSession
                ) {
                    Task { await viewModel.unlockRememberedSession() }
                } onUseAnotherAccount: {
                    Task { await viewModel.signOut() }
                }
                .zIndex(40)
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
        .task {
            await viewModel.bootstrapRememberedSessionIfNeeded()
        }
        .task {
            await viewModel.refreshPushRegistrationState()
        }
        .task {
            await viewModel.refreshCalendarSyncState()
        }
        .task {
            await viewModel.refreshExpenseLocationState()
        }
        .task {
            await viewModel.refreshStoreBilling()
        }
        .task {
            await viewModel.refreshSharingState()
        }
        .onChange(of: scenePhase) { _, phase in
            viewModel.handleScenePhaseChange(phase)
        }
        .onChange(of: viewModel.reviewPromptToken) { _, token in
            guard token != nil else { return }
            requestReview()
            viewModel.consumeReviewPrompt()
        }
        .onOpenURL { url in
            viewModel.handleIncomingURL(url)
        }
    }

    @ViewBuilder
    private func debugRouteView(_ route: AppViewModel.DebugRoute) -> some View {
        switch route {
        case .dashboard:
            DashboardView(viewModel: viewModel)
        case .expenses:
            ExpensesCenterView(viewModel: viewModel)
        case .insights:
            InsightsView(viewModel: viewModel)
        case .settings:
            SettingsView(viewModel: viewModel)
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
        case .preferences:
            SettingsPreferencesDebugView()
        case .notifications:
            SettingsNotificationsDebugView(viewModel: viewModel)
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
        case .trophies:
            TrophyHistoryView(viewModel: viewModel)
        }
    }
}
