import Foundation
import Testing
@testable import SpendSage

@MainActor
struct PushRegistrationFlowTests {
    @Test
    func registerPushUploadsDeviceToken() async {
        PushRegistrationPersistence.resetForTesting()

        let auth = MockAuthService(idToken: "id-token")
        let backend = MockBackendService()
        let push = MockPushRegistrationService(
            authorization: .authorized,
            cachedToken: nil,
            requestedToken: .success("apns-token-1234567890")
        )
        let viewModel = AppViewModel(
            authService: auth,
            financeStore: LocalFinanceStore(),
            backendService: backend,
            pushRegistrationService: push
        )

        viewModel.session = .signedIn(email: "push@spendsage.ai", provider: "Apple")
        viewModel.backendStatus = BackendRuntimeStatus(capabilities: makeCapabilities(pushRegistration: true), entitlements: nil)

        await viewModel.registerPushNotifications()

        #expect(backend.registeredRequests.count == 1)
        #expect(backend.registeredRequests.first?.token == "apns-token-1234567890")
        #expect(backend.registeredRequests.first?.apnsEnvironment == .sandbox)
        #expect(viewModel.pushRegistrationStatus.lastError == nil)
        #expect(viewModel.pushRegistrationStatus.lastUploadedEmail == "push@spendsage.ai")
    }

    @Test
    func signOutUnregistersCachedPushToken() async {
        PushRegistrationPersistence.resetForTesting()
        PushRegistrationPersistence.cacheToken("apns-token-1234567890")
        PushRegistrationPersistence.recordUpload(
            token: "apns-token-1234567890",
            email: "push@spendsage.ai",
            environmentName: "dev",
            apnsEnvironment: .sandbox
        )

        let auth = MockAuthService(idToken: "id-token")
        let backend = MockBackendService()
        let push = MockPushRegistrationService(
            authorization: .authorized,
            cachedToken: "apns-token-1234567890",
            requestedToken: .success("apns-token-1234567890")
        )
        let viewModel = AppViewModel(
            authService: auth,
            financeStore: LocalFinanceStore(),
            backendService: backend,
            pushRegistrationService: push
        )

        viewModel.session = .signedIn(email: "push@spendsage.ai", provider: "Apple")
        viewModel.backendStatus = BackendRuntimeStatus(capabilities: makeCapabilities(pushRegistration: true), entitlements: nil)

        await viewModel.signOut()

        #expect(backend.unregisteredRequests.count == 1)
        #expect(backend.unregisteredRequests.first?.token == "apns-token-1234567890")
        #expect(backend.unregisteredRequests.first?.apnsEnvironment == .sandbox)
        #expect(PushRegistrationPersistence.uploadMarker() == nil)
        #expect(viewModel.session == .signedOut)
    }

    @Test
    func bootstrapsEssentialPermissionsOnlyOncePerSessionState() async {
        PushRegistrationPersistence.resetForTesting()

        let auth = MockAuthService(idToken: "id-token")
        let backend = MockBackendService()
        let push = MockPushRegistrationService(
            authorization: .notDetermined,
            cachedToken: nil,
            requestedToken: .success("apns-token-boot-123456")
        )
        let calendar = MockBillCalendarSyncService(authorization: .notDetermined)
        let location = MockExpenseLocationService(authorization: .notDetermined)
        let viewModel = AppViewModel(
            authService: auth,
            financeStore: LocalFinanceStore(),
            backendService: backend,
            pushRegistrationService: push,
            billCalendarSyncService: calendar,
            expenseLocationService: location
        )

        viewModel.hasCompletedOnboarding = true
        viewModel.session = .signedIn(email: "bootstrap@spendsage.ai", provider: "Apple")
        viewModel.backendStatus = BackendRuntimeStatus(capabilities: makeCapabilities(pushRegistration: true), entitlements: nil)

        await viewModel.bootstrapEssentialPermissionsIfNeeded(force: true)
        await viewModel.bootstrapEssentialPermissionsIfNeeded()

        #expect(push.requestRemoteNotificationTokenCallCount == 1)
        #expect(backend.registeredRequests.count == 1)
        #expect(calendar.requestAccessCallCount == 1)
        #expect(location.requestAuthorizationCallCount == 1)
    }

    private func makeCapabilities(pushRegistration: Bool) -> BackendCapabilities {
        BackendCapabilities(
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
                pushRegistration: pushRegistration,
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
        )
    }
}

@MainActor
private final class MockAuthService: AuthServicing {
    let configuration = AuthConfiguration.preview
    let idToken: String?

    init(idToken: String?) {
        self.idToken = idToken
    }

