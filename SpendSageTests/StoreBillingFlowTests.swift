import Foundation
import Testing
@testable import SpendSage

@MainActor
struct StoreBillingFlowTests {
    @Test
    func refreshStoreBillingPersistsActivePlanFromEntitlements() async {
        resetPremiumDefaults()

        let storeBilling = MockStoreBillingService(
            products: [
                StoreCatalogProduct(
                    id: StoreProductID.proMonthly.rawValue,
                    planKey: .pro,
                    kind: .monthly,
                    displayName: "SpendSage Pro Monthly",
                    displayPrice: "$4.99",
                    shortDescription: "Cloud sync",
                    sortOrder: 10
                )
            ],
            entitlements: StoreEntitlementSnapshot(
                activeProductIDs: [StoreProductID.proMonthly.rawValue],
                activePlanKey: .pro,
                hasRemoveAds: false
            )
        )
        let viewModel = AppViewModel(
            authService: MockStoreAuthService(),
            financeStore: LocalFinanceStore(),
            backendService: MockStoreBackendService(),
            pushRegistrationService: PreviewPushRegistrationService(),
            storeBillingService: storeBilling
        )

        await viewModel.refreshStoreBilling(force: true)

        #expect(viewModel.storeBillingState.products.count == 1)
        #expect(viewModel.storeEntitlements.activePlanKey == .pro)
        #expect(UserDefaults.standard.string(forKey: "native.premium.plan") == "pro")
        #expect(UserDefaults.standard.string(forKey: "native.premium.status") == "active")
    }

    @Test
    func purchaseStoreProductRequiresAuthenticatedSession() async {
        resetPremiumDefaults()

        let storeBilling = MockStoreBillingService(
            products: [],
            entitlements: .empty
        )
        let viewModel = AppViewModel(
            authService: MockStoreAuthService(),
            financeStore: LocalFinanceStore(),
            backendService: MockStoreBackendService(),
            pushRegistrationService: PreviewPushRegistrationService(),
            storeBillingService: storeBilling
        )

        await viewModel.purchaseStoreProduct(StoreProductID.proMonthly.rawValue)

        #expect(storeBilling.purchasedProductIDs.isEmpty)
        #expect(viewModel.notice == "Inicia sesión antes de comprar o restaurar en App Store.")
    }

    @Test
    func restoreStorePurchasesUpdatesFamilyState() async {
        resetPremiumDefaults()

        let restoredEntitlements = StoreEntitlementSnapshot(
            activeProductIDs: [StoreProductID.familyAnnual.rawValue],
            activePlanKey: .family,
            hasRemoveAds: false
        )
        let storeBilling = MockStoreBillingService(
            products: [],
            entitlements: .empty,
            restoredEntitlements: restoredEntitlements
        )
        let auth = MockStoreAuthService(idToken: "id-token")
        let viewModel = AppViewModel(
            authService: auth,
            financeStore: LocalFinanceStore(),
            backendService: MockStoreBackendService(),
            pushRegistrationService: PreviewPushRegistrationService(),
            storeBillingService: storeBilling
        )
        viewModel.session = .signedIn(email: "billing@spendsage.ai", provider: "Apple")

        await viewModel.restoreStorePurchases()

        #expect(viewModel.storeEntitlements.activePlanKey == .family)
        #expect(UserDefaults.standard.string(forKey: "native.premium.plan") == "family")
        #expect(UserDefaults.standard.string(forKey: "native.premium.status") == "active")
    }

    private func resetPremiumDefaults() {
        UserDefaults.standard.removeObject(forKey: "native.premium.plan")
        UserDefaults.standard.removeObject(forKey: "native.premium.status")
    }
}

@MainActor
private final class MockStoreAuthService: AuthServicing {
    let configuration = AuthConfiguration.preview
    let idToken: String?

    init(idToken: String? = nil) {
        self.idToken = idToken
    }

    func signIn(email: String, password: String) async throws -> SessionState {
        .signedIn(email: email, provider: "Email")
    }

    func createAccount(email: String, password: String) async throws -> SessionState {
        .signedIn(email: email, provider: "Email")
    }

    func signInWithSocial(_ provider: SocialProvider) async throws -> SessionState {
        .signedIn(email: "social@spendsage.ai", provider: provider.rawValue)
    }

    func continueAsGuest() async -> SessionState {
        .guest
    }

    func hostedUIRequest(for provider: SocialProvider) -> AuthHostedUIRequest? {
        nil
    }

    func consumeProfileSeed() -> AuthProfileSeed? {
        nil
    }

    func hasRememberedSession() -> Bool {
        false
    }

    func restoreRememberedSession() async -> SessionState? {
        nil
    }

    func currentIDToken() async -> String? {
        idToken
    }

    func forgetRememberedSession() {}
}

@MainActor
private final class MockStoreBackendService: BackendServicing {
    let configuration = BackendConfiguration.make(
        apiBaseURL: "https://api.spendsage.ai/dev/",
        environmentName: "dev"
    )

    func fetchStatus(idToken: String?) async throws -> BackendRuntimeStatus {
        BackendRuntimeStatus(
            capabilities: BackendCapabilities(
                mode: "live",
                mocked: false,
                features: .init(
                    expenses: true,
                    budgets: true,
                    spaces: true,
                    invoiceScan: true,
                    csvImport: true,
                    aiInsights: true,
                    promoCodes: true,
                    webhooks: true,
                    pushRegistration: true,
                    billing: true,
                    gamification: true,
                    coach: nil,
                    importsEnabled: true
                ),
                security: .init(
                    waf: true,
                    kmsAtRest: true,
                    cognitoAuth: true,
                    webhookSignatureValidation: true,
                    rateLimits: true
                )
            ),
            entitlements: nil
        )
    }

