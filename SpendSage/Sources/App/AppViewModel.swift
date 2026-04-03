import Foundation

@MainActor
final class AppViewModel: ObservableObject {
    enum Screen {
        case onboarding
        case auth
        case app
    }

    enum AppTab: String, CaseIterable, Identifiable {
        case dashboard
        case expenses
        case insights
        case premium
        case settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .expenses: return "Expenses"
            case .insights: return "Insights"
            case .premium: return "Premium"
            case .settings: return "Settings"
            }
        }

        var systemImage: String {
            switch self {
            case .dashboard: return "house.fill"
            case .expenses: return "list.bullet.rectangle.portrait.fill"
            case .insights: return "chart.xyaxis.line"
            case .premium: return "sparkles"
            case .settings: return "gearshape.fill"
            }
        }
    }

    @Published var session: SessionState
    @Published var hasCompletedOnboarding: Bool
    @Published var selectedTab: AppTab
    @Published var dashboardState: FinanceDashboardState?
    @Published var ledger: LocalFinanceLedger?
    @Published var isPresentingAddExpense = false
    @Published var isPresentingBudgetWizard = false
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
        self.selectedTab = .dashboard
    }

    var authConfiguration: AuthConfiguration {
        authService.configuration
    }

    var accounts: [AccountRecord] {
        ledger?.accounts ?? []
    }

    var bills: [BillRecord] {
        ledger?.upcomingBills() ?? []
    }

    var rules: [RuleRecord] {
        ledger?.rules ?? []
    }

    var profile: ProfileRecord {
        ledger?.profile ?? .default
    }

    var screen: Screen {
        if !hasCompletedOnboarding {
            return .onboarding
        }
        switch session {
        case .signedOut:
            return .auth
        case .guest, .signedIn:
            return .app
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
        notice = "Signed in with \(provider.rawValue)."
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
        ledger = nil
        isPresentingAddExpense = false
        isPresentingBudgetWizard = false
        selectedTab = .dashboard
    }

    func refreshDashboard() async {
        let ledger = await financeStore.loadLedger(for: session)
        self.ledger = ledger
        dashboardState = ledger.dashboardState()
    }

    func presentAddExpense() {
        isPresentingAddExpense = true
    }

    func dismissAddExpense() {
        isPresentingAddExpense = false
    }

    func presentBudgetWizard() {
        isPresentingBudgetWizard = true
    }

    func dismissBudgetWizard() {
        isPresentingBudgetWizard = false
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

    func saveBudget(monthlyIncome: Decimal, monthlyBudget: Decimal) async {
        guard monthlyIncome > 0, monthlyBudget > 0 else {
            notice = "Income and budget must be positive values."
            return
        }

        await financeStore.saveBudget(monthlyIncome: monthlyIncome, monthlyBudget: monthlyBudget, for: session)
        notice = "Budget updated locally on this device."
        isPresentingBudgetWizard = false
        await refreshDashboard()
    }

    func addAccount(_ draft: AccountDraft) async {
        guard draft.isValid else {
            notice = "Add an account name before saving."
            return
        }

        await financeStore.saveAccount(draft, for: session)
        notice = "Account saved locally on this device."
        await refreshDashboard()
    }

    func addBill(_ draft: BillDraft) async {
        guard draft.isValid else {
            notice = "Add a bill title, amount, and due day."
            return
        }

        await financeStore.saveBill(draft, for: session)
        notice = "Recurring bill saved locally on this device."
        await refreshDashboard()
    }

    func addRule(_ draft: RuleDraft) async {
        guard draft.isValid else {
            notice = "Add a merchant keyword before saving a rule."
            return
        }

        await financeStore.saveRule(draft, for: session)
        notice = "Rule saved locally on this device."
        await refreshDashboard()
    }

    func payBill(_ billID: UUID) async {
        await financeStore.markBillPaid(billID, for: session)
        notice = "Bill payment saved to your local ledger."
        await refreshDashboard()
    }

    func importExpenses(_ drafts: [ExpenseDraft]) async {
        guard !drafts.isEmpty else {
            notice = "There are no expenses ready to import."
            return
        }

        await financeStore.importExpenses(drafts, for: session)
        notice = "\(drafts.count) expenses imported into your local ledger."
        await refreshDashboard()
    }

    func saveProfile(_ profile: ProfileRecord) async {
        await financeStore.saveProfile(profile, for: session)
        notice = "Profile preferences saved on this device."
        await refreshDashboard()
    }
}
