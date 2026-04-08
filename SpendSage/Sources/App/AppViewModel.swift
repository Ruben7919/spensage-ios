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
        case preferences
        case notifications
        case advanced = "advanced"
        case support
        case help
        case legal
        case brand = "brand"
        case budget = "budget"
        case trophies
    }

    enum PresentedSheet: String, Identifiable {
        case addExpense
        case budgetWizard

        var id: String { rawValue }
    }

    @Published var session: SessionState
    @Published var hasCompletedOnboarding: Bool
    @Published var selectedTab: AppTab
    @Published var scanFlowID = UUID()
    @Published var dashboardState: FinanceDashboardState?
    @Published var ledger: LocalFinanceLedger?
    @Published var growthSnapshot: DashboardGrowthSnapshot?
    @Published var activeSheet: PresentedSheet?
    @Published var notice: String?
    @Published var debugRoute: DebugRoute?
    @Published var activeCelebration: GrowthCelebration?
    @Published var reviewPromptToken: UUID?
    @Published var pendingProfileSetup: PendingProfileSetup?
    @Published var isRestoringRememberedSession = false
    @Published var requiresSessionUnlock = false
    @Published var biometricKind = BiometricUnlockService.availableBiometric()
    @Published var sessionUnlockError: String?
    @Published var backendStatus: BackendRuntimeStatus?
    @Published var backendStatusError: String?
    @Published var pushRegistrationStatus = PushRegistrationStatus()
    @Published var storeBillingState = StoreBillingState()
    @Published var calendarSyncStatus = BillCalendarSyncStatus()
    @Published var expenseLocationStatus = ExpenseLocationAuthorizationStatus.notDetermined
    @Published var spaces: [SpaceSummary] = []
    @Published var currentSpaceID: String?
    @Published var familySharingModel: FamilySharingModel?
    @Published var myInvites: [SpaceInvite] = []
    @Published var spaceInvites: [SpaceInvite] = []
    @Published var spaceMembers: [SpaceMember] = []
    @Published var currentSpaceMember: SpaceMember?
    @Published var lastCreatedInvite: CreateInviteResult?
    @Published var sharingStatusError: String?
    @Published var isRefreshingSharing = false

    private let authService: AuthServicing
    private let financeStore: FinanceDashboardStoring
    private let backendService: BackendServicing
    private let pushRegistrationService: PushRegistrationServicing
    private let storeBillingService: StoreBillingServicing
    private let billCalendarSyncService: BillCalendarSyncServicing
    private let expenseLocationService: ExpenseLocationServicing
    private let selectedSpaceStore: SelectedSpaceStore
    private let pendingInviteStore: PendingInviteStore
    private let telemetryService: TelemetryServicing
    private let onboardingKey = "native_onboarding_completed"
    private let premiumStatusDefaultsKey = "native.premium.status"
    private let premiumPlanDefaultsKey = "native.premium.plan"
    private var queuedCelebrations: [GrowthCelebration] = []
    private var shouldPromptForReviewAfterCelebrations = false
    private var didBootstrapRememberedSession = false
    private var permissionBootstrapKey: String?
    private var isBootstrappingPermissions = false
    private var backgroundedAt: Date?
    private var backendStatusUpdatedAt: Date?
    private var storeBillingUpdatedAt: Date?

    init(
        authService: AuthServicing = DefaultAuthService.make(),
        financeStore: FinanceDashboardStoring? = nil,
        backendService: BackendServicing = DefaultBackendService.make(),
        pushRegistrationService: PushRegistrationServicing = DefaultPushRegistrationService.make(),
        storeBillingService: StoreBillingServicing = DefaultStoreBillingService.make(),
        billCalendarSyncService: BillCalendarSyncServicing = DefaultBillCalendarSyncService.make(),
        expenseLocationService: ExpenseLocationServicing = DefaultExpenseLocationService.make(),
        selectedSpaceStore: SelectedSpaceStore = SelectedSpaceStore(),
        pendingInviteStore: PendingInviteStore = PendingInviteStore(),
        telemetryService: TelemetryServicing? = nil
    ) {
        self.authService = authService
        self.backendService = backendService
        self.pushRegistrationService = pushRegistrationService
        self.storeBillingService = storeBillingService
        self.billCalendarSyncService = billCalendarSyncService
        self.expenseLocationService = expenseLocationService
        self.selectedSpaceStore = selectedSpaceStore
        self.pendingInviteStore = pendingInviteStore
        self.telemetryService = telemetryService ?? DefaultTelemetryService.make(
            authService: authService,
            configuration: backendService.configuration
        )
        self.financeStore = financeStore ?? SyncedFinanceStore(
            authService: authService,
            backendConfiguration: backendService.configuration
        )
        self.session = .signedOut
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        self.selectedTab = .dashboard
        applyDebugLaunchOverrides()
        self.telemetryService.start()
    }

    var authConfiguration: AuthConfiguration {
        authService.configuration
    }

    var backendConfiguration: BackendConfiguration? {
        backendService.configuration
    }

    var cloudEntitlements: BackendEntitlements? {
        backendStatus?.entitlements
    }

    var storeEntitlements: StoreEntitlementSnapshot {
        storeBillingState.entitlements
    }

    var subscriptionManagementURL: URL? {
        storeBillingService.managementURL()
    }

    var currentSpace: SpaceSummary? {
        guard let currentSpaceID else { return nil }
        return spaces.first(where: { $0.spaceId == currentSpaceID })
    }

    var currentSpaceRole: SpaceRole? {
        familySharingModel?.permissions.callerRole ?? currentSpace?.role
    }

    var canManageCurrentSpaceMembers: Bool {
        familySharingModel?.permissions.canManageMembers ?? false
    }

    var pendingInviteCode: String? {
        pendingInviteStore.currentCode()
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
        Task { await telemetryService.track("onboarding_completed", properties: [:]) }
    }

    func signIn(email: String, password: String) async throws {
        session = try await authService.signIn(email: email, password: password)
        currentSpaceID = selectedSpaceStore.currentSpaceID(for: session)
        pendingProfileSetup = nil
        notice = nil
        requiresSessionUnlock = false
        sessionUnlockError = nil
        await refreshDashboard()
        await refreshBackendStatus(force: true)
        await refreshSharingState(force: true)
        await refreshStoreBilling(force: true)
        await telemetryService.track("auth_signed_in", properties: ["provider": "email"])
        await telemetryService.flushIfPossible(session: session)
    }

    func createAccount(email: String, password: String) async throws {
        session = try await authService.createAccount(email: email, password: password)
        currentSpaceID = selectedSpaceStore.currentSpaceID(for: session)
        pendingProfileSetup = nil
        notice = nil
        requiresSessionUnlock = false
        sessionUnlockError = nil
        await refreshDashboard()
        await refreshBackendStatus(force: true)
        await refreshSharingState(force: true)
        await refreshStoreBilling(force: true)
        await telemetryService.track("auth_account_created", properties: ["provider": "email"])
        await telemetryService.flushIfPossible(session: session)
    }

    func signInWithSocial(_ provider: SocialProvider) async throws {
        session = try await authService.signInWithSocial(provider)
        currentSpaceID = selectedSpaceStore.currentSpaceID(for: session)
        notice = AppLocalization.localized("Signed in with %@.", arguments: provider.displayName)
        requiresSessionUnlock = false
        sessionUnlockError = nil
        await refreshDashboard()
        await refreshBackendStatus(force: true)
        await refreshSharingState(force: true)
        await refreshStoreBilling(force: true)
        pendingProfileSetup = makePendingProfileSetup(from: authService.consumeProfileSeed(), provider: provider)
        await telemetryService.track("auth_signed_in", properties: ["provider": provider.rawValue.lowercased()])
        await telemetryService.flushIfPossible(session: session)
    }

    func continueAsGuest() async {
        session = await authService.continueAsGuest()
        currentSpaceID = nil
        notice = "Guest mode stays local on this device.".appLocalized
        await refreshDashboard()
        await refreshBackendStatus(force: true)
        await refreshStoreBilling(force: true)
    }

    func signOut() async {
        await unregisterPushNotificationsIfNeeded()
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
            Task { await refreshPushRegistrationState() }
            Task { await refreshStoreBilling() }
            Task { await refreshCalendarSyncState() }
            Task { await refreshExpenseLocationState() }

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
        backendStatus = nil
        backendStatusError = nil
        pushRegistrationStatus = PushRegistrationStatus()
        calendarSyncStatus = BillCalendarSyncStatus()
        expenseLocationStatus = .notDetermined
        spaces = []
        currentSpaceID = nil
        familySharingModel = nil
        myInvites = []
        spaceInvites = []
        spaceMembers = []
        currentSpaceMember = nil
        lastCreatedInvite = nil
        sharingStatusError = nil
        isRefreshingSharing = false
        activeSheet = nil
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
        permissionBootstrapKey = nil
        isBootstrappingPermissions = false
        backgroundedAt = nil
        backendStatusUpdatedAt = nil
        storeBillingUpdatedAt = nil
        storeBillingState = StoreBillingState()
        PushRegistrationPersistence.clearUploadMarker()
    }

    func startScanFlow() {
        scanFlowID = UUID()
        selectedTab = .scan
    }

    func startManualExpenseFlow() {
        selectedTab = .expenses
        activeSheet = .addExpense
    }

    func refreshDashboard() async {
        let previousGrowthSnapshot = growthSnapshot
        let ledger = await financeStore.loadLedger(for: session, spaceID: currentSpaceID)
        let state = ledger.dashboardState()
        self.ledger = ledger
        dashboardState = state

        let newGrowthSnapshot = makeGrowthSnapshot(state: state, ledger: ledger)
        growthSnapshot = newGrowthSnapshot
        handleGrowthUpdates(previous: previousGrowthSnapshot, current: newGrowthSnapshot)
        if backendStatus == nil {
            await refreshBackendStatus()
        }
        if storeBillingState.products.isEmpty {
            await refreshStoreBilling()
        }
        await refreshCalendarSyncState()
        await refreshExpenseLocationState()
        await telemetryService.flushIfPossible(session: session)
    }

    func storeProducts(for planID: String) -> [StoreCatalogProduct] {
        guard let planKey = StorePlanKey(rawValue: planID) else { return [] }
        return storeBillingState.products
            .filter { $0.planKey == planKey }
            .sorted { lhs, rhs in
                lhs.sortOrder < rhs.sortOrder
            }
    }

    func storeHasActiveProduct(_ productID: String) -> Bool {
        storeBillingState.entitlements.activeProductIDs.contains(productID)
    }

    func refreshBackendStatus(force: Bool = false) async {
        guard backendService.configuration != nil else {
            backendStatus = nil
            backendStatusError = nil
            backendStatusUpdatedAt = nil
            await refreshPushRegistrationState()
            return
        }

        if !force, let backendStatusUpdatedAt, Date().timeIntervalSince(backendStatusUpdatedAt) < 60 {
            return
        }

        do {
            let idToken = session.isAuthenticated ? await authService.currentIDToken() : nil
            backendStatus = try await backendService.fetchStatus(idToken: idToken)
            backendStatusError = nil
            backendStatusUpdatedAt = .now
        } catch {
            backendStatusError = error.localizedDescription
        }

        await refreshPushRegistrationState()
        await syncCachedPushRegistrationIfNeeded()
    }

    func refreshStoreBilling(force: Bool = false) async {
        if !force, let storeBillingUpdatedAt, Date().timeIntervalSince(storeBillingUpdatedAt) < 60 {
            return
        }

        storeBillingState.isLoading = true
        storeBillingState.lastError = nil

        var loadedProducts = storeBillingState.products
        var loadedEntitlements = storeBillingState.entitlements
        var errors: [String] = []

        do {
            loadedProducts = try await storeBillingService.loadCatalog()
        } catch {
            errors.append(error.localizedDescription)
        }

        do {
            loadedEntitlements = try await storeBillingService.refreshEntitlements()
        } catch {
            errors.append(error.localizedDescription)
        }

        storeBillingState.products = loadedProducts
        storeBillingState.entitlements = loadedEntitlements
        storeBillingState.lastUpdatedAt = .now
        storeBillingState.isLoading = false
        storeBillingUpdatedAt = .now
        syncPersistedPremiumState(with: loadedEntitlements)

        if !errors.isEmpty {
            storeBillingState.lastError = errors.joined(separator: "\n")
        }
    }

    func purchaseStoreProduct(_ productID: String) async {
        guard session.isAuthenticated else {
            let message = "Inicia sesión antes de comprar o restaurar en App Store."
            notice = message
            storeBillingState.lastError = message
            return
        }

        storeBillingState.activePurchaseProductID = productID
        storeBillingState.lastError = nil

        do {
            let entitlements = try await storeBillingService.purchase(productID: productID)
            applyStoreEntitlements(entitlements)
            notice = purchaseSuccessMessage(for: productID, entitlements: entitlements)
            await refreshBackendStatus(force: true)
            await refreshSharingState(force: true)
            await telemetryService.track("billing_purchase_succeeded", properties: ["productId": productID])
        } catch let error as StoreBillingError {
            handleStoreBillingError(error, productID: productID)
        } catch {
            storeBillingState.lastError = error.localizedDescription
            notice = error.localizedDescription
        }

        storeBillingState.activePurchaseProductID = nil
    }

    func restoreStorePurchases() async {
        guard session.isAuthenticated else {
            let message = "Inicia sesión antes de restaurar compras en este iPhone."
            notice = message
            storeBillingState.lastError = message
            return
        }

        storeBillingState.isRestoring = true
        storeBillingState.lastError = nil

        do {
            let entitlements = try await storeBillingService.restorePurchases()
            applyStoreEntitlements(entitlements)
            notice = entitlements.activePlanKey == nil && !entitlements.hasRemoveAds
                ? "No se encontraron compras activas para restaurar en este Apple ID."
                : "Compras restauradas desde App Store."
            await refreshBackendStatus(force: true)
            await refreshSharingState(force: true)
            await telemetryService.track(
                "billing_restore_completed",
                properties: ["activePlan": entitlements.activePlanKey?.rawValue ?? StorePlanKey.freeLocal.rawValue]
            )
        } catch let error as StoreBillingError {
            storeBillingState.lastError = error.localizedDescription
            notice = error.localizedDescription
        } catch {
            storeBillingState.lastError = error.localizedDescription
            notice = error.localizedDescription
        }

        storeBillingState.isRestoring = false
    }

    func refreshPushRegistrationState(
        lastError: String? = nil,
        isRegistering: Bool? = nil,
        isSendingTestPush: Bool? = nil
    ) async {
        let authorization = await pushRegistrationService.authorizationStatus()
        let cachedToken = pushRegistrationService.cachedToken()
        let marker = PushRegistrationPersistence.uploadMarker()

        pushRegistrationStatus = PushRegistrationStatus(
            backendEnabled: backendStatus?.capabilities.features.pushRegistration ?? false,
            authorization: authorization,
            cachedTokenSuffix: cachedToken.flatMap(Self.pushTokenSuffix(for:)),
            lastUploadedAt: marker?.uploadedAt,
            lastUploadedEnvironment: marker?.environmentName,
            lastUploadedEmail: marker?.email,
            lastError: lastError,
            isRegistering: isRegistering ?? false,
            isSendingTestPush: isSendingTestPush ?? false
        )
    }

    func refreshCalendarSyncState(lastError: String? = nil, isSyncing: Bool? = nil) async {
        let authorization = await billCalendarSyncService.authorizationStatus()
        let marker = BillCalendarSyncPersistence.marker(for: session)
        calendarSyncStatus = BillCalendarSyncStatus(
            authorization: authorization,
            lastSyncedAt: marker?.syncedAt,
            syncedBillCount: marker?.count,
            lastError: lastError,
            isSyncing: isSyncing ?? false
        )
    }

    func refreshExpenseLocationState() async {
        expenseLocationStatus = await expenseLocationService.authorizationStatus()
    }

    func requestExpenseLocationPermission(showNotice: Bool = true) async {
        do {
            try await expenseLocationService.requestAuthorization()
            if showNotice {
                notice = "Ubicación lista para etiquetar gastos cuando tú lo pidas."
            }
            await refreshExpenseLocationState()
        } catch {
            if showNotice {
                notice = error.localizedDescription
            }
            await refreshExpenseLocationState()
        }
    }

    func captureCurrentExpenseLocation() async -> String? {
        do {
            let label = try await expenseLocationService.requestCurrentLocationLabel()
            await refreshExpenseLocationState()
            return label
        } catch {
            notice = error.localizedDescription
            await refreshExpenseLocationState()
            return nil
        }
    }

    func syncBillsToCalendar(showNotice: Bool = true) async {
        guard let ledger else {
            if showNotice {
                notice = "Todavía no hay un libro cargado para sincronizar facturas."
            }
            return
        }

        await refreshCalendarSyncState(isSyncing: true)
        do {
            let syncedCount = try await billCalendarSyncService.syncBills(bills, ledger: ledger, session: session)
            if showNotice {
                notice = AppLocalization.localized("Calendario actualizado con %d recordatorios de facturas.", arguments: syncedCount)
            }
            await refreshCalendarSyncState()
        } catch {
            if showNotice {
                notice = error.localizedDescription
            }
            await refreshCalendarSyncState(lastError: error.localizedDescription)
        }
    }

    func activateInternalTesterPlan(_ planID: InternalTesterPlanID) async {
        guard let financeStore = financeStore as? FinanceCloudDebugControlling else {
            notice = "Este build no tiene override interno de billing habilitado."
            return
        }

        do {
            try await financeStore.activateInternalTesterPlan(planID, for: session)
            notice = AppLocalization.localized("Plan interno activo: %@.", arguments: planID.displayName)
            await refreshBackendStatus(force: true)
            await refreshSharingState(force: true)
            await refreshDashboard()
        } catch {
            notice = error.localizedDescription
        }
    }

    func chooseFreeLocalPlan() {
        syncPersistedPremiumState(with: .empty)
        notice = "Local gratis sigue activo en este dispositivo."
    }

    private func applyStoreEntitlements(_ entitlements: StoreEntitlementSnapshot) {
        storeBillingState.entitlements = entitlements
        storeBillingState.lastUpdatedAt = .now
        storeBillingUpdatedAt = .now
        storeBillingState.lastError = nil
        syncPersistedPremiumState(with: entitlements)
    }

    private func syncPersistedPremiumState(with entitlements: StoreEntitlementSnapshot) {
        let defaults = UserDefaults.standard
        let nextPlan = entitlements.activePlanKey?.rawValue ?? StorePlanKey.freeLocal.rawValue
        let nextStatus = entitlements.activePlanKey == nil ? "free" : "active"
        defaults.set(nextPlan, forKey: premiumPlanDefaultsKey)
        defaults.set(nextStatus, forKey: premiumStatusDefaultsKey)
    }

    private func markPendingPremiumState(for productID: String) {
        let defaults = UserDefaults.standard
        let nextPlan = StoreProductID(rawValue: productID)?.planKey.rawValue ?? StorePlanKey.pro.rawValue
        defaults.set(nextPlan, forKey: premiumPlanDefaultsKey)
        defaults.set("trialing", forKey: premiumStatusDefaultsKey)
    }

    private func handleStoreBillingError(_ error: StoreBillingError, productID: String) {
        if error == .purchasePending {
            markPendingPremiumState(for: productID)
        }
        storeBillingState.lastError = error.localizedDescription
        notice = error.localizedDescription
    }

    private func purchaseSuccessMessage(
        for productID: String,
        entitlements: StoreEntitlementSnapshot
    ) -> String {
        if StoreProductID(rawValue: productID)?.planKey == .removeAds {
            return "Compra completada. SpendSage queda sin anuncios en este Apple ID."
        }

        return AppLocalization.localized(
            "Compra completada. Plan activo en App Store: %@.",
            arguments: entitlements.displayPlanName
        )
    }

    func registerPushNotifications(showNotice: Bool = true) async {
        guard session.isAuthenticated else {
            let message = "Inicia sesión antes de registrar este iPhone para notificaciones push."
            if showNotice {
                notice = message
            }
            await refreshPushRegistrationState(lastError: message)
            return
        }

        guard backendStatus?.capabilities.features.pushRegistration == true else {
            let message = "El backend todavía no tiene APNs/SNS configurado para esta app."
            if showNotice {
                notice = message
            }
            await refreshPushRegistrationState(lastError: message)
            return
        }

        guard let idToken = await authService.currentIDToken(), !idToken.isEmpty else {
            let message = "No se pudo obtener un token válido de tu sesión."
            if showNotice {
                notice = message
            }
            await refreshPushRegistrationState(lastError: message)
            return
        }

        await refreshPushRegistrationState(isRegistering: true)

        do {
            let token = try await pushRegistrationService.requestRemoteNotificationToken()
            let apnsEnvironment = APNSEnvironment.current
            let request = BackendDeviceRegistrationRequest(
                platform: "ios",
                provider: "apns",
                token: token,
                apnsEnvironment: apnsEnvironment
            )
            _ = try await backendService.registerDevice(idToken: idToken, request: request)

            if
                let email = session.emailAddress,
                let environmentName = backendConfiguration?.environmentName
            {
                PushRegistrationPersistence.recordUpload(
                    token: token,
                    email: email,
                    environmentName: environmentName,
                    apnsEnvironment: apnsEnvironment
                )
            }

            if showNotice {
                notice = "Push activado y vinculado a tu cuenta en este iPhone."
            }
            await refreshPushRegistrationState()
            await telemetryService.track(
                "push_registered",
                properties: [
                    "provider": "apns",
                    "apns_environment": apnsEnvironment.rawValue
                ]
            )
            await telemetryService.flushIfPossible(session: session)
        } catch {
            let message = error.localizedDescription
            if showNotice {
                notice = message
            }
            await refreshPushRegistrationState(lastError: message)
        }
    }

    func sendTestPushNotification() async {
        guard session.isAuthenticated else {
            let message = "Inicia sesión antes de enviar un push de prueba."
            notice = message
            await refreshPushRegistrationState(lastError: message)
            return
        }

        guard backendStatus?.capabilities.features.pushRegistration == true else {
            let message = "El backend todavía no permite probar push para esta app."
            notice = message
            await refreshPushRegistrationState(lastError: message)
            return
        }

        guard let token = pushRegistrationService.cachedToken(), !token.isEmpty else {
            let message = "Primero registra este iPhone para push y vuelve a intentar."
            notice = message
            await refreshPushRegistrationState(lastError: message)
            return
        }

        guard let idToken = await authService.currentIDToken(), !idToken.isEmpty else {
            let message = "No se pudo obtener un token válido de tu sesión."
            notice = message
            await refreshPushRegistrationState(lastError: message)
            return
        }

        await refreshPushRegistrationState(isSendingTestPush: true)

        do {
            let apnsEnvironment = APNSEnvironment.current
            let request = BackendDeviceTestPushRequest(
                platform: "ios",
                provider: "apns",
                token: token,
                apnsEnvironment: apnsEnvironment,
                title: "SpendSage test",
                body: "Si ves este aviso, APNs y SNS quedaron enlazados para este iPhone."
            )
            _ = try await backendService.sendTestPush(idToken: idToken, request: request)
            notice = "Push de prueba enviado. Si este iPhone está activo y autorizado, debería llegar en pocos segundos."
            await refreshPushRegistrationState()
        } catch {
            let message = error.localizedDescription
            notice = message
            await refreshPushRegistrationState(lastError: message)
        }
    }

    private func syncCachedPushRegistrationIfNeeded() async {
        let apnsEnvironment = APNSEnvironment.current
        guard
            session.isAuthenticated,
            backendStatus?.capabilities.features.pushRegistration == true,
            let email = session.emailAddress,
            let environmentName = backendConfiguration?.environmentName,
            let idToken = await authService.currentIDToken(),
            !idToken.isEmpty,
            let token = pushRegistrationService.cachedToken(),
            !token.isEmpty,
            PushRegistrationPersistence.shouldUpload(
                token: token,
                email: email,
                environmentName: environmentName,
                apnsEnvironment: apnsEnvironment
            )
        else {
            return
        }

        do {
            let request = BackendDeviceRegistrationRequest(
                platform: "ios",
                provider: "apns",
                token: token,
                apnsEnvironment: apnsEnvironment
            )
            _ = try await backendService.registerDevice(idToken: idToken, request: request)
            PushRegistrationPersistence.recordUpload(
                token: token,
                email: email,
                environmentName: environmentName,
                apnsEnvironment: apnsEnvironment
            )
            await refreshPushRegistrationState()
        } catch {
            await refreshPushRegistrationState(lastError: error.localizedDescription)
        }
    }

    private func unregisterPushNotificationsIfNeeded() async {
        defer { PushRegistrationPersistence.clearUploadMarker() }

        guard
            session.isAuthenticated,
            backendStatus?.capabilities.features.pushRegistration == true,
            let token = pushRegistrationService.cachedToken(),
            !token.isEmpty,
            let idToken = await authService.currentIDToken(),
            !idToken.isEmpty
        else {
            return
        }

        let request = BackendDeviceRegistrationRequest(
            platform: "ios",
            provider: "apns",
            token: token,
            apnsEnvironment: APNSEnvironment.current
        )
        _ = try? await backendService.unregisterDevice(idToken: idToken, request: request)
    }

    func refreshSharingState(force: Bool = false) async {
        guard session.isAuthenticated, backendService.configuration != nil else {
            spaces = []
            currentSpaceID = nil
            familySharingModel = nil
            myInvites = []
            spaceInvites = []
            spaceMembers = []
            currentSpaceMember = nil
            lastCreatedInvite = nil
            sharingStatusError = nil
            isRefreshingSharing = false
            return
        }

        if !force, isRefreshingSharing {
            return
        }

        guard let idToken = await authService.currentIDToken(), !idToken.isEmpty else {
            return
        }

        isRefreshingSharing = true
        defer { isRefreshingSharing = false }

        do {
            let availableSpaces = try await backendService.listSpaces(idToken: idToken)
            spaces = availableSpaces
            myInvites = try await backendService.listInvites(idToken: idToken)

            let persistedSpaceID = selectedSpaceStore.currentSpaceID(for: session)
            let preferredSpaceID = currentSpaceID ?? persistedSpaceID ?? availableSpaces.first?.spaceId
            let resolvedSpaceID = availableSpaces.contains(where: { $0.spaceId == preferredSpaceID })
                ? preferredSpaceID
                : availableSpaces.first?.spaceId

            currentSpaceID = resolvedSpaceID
            selectedSpaceStore.setCurrentSpaceID(resolvedSpaceID, for: session)

            guard let resolvedSpaceID else {
                familySharingModel = nil
                spaceInvites = []
                spaceMembers = []
                currentSpaceMember = nil
                sharingStatusError = nil
                return
            }

            let resolvedFamilyModel = try await backendService.getFamilySharingModel(idToken: idToken, spaceID: resolvedSpaceID)
            familySharingModel = resolvedFamilyModel
            currentSpaceMember = try? await backendService.getSpaceMember(
                idToken: idToken,
                spaceID: resolvedSpaceID,
                memberUserID: "me"
            )

            if resolvedFamilyModel.permissions.canManageMembers {
                spaceMembers = try await backendService.listSpaceMembers(idToken: idToken, spaceID: resolvedSpaceID)
                spaceInvites = try await backendService.listSpaceInvites(idToken: idToken, spaceID: resolvedSpaceID)
            } else {
                spaceMembers = currentSpaceMember.map { [$0] } ?? []
                spaceInvites = []
            }

            sharingStatusError = nil
        } catch {
            sharingStatusError = error.localizedDescription
        }
    }

    func selectSpace(_ spaceID: String) async {
        guard spaces.contains(where: { $0.spaceId == spaceID }) else { return }
        currentSpaceID = spaceID
        selectedSpaceStore.setCurrentSpaceID(spaceID, for: session)
        await telemetryService.track("sharing_space_selected", properties: ["spaceId": spaceID])
        await refreshSharingState(force: true)
        await refreshDashboard()
    }

    func createFamilyInvite(recipientEmail: String, role: SpaceRole, expiresInDays: Int?) async {
        guard session.isAuthenticated else {
            notice = "Inicia sesión antes de invitar a alguien."
            return
        }
        guard let spaceID = currentSpaceID else {
            notice = "No hay un espacio seleccionado para invitar miembros."
            return
        }
        guard let idToken = await authService.currentIDToken(), !idToken.isEmpty else {
            notice = "No se pudo validar tu sesión cloud."
            return
        }

        do {
            let result = try await backendService.createInvite(
                idToken: idToken,
                input: CreateInviteInput(
                    spaceId: spaceID,
                    recipientEmail: recipientEmail,
                    role: role,
                    expiresInDays: expiresInDays
                )
            )
            lastCreatedInvite = result
            notice = "Invitación creada. Comparte el deep link o el correo del invitado."
            await telemetryService.track("sharing_invite_created", properties: [
                "spaceId": spaceID,
                "role": role.rawValue
            ])
            await refreshSharingState(force: true)
        } catch {
            notice = error.localizedDescription
        }
    }

    func acceptInvite(code: String) async {
        guard session.isAuthenticated else {
            notice = "Inicia sesión antes de aceptar una invitación."
            return
        }
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            notice = "Falta el código de invitación."
            return
        }
        guard let idToken = await authService.currentIDToken(), !idToken.isEmpty else {
            notice = "No se pudo validar tu sesión cloud."
            return
        }

        do {
            let result = try await backendService.acceptInvite(idToken: idToken, code: trimmed)
            pendingInviteStore.store(code: nil)
            currentSpaceID = result.spaceId
            selectedSpaceStore.setCurrentSpaceID(result.spaceId, for: session)
            notice = "Invitación aceptada. Tu espacio compartido ya está activo."
            await telemetryService.track("sharing_invite_accepted", properties: [
                "spaceId": result.spaceId,
                "role": result.role.rawValue
            ])
            await refreshSharingState(force: true)
            await refreshDashboard()
        } catch {
            notice = error.localizedDescription
        }
    }

    func updateSpaceMember(_ memberUserID: String, role: SpaceRole? = nil, notificationsEnabled: Bool? = nil) async {
        guard let spaceID = currentSpaceID else { return }
        guard let idToken = await authService.currentIDToken(), !idToken.isEmpty else { return }
        do {
            try await backendService.updateSpaceMember(
                idToken: idToken,
                spaceID: spaceID,
                memberUserID: memberUserID,
                patch: UpdateSpaceMemberPatch(role: role, notificationsEnabled: notificationsEnabled)
            )
            await refreshSharingState(force: true)
        } catch {
            notice = error.localizedDescription
        }
    }

    func removeSpaceMember(_ memberUserID: String) async {
        guard let spaceID = currentSpaceID else { return }
        guard let idToken = await authService.currentIDToken(), !idToken.isEmpty else { return }
        do {
            let result = try await backendService.removeSpaceMember(idToken: idToken, spaceID: spaceID, memberUserID: memberUserID)
            if result.left == true {
                currentSpaceID = nil
            }
            await refreshSharingState(force: true)
            await refreshDashboard()
        } catch {
            notice = error.localizedDescription
        }
    }

    func revokeSpaceInvite(_ code: String) async {
        guard let spaceID = currentSpaceID else { return }
        guard let idToken = await authService.currentIDToken(), !idToken.isEmpty else { return }
        do {
            try await backendService.revokeSpaceInvite(idToken: idToken, spaceID: spaceID, code: code)
            await refreshSharingState(force: true)
        } catch {
            notice = error.localizedDescription
        }
    }

    func handleIncomingURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        let host = components.host?.lowercased()
        let path = components.path.lowercased()
        guard host == "invite" || path == "/invite" else { return }
        let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        pendingInviteStore.store(code: code)
        notice = "Invitación detectada. Inicia sesión o entra a Spaces para aceptarla."
    }

    func presentAddExpense() {
        activeSheet = .addExpense
    }

    func dismissAddExpense() {
        if activeSheet == .addExpense {
            activeSheet = nil
        }
    }

    func presentBudgetWizard() {
        activeSheet = .budgetWizard
    }

    func dismissBudgetWizard() {
        if activeSheet == .budgetWizard {
            activeSheet = nil
        }
    }

    func addExpense(_ draft: ExpenseDraft) async {
        guard draft.isValid else {
            notice = "Agrega un comercio y un monto positivo.".appLocalized
            return
        }

        await financeStore.saveExpense(draft, for: session, spaceID: currentSpaceID)
        if draft.category == .subscriptions, draft.recurringPlan != nil {
            notice = draft.recurringPlan?.autoRecord == true
                ? "Suscripción guardada y lista para registrarse sola en cada renovación.".appLocalized
                : "Suscripción guardada con seguimiento recurrente.".appLocalized
        } else if draft.source == .email {
            notice = "Compra importada desde correo y guardada localmente.".appLocalized
        } else {
            notice = "Expense saved locally on this device.".appLocalized
        }
        if activeSheet == .addExpense {
            activeSheet = nil
        }
        await refreshDashboard()
    }

    func saveBudget(monthlyIncome: Decimal, monthlyBudget: Decimal) async {
        guard monthlyIncome > 0, monthlyBudget > 0 else {
            notice = "Income and budget must be positive values.".appLocalized
            return
        }

        await financeStore.saveBudget(monthlyIncome: monthlyIncome, monthlyBudget: monthlyBudget, for: session, spaceID: currentSpaceID)
        notice = "Budget updated locally on this device.".appLocalized
        if activeSheet == .budgetWizard {
            activeSheet = nil
        }
        await refreshDashboard()
    }

    func addAccount(_ draft: AccountDraft) async {
        guard draft.isValid else {
            notice = "Add an account name before saving.".appLocalized
            return
        }

        await financeStore.saveAccount(draft, for: session, spaceID: currentSpaceID)
        notice = "Account saved locally on this device.".appLocalized
        await refreshDashboard()
    }

    func updateAccount(_ accountID: UUID, draft: AccountDraft) async {
        guard draft.isValid else {
            notice = "Add an account name before saving.".appLocalized
            return
        }

        await financeStore.updateAccount(accountID, draft: draft, for: session, spaceID: currentSpaceID)
        notice = "Account updated for this space.".appLocalized
        await refreshDashboard()
    }

    func deleteAccount(_ accountID: UUID) async {
        await financeStore.deleteAccount(accountID, for: session, spaceID: currentSpaceID)
        notice = "Account removed from your local ledger.".appLocalized
        await refreshDashboard()
    }

    func setPrimaryAccount(_ accountID: UUID) async {
        await financeStore.setPrimaryAccount(accountID, for: session, spaceID: currentSpaceID)
        notice = "Primary account updated locally on this device.".appLocalized
        await refreshDashboard()
    }

    func addBill(_ draft: BillDraft) async {
        guard draft.isValid else {
            notice = "Add a bill title, amount, and due day.".appLocalized
            return
        }

        await financeStore.saveBill(draft, for: session, spaceID: currentSpaceID)
        notice = "Recurring bill saved locally on this device.".appLocalized
        await syncBillsToCalendarIfAuthorized()
        await refreshDashboard()
    }

    func updateBill(_ billID: UUID, draft: BillDraft) async {
        guard draft.isValid else {
            notice = "Add a bill title, amount, and due day.".appLocalized
            return
        }

        await financeStore.updateBill(billID, draft: draft, for: session, spaceID: currentSpaceID)
        notice = "Recurring bill updated for this space.".appLocalized
        await syncBillsToCalendarIfAuthorized()
        await refreshDashboard()
    }

    func deleteBill(_ billID: UUID) async {
        await financeStore.deleteBill(billID, for: session, spaceID: currentSpaceID)
        notice = "Recurring bill removed from your local ledger.".appLocalized
        await syncBillsToCalendarIfAuthorized()
        await refreshDashboard()
    }

    func toggleBillAutopay(_ billID: UUID) async {
        await financeStore.toggleBillAutopay(billID, for: session, spaceID: currentSpaceID)
        notice = "Bill autopay updated locally on this device.".appLocalized
        await syncBillsToCalendarIfAuthorized()
        await refreshDashboard()
    }

    func addRule(_ draft: RuleDraft) async {
        guard draft.isValid else {
            notice = "Agrega una palabra clave del comercio antes de guardar una regla.".appLocalized
            return
        }

        await financeStore.saveRule(draft, for: session, spaceID: currentSpaceID)
        notice = "Rule saved locally on this device.".appLocalized
        await refreshDashboard()
    }

    func updateRule(_ ruleID: UUID, draft: RuleDraft) async {
        guard draft.isValid else {
            notice = "Agrega una palabra clave del comercio antes de guardar una regla.".appLocalized
            return
        }

        await financeStore.updateRule(ruleID, draft: draft, for: session, spaceID: currentSpaceID)
        notice = "Rule updated for this space.".appLocalized
        await refreshDashboard()
    }

    func deleteRule(_ ruleID: UUID) async {
        await financeStore.deleteRule(ruleID, for: session, spaceID: currentSpaceID)
        notice = "Rule removed from your local ledger.".appLocalized
        await refreshDashboard()
    }

    func toggleRuleEnabled(_ ruleID: UUID) async {
        await financeStore.toggleRuleEnabled(ruleID, for: session, spaceID: currentSpaceID)
        notice = "Rule activity updated locally on this device.".appLocalized
        await refreshDashboard()
    }

    func payBill(_ billID: UUID) async {
        await financeStore.markBillPaid(billID, for: session, spaceID: currentSpaceID)
        notice = "Bill payment saved to your local ledger.".appLocalized
        await syncBillsToCalendarIfAuthorized()
        await refreshDashboard()
    }

    func importExpenses(_ drafts: [ExpenseDraft]) async {
        guard !drafts.isEmpty else {
            notice = "No hay gastos listos para importar.".appLocalized
            return
        }

        await financeStore.importExpenses(drafts, for: session, spaceID: currentSpaceID)
        notice = AppLocalization.localized("%d expenses imported into your local ledger.", arguments: drafts.count)
        await refreshDashboard()
    }

    func saveProfile(_ profile: ProfileRecord) async {
        await financeStore.saveProfile(profile, for: session, spaceID: currentSpaceID)
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

    func bootstrapEssentialPermissionsIfNeeded(force: Bool = false) async {
        guard case .app = screen, session.isAuthenticated else { return }
        guard !isBootstrappingPermissions else { return }

        if backendService.configuration != nil, backendStatus == nil {
            await refreshBackendStatus(force: true)
        }

        await refreshPushRegistrationState()
        await refreshCalendarSyncState()
        await refreshExpenseLocationState()

        let pushEnabled = pushRegistrationStatus.backendEnabled
        let bootstrapKey = "\(session.storageNamespace)-\(pushEnabled ? "push-on" : "push-off")"
        if !force, permissionBootstrapKey == bootstrapKey {
            return
        }

        isBootstrappingPermissions = true
        defer {
            isBootstrappingPermissions = false
            permissionBootstrapKey = bootstrapKey
        }

        if pushEnabled, pushRegistrationStatus.authorization == .notDetermined {
            await registerPushNotifications(showNotice: false)
        }

        switch calendarSyncStatus.authorization {
        case .notDetermined:
            await requestCalendarAccessIfNeeded(showNotice: false)
        case .granted:
            await syncBillsToCalendarIfAuthorized(showNotice: false)
        case .denied, .restricted:
            break
        }

        if expenseLocationStatus == .notDetermined {
            await requestExpenseLocationPermission(showNotice: false)
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

    private func requestCalendarAccessIfNeeded(showNotice: Bool) async {
        let authorization = await billCalendarSyncService.authorizationStatus()
        switch authorization {
        case .granted:
            await syncBillsToCalendarIfAuthorized(showNotice: showNotice)
        case .notDetermined:
            do {
                try await billCalendarSyncService.requestAccessIfNeeded()
                if showNotice {
                    notice = "Calendario listo para recordatorios de facturas."
                }
                await refreshCalendarSyncState()
                await syncBillsToCalendarIfAuthorized(showNotice: showNotice)
            } catch {
                if showNotice {
                    notice = error.localizedDescription
                }
                await refreshCalendarSyncState(lastError: error.localizedDescription)
            }
        case .denied, .restricted:
            await refreshCalendarSyncState()
        }
    }

    private func syncBillsToCalendarIfAuthorized(showNotice: Bool = false) async {
        guard ledger != nil else { return }
        let authorization = await billCalendarSyncService.authorizationStatus()
        guard authorization == .granted else {
            await refreshCalendarSyncState()
            return
        }
        await syncBillsToCalendar(showNotice: showNotice)
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
        currentSpaceID = selectedSpaceStore.currentSpaceID(for: restoredSession)
        notice = nil
        requiresSessionUnlock = false
        sessionUnlockError = nil
        await refreshDashboard()
        await refreshBackendStatus(force: true)
        await refreshSharingState(force: true)
        await refreshStoreBilling(force: true)

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
                activeSheet = .addExpense
            case "budget":
                hasCompletedOnboarding = true
                if !session.isAuthenticated {
                    session = .signedIn(email: "preview@spendsage.ai", provider: "Preview")
                }
                selectedTab = .settings
                activeSheet = .budgetWizard
            default:
                break
            }
        }

        if session.isAuthenticated {
            didBootstrapRememberedSession = true
            currentSpaceID = selectedSpaceStore.currentSpaceID(for: session)
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

    private static func pushTokenSuffix(for token: String) -> String {
        let suffix = token.suffix(8)
        return "…\(suffix)"
    }
}