    func registerDevice(idToken: String, request: BackendDeviceRegistrationRequest) async throws -> BackendDeviceRegistrationResult {
        BackendDeviceRegistrationResult(
            registered: true,
            device: BackendDeviceRecord(
                userId: "user-1",
                platform: request.platform,
                provider: request.provider,
                tokenHash: "hash",
                endpointArn: nil,
                createdAt: "2026-04-07T00:00:00Z",
                updatedAt: "2026-04-07T00:00:00Z"
            )
        )
    }

    func sendTestPush(idToken: String, request: BackendDeviceTestPushRequest) async throws -> BackendDeviceTestPushResult {
        BackendDeviceTestPushResult(sent: true, endpointArn: "arn:aws:sns:test", messageId: "msg-1")
    }

    func unregisterDevice(idToken: String, request: BackendDeviceRegistrationRequest) async throws -> BackendDeviceUnregistrationResult {
        BackendDeviceUnregistrationResult(unregistered: true, existed: true)
    }

    func listSpaces(idToken: String) async throws -> [SpaceSummary] { [] }

    func getFamilySharingModel(idToken: String, spaceID: String) async throws -> FamilySharingModel {
        FamilySharingModel(
            spaceId: spaceID,
            ownerUserId: "user-1",
            mode: "family",
            budgetScope: "shared",
            memberCount: 1,
            pendingInviteCount: 0,
            maxMembers: 5,
            remainingSlots: 4,
            entitlements: FamilyEntitlements(
                enforced: true,
                ownerPlanId: "family",
                ownerHasFamilyEntitlement: true,
                memberEditorUpgradeRequiresEntitlement: false
            ),
            permissions: FamilyPermissions(
                callerRole: .owner,
                canWrite: true,
                canManageMembers: true,
                canInvite: true,
                canPromoteToEditor: true
            )
        )
    }

    func listInvites(idToken: String) async throws -> [SpaceInvite] { [] }

    func createInvite(idToken: String, input: CreateInviteInput) async throws -> CreateInviteResult {
        CreateInviteResult(
            invite: SpaceInvite(
                code: "INVITE-1",
                spaceId: input.spaceId ?? "space-1",
                recipientEmailLower: input.recipientEmail.lowercased(),
                role: input.role,
                inviterUserId: "user-1",
                inviterEmailLower: "owner@spendsage.ai",
                createdAt: "2026-04-08T00:00:00Z",
                expiresAt: nil,
                status: .pending,
                acceptedByUserId: nil,
                acceptedAt: nil
            ),
            deepLink: "spendsage://invite/INVITE-1",
            webLink: nil,
            emailDelivery: nil
        )
    }

    func acceptInvite(idToken: String, code: String) async throws -> AcceptInviteResult {
        AcceptInviteResult(accepted: true, spaceId: "space-1", role: .viewer)
    }

    func listSpaceMembers(idToken: String, spaceID: String) async throws -> [SpaceMember] { [] }

    func listSpaceInvites(idToken: String, spaceID: String) async throws -> [SpaceInvite] { [] }

    func getSpaceMember(idToken: String, spaceID: String, memberUserID: String) async throws -> SpaceMember {
        SpaceMember(
            spaceId: spaceID,
            userId: memberUserID,
            userEmailLower: "member@spendsage.ai",
            role: .viewer,
            notificationsEnabled: true,
            addedAt: "2026-04-08T00:00:00Z",
            addedByUserId: "user-1"
        )
    }

    func updateSpaceMember(idToken: String, spaceID: String, memberUserID: String, patch: UpdateSpaceMemberPatch) async throws {}

    func removeSpaceMember(idToken: String, spaceID: String, memberUserID: String) async throws -> BackendSpaceMemberDeleteResult {
        BackendSpaceMemberDeleteResult(removed: true, left: nil)
    }

    func revokeSpaceInvite(idToken: String, spaceID: String, code: String) async throws {}
}

@MainActor
private final class MockStoreBillingService: StoreBillingServicing {
    var products: [StoreCatalogProduct]
    var entitlements: StoreEntitlementSnapshot
    var restoredEntitlements: StoreEntitlementSnapshot?
    var purchasedProductIDs: [String] = []

    init(
        products: [StoreCatalogProduct],
        entitlements: StoreEntitlementSnapshot,
        restoredEntitlements: StoreEntitlementSnapshot? = nil
    ) {
        self.products = products
        self.entitlements = entitlements
        self.restoredEntitlements = restoredEntitlements
    }

    func loadCatalog() async throws -> [StoreCatalogProduct] {
        products
    }

    func refreshEntitlements() async throws -> StoreEntitlementSnapshot {
        entitlements
    }

    func purchase(productID: String) async throws -> StoreEntitlementSnapshot {
        purchasedProductIDs.append(productID)
        entitlements = StoreEntitlementSnapshot(
            activeProductIDs: [productID],
            activePlanKey: StoreProductID(rawValue: productID)?.planKey,
            hasRemoveAds: productID == StoreProductID.removeAds.rawValue
        )
        return entitlements
    }

    func restorePurchases() async throws -> StoreEntitlementSnapshot {
        if let restoredEntitlements {
            entitlements = restoredEntitlements
        }
        return entitlements
    }

    func managementURL() -> URL? {
        URL(string: "https://apps.apple.com/account/subscriptions")
    }
}
