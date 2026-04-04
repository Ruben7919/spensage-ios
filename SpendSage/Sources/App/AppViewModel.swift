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
            case .dashboard: return "Dashboard".appLocalized
            case .expenses: return "Expenses".appLocalized
            case .insights: return "Insights".appLocalized
            case .premium: return "Premium".appLocalized
            case .settings: return "Settings".appLocalized
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

    enum DebugRoute: String {
        case accounts
        case bills
        case rules
        case csv = "csv"
        case scan
        case profile
        case advanced = "advanced"
        case support
        case help
        case legal
        case brand = "brand"
        case budget = "budget"
    }

    @Published var session: SessionState
    @Published var hasCompletedOnboarding: Bool
    @Published var selectedTab: AppTab
    @Published var dashboardState: FinanceDashboardState?
    @Published var ledger: LocalFinanceLedger?
    @Published var isPresentingAddExpense = false
    @Published var isPresentingBudgetWizard = false
    @Published var notice: String?
    @Published var debugRoute: DebugRoute?

    private let authService: AuthServicing
    private let financeStore: FinanceDashboardStoring
    private let onboardingKey = "native_onboarding_completed"

    init(
        authService: AuthServicing = DefaultAuthService.make(),
        financeStore: FinanceDashboardStoring = LocalFinanceStore()
    ) {
        self.authService = authService
        self.financeStore = financeStore
        self.session = .signedOut
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        self.selectedTab = .dashboard
        applyDebugLaunchOverrides()
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
        case .guest:
            return .auth
        case .signedIn:
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
        notice = AppLocalization.localized("Signed in with %@.", arguments: provider.displayName)
        await refreshDashboard()
    }

    func continueAsGuest() async {
        session = await authService.continueAsGuest()
        notice = "Guest mode stays local on this device.".appLocalized
        await refreshDashboard()
    }

    func signOut() {
        session = .signedOut
        dashboardState = nil
        ledger = nil
        isPresentingAddExpense = false
        isPresentingBudgetWizard = false
        selectedTab = .dashboard
        debugRoute = nil
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
            notice = "Add a merchant name and a positive amount.".appLocalized
            return
        }

        await financeStore.saveExpense(draft, for: session)
        notice = "Expense saved locally on this device.".appLocalized
        isPresentingAddExpense = false
        await refreshDashboard()
    }

    func saveBudget(monthlyIncome: Decimal, monthlyBudget: Decimal) async {
        guard monthlyIncome > 0, monthlyBudget > 0 else {
            notice = "Income and budget must be positive values.".appLocalized
            return
        }

        await financeStore.saveBudget(monthlyIncome: monthlyIncome, monthlyBudget: monthlyBudget, for: session)
        notice = "Budget updated locally on this device.".appLocalized
        isPresentingBudgetWizard = false
        await refreshDashboard()
    }

    func addAccount(_ draft: AccountDraft) async {
        guard draft.isValid else {
            notice = "Add an account name before saving.".appLocalized
            return
        }

        await financeStore.saveAccount(draft, for: session)
        notice = "Account saved locally on this device.".appLocalized
        await refreshDashboard()
    }

    func deleteAccount(_ accountID: UUID) async {
        await financeStore.deleteAccount(accountID, for: session)
        notice = "Account removed from your local ledger.".appLocalized
        await refreshDashboard()
    }

    func setPrimaryAccount(_ accountID: UUID) async {
        await financeStore.setPrimaryAccount(accountID, for: session)
        notice = "Primary account updated locally on this device.".appLocalized
        await refreshDashboard()
    }

    func addBill(_ draft: BillDraft) async {
        guard draft.isValid else {
            notice = "Add a bill title, amount, and due day.".appLocalized
            return
        }

        await financeStore.saveBill(draft, for: session)
        notice = "Recurring bill saved locally on this device.".appLocalized
        await refreshDashboard()
    }

    func deleteBill(_ billID: UUID) async {
        await financeStore.deleteBill(billID, for: session)
        notice = "Recurring bill removed from your local ledger.".appLocalized
        await refreshDashboard()
    }

    func toggleBillAutopay(_ billID: UUID) async {
        await financeStore.toggleBillAutopay(billID, for: session)
        notice = "Bill autopay updated locally on this device.".appLocalized
        await refreshDashboard()
    }

    func addRule(_ draft: RuleDraft) async {
        guard draft.isValid else {
            notice = "Add a merchant keyword before saving a rule.".appLocalized
            return
        }

        await financeStore.saveRule(draft, for: session)
        notice = "Rule saved locally on this device.".appLocalized
        await refreshDashboard()
    }

    func deleteRule(_ ruleID: UUID) async {
        await financeStore.deleteRule(ruleID, for: session)
        notice = "Rule removed from your local ledger.".appLocalized
        await refreshDashboard()
    }

    func toggleRuleEnabled(_ ruleID: UUID) async {
        await financeStore.toggleRuleEnabled(ruleID, for: session)
        notice = "Rule activity updated locally on this device.".appLocalized
        await refreshDashboard()
    }

    func payBill(_ billID: UUID) async {
        await financeStore.markBillPaid(billID, for: session)
        notice = "Bill payment saved to your local ledger.".appLocalized
        await refreshDashboard()
    }

    func importExpenses(_ drafts: [ExpenseDraft]) async {
        guard !drafts.isEmpty else {
            notice = "There are no expenses ready to import.".appLocalized
            return
        }

        await financeStore.importExpenses(drafts, for: session)
        notice = AppLocalization.localized("%d expenses imported into your local ledger.", arguments: drafts.count)
        await refreshDashboard()
    }

    func saveProfile(_ profile: ProfileRecord) async {
        await financeStore.saveProfile(profile, for: session)
        notice = "Profile preferences saved on this device.".appLocalized
        await refreshDashboard()
    }

    private func applyDebugLaunchOverrides() {
        let environment = ProcessInfo.processInfo.environment

        if let onboarding = environment["SPENDSAGE_DEBUG_ONBOARDING"]?.lowercased() {
            switch onboarding {
            case "complete", "done", "true", "1":
                hasCompletedOnboarding = true
            case "incomplete", "pending", "false", "0":
                hasCompletedOnboarding = false
            default:
                break
            }
        }

        if let sessionOverride = environment["SPENDSAGE_DEBUG_SESSION"]?.lowercased() {
            switch sessionOverride {
            case "signed_out", "signedout", "logout":
                session = .signedOut
            case "guest", "local":
                session = .guest
            case "email":
                session = .signedIn(email: "rubenl97m@gmail.com", provider: "Email")
            case "google":
                session = .signedIn(email: "rubenl97m@gmail.com", provider: SocialProvider.google.rawValue)
            case "apple":
                session = .signedIn(email: "rubenl97m@gmail.com", provider: SocialProvider.apple.rawValue)
            default:
                break
            }
        }

        if let screenOverride = environment["SPENDSAGE_DEBUG_SCREEN"]?.lowercased() {
            switch screenOverride {
            case "onboarding":
                hasCompletedOnboarding = false
                session = .signedOut
            case "auth", "login":
                hasCompletedOnboarding = true
                session = .signedOut
            case "app", "shell":
                hasCompletedOnboarding = true
                if !session.isAuthenticated {
                    session = .signedIn(email: "preview@spendsage.ai", provider: "Preview")
                }
            default:
                break
            }
        }

        if let tabOverride = environment["SPENDSAGE_DEBUG_TAB"]?.lowercased(),
           let tab = AppTab(rawValue: tabOverride) {
            hasCompletedOnboarding = true
            if !session.isAuthenticated {
                session = .signedIn(email: "preview@spendsage.ai", provider: "Preview")
            }
            selectedTab = tab
        }

        if let routeOverride = environment["SPENDSAGE_DEBUG_ROUTE"]?.lowercased(),
           let route = DebugRoute(rawValue: routeOverride) {
            hasCompletedOnboarding = true
            if !session.isAuthenticated {
                session = .signedIn(email: "preview@spendsage.ai", provider: "Preview")
            }
            selectedTab = .settings
            debugRoute = route
        }
    }
}
