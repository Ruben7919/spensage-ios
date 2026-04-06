import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    enum Screen {
        case onboarding
        case auth
        case profileSetup
        case app
    }

    struct PendingProfileSetup: Equatable {
        var email: String
        var suggestedFullName: String
        var countryCode: String
    }

    enum AppTab: String, CaseIterable, Identifiable {
        case dashboard
        case expenses
        case scan
        case insights
        case settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .dashboard: return "Inicio"
            case .expenses: return "Gastos"
            case .scan: return "Escanear"
            case .insights: return "Análisis"
            case .settings: return "Ajustes"
            }
        }

        var systemImage: String {
            switch self {
            case .dashboard: return "house.fill"
            case .expenses: return "list.bullet.rectangle.portrait.fill"
            case .scan: return "camera.viewfinder"
            case .insights: return "chart.xyaxis.line"
            case .settings: return "gearshape.fill"
            }
        }
    }

    enum DebugRoute: String {
        case dashboard
        case expenses
        case insights
        case settings
        case accounts
        case bills
        case rules
        case csv = "csv"
        case scan
        case premium
        case profile
        case advanced = "advanced"
        case support
        case help
        case legal
        case brand = "brand"
        case budget = "budget"
        case trophies
    }

    @Published var session: SessionState
    @Published var hasCompletedOnboarding: Bool
    @Published var selectedTab: AppTab
    @Published var scanFlowID = UUID()
    @Published var dashboardState: FinanceDashboardState?
    @Published var ledger: LocalFinanceLedger?
    @Published var growthSnapshot: DashboardGrowthSnapshot?
    @Published var isPresentingAddExpense = false
    @Published var isPresentingBudgetWizard = false
    @Published var notice: String?
    @Published var debugRoute: DebugRoute?
    @Published var activeCelebration: GrowthCelebration?
    @Published var reviewPromptToken: UUID?
    @Published var pendingProfileSetup: PendingProfileSetup?
    @Published var isRestoringRememberedSession = false
    @Published var requiresSessionUnlock = false
    @Published var biometricKind = BiometricUnlockService.availableBiometric()
    @Published var sessionUnlockError: String?

    private let authService: AuthServicing
    private let financeStore: FinanceDashboardStoring
    private let onboardingKey = "native_onboarding_completed"
    private var queuedCelebrations: [GrowthCelebration] = []
    private var shouldPromptForReviewAfterCelebrations = false
    private var didBootstrapRememberedSession = false
    private var backgroundedAt: Date?

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
        if pendingProfileSetup != nil {
            return .profileSetup
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
        pendingProfileSetup = nil
        notice = nil
        requiresSessionUnlock = false
        sessionUnlockError = nil
        await refreshDashboard()
    }

    func createAccount(email: String, password: String) async throws {
        session = try await authService.createAccount(email: email, password: password)
        pendingProfileSetup = nil
        notice = nil
        requiresSessionUnlock = false
        sessionUnlockError = nil
        await refreshDashboard()
    }

    func signInWithSocial(_ provider: SocialProvider) async throws {
        session = try await authService.signInWithSocial(provider)
        notice = AppLocalization.localized("Signed in with %@.", arguments: provider.displayName)
        requiresSessionUnlock = false
        sessionUnlockError = nil
        await refreshDashboard()
        pendingProfileSetup = makePendingProfileSetup(from: authService.consumeProfileSeed(), provider: provider)
    }

    func continueAsGuest() async {
        session = await authService.continueAsGuest()
        notice = "Guest mode stays local on this device.".appLocalized
        await refreshDashboard()
    }

    func signOut() {
        authService.forgetRememberedSession()
        resetLocalSessionState()
    }

    func forgetRememberedDevice() {
        authService.forgetRememberedSession()
        requiresSessionUnlock = false
        sessionUnlockError = nil
    }

    func bootstrapRememberedSessionIfNeeded() async {
        guard !didBootstrapRememberedSession else { return }
        didBootstrapRememberedSession = true
        biometricKind = BiometricUnlockService.availableBiometric()

        guard hasCompletedOnboarding, !session.isAuthenticated, authService.hasRememberedSession() else {
            return
        }

        if shouldRequireBiometricUnlock {
            requiresSessionUnlock = true
            await unlockRememberedSession()
        } else {
            await restoreRememberedSession()
        }
    }

    func unlockRememberedSession() async {
        guard authService.hasRememberedSession() else {
            requiresSessionUnlock = false
            return
        }

        sessionUnlockError = nil
        requiresSessionUnlock = shouldRequireBiometricUnlock

        if shouldRequireBiometricUnlock {
            isRestoringRememberedSession = true
            let unlocked = await BiometricUnlockService.authenticate(
                reason: "Desbloquea SpendSage para abrir tu cuenta guardada."
            )
            if !unlocked {
                isRestoringRememberedSession = false
                requiresSessionUnlock = true
                sessionUnlockError = AppLocalization.localized(
                    "Usa %@ o el código del dispositivo para abrir tu cuenta guardada.",
                    arguments: biometricKind.displayName
                )
                return
            }
        }

        await restoreRememberedSession()
    }

    func handleScenePhaseChange(_ phase: ScenePhase) {
        biometricKind = BiometricUnlockService.availableBiometric()

        switch phase {
        case .active:
            if !didBootstrapRememberedSession {
                Task { await bootstrapRememberedSessionIfNeeded() }
                return
            }

            guard
                session.isAuthenticated,
                authService.hasRememberedSession(),
                shouldRequireBiometricUnlock,
                let backgroundedAt
            else {
                self.backgroundedAt = nil
                return
            }

            self.backgroundedAt = nil
            guard Date().timeIntervalSince(backgroundedAt) >= 20 else { return }

            requiresSessionUnlock = true
            Task { await unlockRememberedSession() }

        case .background:
            if session.isAuthenticated {
                backgroundedAt = .now
            }

        case .inactive:
            break
        @unknown default:
            break
        }
    }

    func updateRememberDevicePreference(enabled: Bool) {
        if !enabled {
            authService.forgetRememberedSession()
            requiresSessionUnlock = false
            sessionUnlockError = nil
        }
    }

    func updateBiometricUnlockPreference(enabled: Bool) {
        if !enabled {
            requiresSessionUnlock = false
            sessionUnlockError = nil
        }
    }

    private var shouldRequireBiometricUnlock: Bool {
        AuthSessionPreferences.rememberDeviceEnabled()
            && AuthSessionPreferences.biometricUnlockEnabled()
            && biometricKind != .none
    }

    private func resetLocalSessionState() {
        session = .signedOut
        dashboardState = nil
        ledger = nil
        growthSnapshot = nil
        isPresentingAddExpense = false
        isPresentingBudgetWizard = false
        scanFlowID = UUID()
        selectedTab = .dashboard
        debugRoute = nil
        activeCelebration = nil
        queuedCelebrations.removeAll()
        shouldPromptForReviewAfterCelebrations = false
        reviewPromptToken = nil
        pendingProfileSetup = nil
        requiresSessionUnlock = false
        isRestoringRememberedSession = false
        sessionUnlockError = nil
        backgroundedAt = nil
    }

    func startScanFlow() {
        scanFlowID = UUID()
        selectedTab = .scan
    }

    func startManualExpenseFlow() {
        selectedTab = .expenses
        isPresentingAddExpense = true
    }

    func refreshDashboard() async {
        let previousGrowthSnapshot = growthSnapshot
        let ledger = await financeStore.loadLedger(for: session)
        let state = ledger.dashboardState()
        self.ledger = ledger
        dashboardState = state

        let newGrowthSnapshot = makeGrowthSnapshot(state: state, ledger: ledger)
        growthSnapshot = newGrowthSnapshot
        handleGrowthUpdates(previous: previousGrowthSnapshot, current: newGrowthSnapshot)
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
            notice = "Agrega un comercio y un monto positivo.".appLocalized
            return
        }

        await financeStore.saveExpense(draft, for: session)
        if draft.category == .subscriptions, draft.recurringPlan != nil {
            notice = draft.recurringPlan?.autoRecord == true
                ? "Suscripción guardada y lista para registrarse sola en cada renovación.".appLocalized
                : "Suscripción guardada con seguimiento recurrente.".appLocalized
        } else if draft.source == .email {
            notice = "Compra importada desde correo y guardada localmente.".appLocalized
        } else {
            notice = "Expense saved locally on this device.".appLocalized
        }
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
            notice = "Agrega una palabra clave del comercio antes de guardar una regla.".appLocalized
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
            notice = "No hay gastos listos para importar.".appLocalized
            return
        }

        await financeStore.importExpenses(drafts, for: session)
        notice = AppLocalization.localized("%d expenses imported into your local ledger.", arguments: drafts.count)
        await refreshDashboard()
    }

    func saveProfile(_ profile: ProfileRecord) async {
        await financeStore.saveProfile(profile, for: session)
        if !profile.needsWelcomeProfile(for: session.emailAddress) {
            pendingProfileSetup = nil
        }
        notice = "Profile preferences saved on this device.".appLocalized
        await refreshDashboard()
    }

    func completeWelcomeProfile(fullName: String, countryCode: String) async {
        guard let email = session.emailAddress else { return }

        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            notice = "Escribe tu nombre antes de continuar.".appLocalized
            return
        }

        let currentProfile = profile
        let updatedProfile = ProfileRecord(
            fullName: trimmedName,
            householdName: currentProfile.householdName,
            email: email,
            countryCode: countryCode,
            marketingOptIn: currentProfile.marketingOptIn
        )

        await saveProfile(updatedProfile)
        pendingProfileSetup = nil
        notice = "Perfil listo. Ahora sí, entremos.".appLocalized
    }

    func dismissCelebration() {
        activeCelebration = nil
        presentNextCelebrationIfNeeded()
    }

    func consumeReviewPrompt() {
        reviewPromptToken = nil
        AppReviewPromptPolicy.markPrompted()
    }

    var queuedCelebrationCount: Int {
        queuedCelebrations.count
    }

    private func makeGrowthSnapshot(state: FinanceDashboardState?, ledger: LocalFinanceLedger?) -> DashboardGrowthSnapshot {
        GrowthSnapshotBuilder.build(
            session: session,
            state: state,
            ledger: ledger,
            accounts: accounts,
            bills: bills,
            rules: rules,
            profile: profile
        )
    }

    private func makePendingProfileSetup(from seed: AuthProfileSeed?, provider: SocialProvider) -> PendingProfileSetup? {
        guard session.socialProvider == provider, let sessionEmail = session.emailAddress else {
            return nil
        }

        let currentProfile = profile
        guard currentProfile.needsWelcomeProfile(for: sessionEmail) else {
            return nil
        }

        let suggestedFullName = seed?.preferredFullName
            ?? currentProfile.normalizedFullName
            ?? ""

        return PendingProfileSetup(
            email: seed?.preferredEmail ?? sessionEmail,
            suggestedFullName: suggestedFullName,
            countryCode: currentProfile.countryCode
        )
    }

    private func handleGrowthUpdates(previous: DashboardGrowthSnapshot?, current: DashboardGrowthSnapshot) {
        guard let previous else { return }

        enqueueCelebrations(GrowthCelebrationBuilder.build(previous: previous, current: current))

        guard AppReviewPromptPolicy.shouldPrompt(previous: previous, current: current) else {
            return
        }

        if activeCelebration != nil || !queuedCelebrations.isEmpty {
            shouldPromptForReviewAfterCelebrations = true
        } else {
            reviewPromptToken = UUID()
        }
    }

    private func enqueueCelebrations(_ celebrations: [GrowthCelebration]) {
        guard !celebrations.isEmpty else { return }

        var knownIDs = Set(queuedCelebrations.map(\.id))
        if let activeCelebration {
            knownIDs.insert(activeCelebration.id)
        }

        let filtered = celebrations.filter { knownIDs.insert($0.id).inserted }
        guard !filtered.isEmpty else { return }

        queuedCelebrations.append(contentsOf: filtered)
        presentNextCelebrationIfNeeded()
    }

    private func presentNextCelebrationIfNeeded() {
        guard activeCelebration == nil else { return }

        if let next = queuedCelebrations.first {
            queuedCelebrations.removeFirst()
            activeCelebration = next
            return
        }

        if shouldPromptForReviewAfterCelebrations {
            shouldPromptForReviewAfterCelebrations = false
            reviewPromptToken = UUID()
        }
    }

    private func restoreRememberedSession() async {
        isRestoringRememberedSession = true
        defer { isRestoringRememberedSession = false }

        guard let restoredSession = await authService.restoreRememberedSession() else {
            requiresSessionUnlock = false
            sessionUnlockError = nil
            resetLocalSessionState()
            return
        }

        session = restoredSession
        notice = nil
        requiresSessionUnlock = false
        sessionUnlockError = nil
        await refreshDashboard()

        if let provider = restoredSession.socialProvider {
            pendingProfileSetup = makePendingProfileSetup(from: authService.consumeProfileSeed(), provider: provider)
        } else {
            pendingProfileSetup = nil
        }
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

        if let celebrationOverride = environment["SPENDSAGE_DEBUG_CELEBRATION"]?.lowercased() {
            activeCelebration = debugCelebration(for: celebrationOverride)
        }

        if let modalOverride = environment["SPENDSAGE_DEBUG_MODAL"]?.lowercased() {
            switch modalOverride {
            case "add_expense", "expense":
                hasCompletedOnboarding = true
                if !session.isAuthenticated {
                    session = .signedIn(email: "preview@spendsage.ai", provider: "Preview")
                }
                selectedTab = .expenses
                isPresentingAddExpense = true
            case "budget":
                hasCompletedOnboarding = true
                if !session.isAuthenticated {
                    session = .signedIn(email: "preview@spendsage.ai", provider: "Preview")
                }
                selectedTab = .settings
                isPresentingBudgetWizard = true
            default:
                break
            }
        }

        if session.isAuthenticated {
            didBootstrapRememberedSession = true
        }
    }

    private func debugCelebration(for value: String) -> GrowthCelebration? {
        switch value {
        case "level", "levelup":
            return GrowthCelebration(
                id: "debug-level-6",
                kind: .levelUp,
                title: "Nivel 6",
                message: "Subiste de nivel y tu loop se siente más fuerte.",
                detail: "La app ya tiene suficiente señal para darte recomendaciones más claras y un progreso más visible.",
                badgeAsset: "badge_level_up_v2.png",
                systemImage: "bolt.fill",
                rewardXP: nil,
                reachedLevel: 6,
                shareText: "Subí al nivel 6 en SpendSage."
            )
        case "mission":
            return GrowthCelebration(
                id: "debug-mission-ledger",
                kind: .missionCompleted,
                title: "Cinco gastos registrados",
                message: "Misión completada. 80 XP listos para tu progreso.",
                detail: "Tu libro local ya tiene suficiente movimiento para que el coach lea mejor tus hábitos.",
                badgeAsset: "badge_quest_daily_v2.png",
                systemImage: "checkmark.circle.fill",
                rewardXP: 80,
                reachedLevel: nil,
                shareText: "Completé una misión en SpendSage."
            )
        case "trophy", "badge":
            return GrowthCelebration(
                id: "debug-trophy-rookie",
                kind: .trophyUnlocked,
                title: "Libro novato",
                message: "Desbloqueaste un nuevo badge.",
                detail: "Tu primer logro ya está visible y ahora el loop de ahorro tiene un punto de partida claro.",
                badgeAsset: "badge_savings_v2.png",
                systemImage: "sparkles",
                rewardXP: nil,
                reachedLevel: nil,
                shareText: "Desbloqueé un badge en SpendSage."
            )
        default:
            return nil
        }
    }
}
