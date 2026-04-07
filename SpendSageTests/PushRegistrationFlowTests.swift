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
            environmentName: "dev"
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
        #expect(PushRegistrationPersistence.uploadMarker() == nil)
        #expect(viewModel.session == .signedOut)
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

    func unregisterDevice(idToken: String, request: BackendDeviceRegistrationRequest) async throws -> BackendDeviceUnregistrationResult {
        unregisteredRequests.append(request)
        return BackendDeviceUnregistrationResult(unregistered: true, existed: true)
    }
}

@MainActor
private final class MockPushRegistrationService: PushRegistrationServicing {
    let authorization: PushAuthorizationState
    let cachedTokenValue: String?
    let requestedTokenResult: Result<String, Error>

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
        try requestedTokenResult.get()
    }
}
