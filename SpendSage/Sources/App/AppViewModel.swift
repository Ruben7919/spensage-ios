import Foundation

@MainActor
final class AppViewModel: ObservableObject {
    enum Screen {
        case onboarding
        case auth
        case dashboard
    }

    @Published var session: SessionState
    @Published var hasCompletedOnboarding: Bool
    @Published var dashboardState: FinanceDashboardState?
    @Published var isPresentingAddExpense = false
    @Published var notice: String?

    private let authService: AuthServicing
    private let financeStore: FinanceDashboardStoring
    private let onboardingKey = "native_onboarding_completed"

    init(
        authService: AuthServicing = PreviewAuthService(),
        financeStore: FinanceDashboardStoring = LocalFinanceStore()
    ) {
        self.authService = authService
        self.financeStore = financeStore
        self.session = .signedOut
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
    }

    var authConfiguration: AuthConfiguration {
        authService.configuration
    }

    var screen: Screen {
        if !hasCompletedOnboarding {
            return .onboarding
        }
        switch session {
        case .signedOut:
            return .auth
        case .guest, .signedIn:
            return .dashboard
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    func signIn(email: String, password: String) async throws {
        session = try await authService.signIn(email: email, password: password)
        notice = nil
        await refreshDashboard()
    }

    func createAccount(email: String, password: String) async throws {
        session = try await authService.createAccount(email: email, password: password)
        notice = nil
        await refreshDashboard()
    }

    func signInWithSocial(_ provider: SocialProvider) async throws {
        session = try await authService.signInWithSocial(provider)
        notice = "\(provider.rawValue) sign-in is using preview wiring in this native track."
        await refreshDashboard()
    }

    func continueAsGuest() async {
        session = await authService.continueAsGuest()
        notice = "Guest mode stays local on this device."
        await refreshDashboard()
    }

    func signOut() {
        session = .signedOut
        dashboardState = nil
        isPresentingAddExpense = false
    }

    func refreshDashboard() async {
        dashboardState = await financeStore.loadDashboardState(for: session)
    }

    func presentAddExpense() {
        isPresentingAddExpense = true
    }

    func dismissAddExpense() {
        isPresentingAddExpense = false
    }

    func addExpense(_ draft: ExpenseDraft) async {
        guard draft.isValid else {
            notice = "Add a merchant name and a positive amount."
            return
        }

        await financeStore.saveExpense(draft, for: session)
        notice = "Expense saved locally on this device."
        isPresentingAddExpense = false
        await refreshDashboard()
    }
}