    func signIn(email: String, password: String) async throws -> SessionState { .signedIn(email: email, provider: "Email") }
    func createAccount(email: String, password: String) async throws -> SessionState { .signedIn(email: email, provider: "Email") }
    func signInWithSocial(_ provider: SocialProvider) async throws -> SessionState { .signedIn(email: "social@spendsage.ai", provider: provider.rawValue) }
    func continueAsGuest() async -> SessionState { .guest }
    func hostedUIRequest(for provider: SocialProvider) -> AuthHostedUIRequest? { nil }
    func consumeProfileSeed() -> AuthProfileSeed? { nil }
    func hasRememberedSession() -> Bool { false }
    func restoreRememberedSession() async -> SessionState? { nil }
    func currentIDToken() async -> String? { idToken }
    func forgetRememberedSession() {}
}

@MainActor
private final class MockBackendService: BackendServicing {
    let configuration = BackendConfiguration.make(
        apiBaseURL: "https://api.spendsage.ai/dev/",
        environmentName: "dev"
    )
    var registeredRequests: [BackendDeviceRegistrationRequest] = []
    var unregisteredRequests: [BackendDeviceRegistrationRequest] = []

    func fetchStatus(idToken: String?) async throws -> BackendRuntimeStatus {
        BackendRuntimeStatus(capabilities: BackendCapabilities(
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
                gamification: nil,
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
        ), entitlements: nil)
    }

    func registerDevice(idToken: String, request: BackendDeviceRegistrationRequest) async throws -> BackendDeviceRegistrationResult {
        registeredRequests.append(request)
        return BackendDeviceRegistrationResult(
            registered: true,
            device: BackendDeviceRecord(
                userId: "user-1",
                platform: request.platform,
                provider: request.provider,
                tokenHash: "hash",
                endpointArn: "arn:aws:sns:endpoint",
                createdAt: "2026-04-06T00:00:00Z",
                updatedAt: "2026-04-06T00:00:00Z"
            )
        )
    }

    func sendTestPush(idToken: String, request: BackendDeviceTestPushRequest) async throws -> BackendDeviceTestPushResult {
        BackendDeviceTestPushResult(sent: true, endpointArn: "arn:aws:sns:test", messageId: "msg-1")
    }

    func unregisterDevice(idToken: String, request: BackendDeviceRegistrationRequest) async throws -> BackendDeviceUnregistrationResult {
        unregisteredRequests.append(request)
        return BackendDeviceUnregistrationResult(unregistered: true, existed: true)
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
            webLink: nil
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
private final class MockPushRegistrationService: PushRegistrationServicing {
    var authorization: PushAuthorizationState
    var cachedTokenValue: String?
    let requestedTokenResult: Result<String, Error>
    private(set) var requestRemoteNotificationTokenCallCount = 0

    init(
        authorization: PushAuthorizationState,
        cachedToken: String?,
        requestedToken: Result<String, Error>
    ) {
        self.authorization = authorization
        self.cachedTokenValue = cachedToken
        self.requestedTokenResult = requestedToken
    }

    func authorizationStatus() async -> PushAuthorizationState {
        authorization
    }

    func cachedToken() -> String? {
        cachedTokenValue
    }

    func requestRemoteNotificationToken() async throws -> String {
        requestRemoteNotificationTokenCallCount += 1
        let token = try requestedTokenResult.get()
        cachedTokenValue = token
        authorization = .authorized
        return token
    }
}

@MainActor
private final class MockBillCalendarSyncService: BillCalendarSyncServicing {
    var authorization: BillCalendarAuthorizationState
    private(set) var requestAccessCallCount = 0

    init(authorization: BillCalendarAuthorizationState) {
        self.authorization = authorization
    }

    func authorizationStatus() async -> BillCalendarAuthorizationState {
        authorization
    }

    func requestAccessIfNeeded() async throws {
        requestAccessCallCount += 1
        authorization = .granted
    }

    func syncBills(_ bills: [BillRecord], ledger: LocalFinanceLedger, session: SessionState) async throws -> Int {
        bills.count
    }
}

@MainActor
private final class MockExpenseLocationService: ExpenseLocationServicing {
    var authorization: ExpenseLocationAuthorizationStatus
    private(set) var requestAuthorizationCallCount = 0

    init(authorization: ExpenseLocationAuthorizationStatus) {
        self.authorization = authorization
    }

    func authorizationStatus() async -> ExpenseLocationAuthorizationStatus {
        authorization
    }

    func requestAuthorization() async throws {
        requestAuthorizationCallCount += 1
        authorization = .granted
    }

    func requestCurrentLocationLabel() async throws -> String {
        "Quito, EC"
    }
}
