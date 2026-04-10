import Foundation

@MainActor
protocol AuthServicing {
    var configuration: AuthConfiguration { get }
    func signIn(email: String, password: String) async throws -> SessionState
    func createAccount(email: String, password: String) async throws -> SessionState
    func signInWithSocial(_ provider: SocialProvider) async throws -> SessionState
    func continueAsGuest() async -> SessionState
    func hostedUIRequest(for provider: SocialProvider) -> AuthHostedUIRequest?
    func consumeProfileSeed() -> AuthProfileSeed?
    func hasRememberedSession() -> Bool
    func restoreRememberedSession() async -> SessionState?
    func currentIDToken() async -> String?
    func forgetRememberedSession()
}

@MainActor
protocol DashboardProviding {
    func loadBudgetSnapshot(for session: SessionState) async -> BudgetSnapshot
    func loadRecentExpenses(for session: SessionState) async -> [ExpenseItem]
}

enum DefaultAuthService {
    @MainActor
    static func make() -> AuthServicing {
        if let liveConfiguration = AuthConfiguration.liveFromBundle() {
            return HostedUIAuthService(configuration: liveConfiguration)
        }
        return PreviewAuthService()
    }
}

@MainActor
final class PreviewAuthService: AuthServicing {
    let configuration: AuthConfiguration
    private var lastProfileSeed: AuthProfileSeed?
    private var rememberedSession: SessionState?

    init(configuration: AuthConfiguration = .preview) {
        self.configuration = configuration
    }

    func signIn(email: String, password: String) async throws -> SessionState {
        try AuthValidation.validate(email: email)
        try await Task.sleep(for: .milliseconds(150))
        lastProfileSeed = AuthProfileSeed(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
        let session = SessionState.signedIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines), provider: "Email")
        if AuthSessionPreferences.rememberDeviceEnabled() {
            rememberedSession = session
        }
        return session
    }

    func createAccount(email: String, password: String) async throws -> SessionState {
        try AuthValidation.validate(email: email)
        try await Task.sleep(for: .milliseconds(180))
        lastProfileSeed = AuthProfileSeed(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
        let session = SessionState.signedIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines), provider: "Email")
        if AuthSessionPreferences.rememberDeviceEnabled() {
            rememberedSession = session
        }
        return session
    }

    func signInWithSocial(_ provider: SocialProvider) async throws -> SessionState {
        guard configuration.supportedSocialProviders.contains(provider) else {
            throw AuthError.providerUnavailable(provider)
        }
        try await Task.sleep(for: .milliseconds(180))
        lastProfileSeed = AuthProfileSeed(
            fullName: nil,
            email: "\(provider.rawValue.lowercased())@michifinanzas.local"
        )
        let session = SessionState.signedIn(email: "\(provider.rawValue.lowercased())@michifinanzas.local", provider: provider.rawValue)
        if AuthSessionPreferences.rememberDeviceEnabled() {
            rememberedSession = session
        }
        return session
    }

    func continueAsGuest() async -> SessionState {
        .guest
    }

    func hostedUIRequest(for provider: SocialProvider) -> AuthHostedUIRequest? {
        configuration.hostedUIRequest(for: provider, action: .social)
    }

    func consumeProfileSeed() -> AuthProfileSeed? {
        defer { lastProfileSeed = nil }
        return lastProfileSeed
    }

    func hasRememberedSession() -> Bool {
        rememberedSession != nil
    }

    func restoreRememberedSession() async -> SessionState? {
        try? await Task.sleep(for: .milliseconds(120))
        return rememberedSession
    }

    func currentIDToken() async -> String? {
        nil
    }

    func forgetRememberedSession() {
        rememberedSession = nil
        lastProfileSeed = nil
    }
}

@MainActor
struct PreviewDashboardStore: DashboardProviding {
    func loadBudgetSnapshot(for session: SessionState) async -> BudgetSnapshot {
        BudgetSnapshot(
            monthlyIncome: 3200,
            monthlySpent: 1840,
            monthlyBudget: 2400
        )
    }

    func loadRecentExpenses(for session: SessionState) async -> [ExpenseItem] {
        [
            ExpenseItem(id: UUID(), title: "Supermarket", category: "Food", amount: 86.40, date: .now),
            ExpenseItem(id: UUID(), title: "Ride Share", category: "Transport", amount: 12.10, date: .now.addingTimeInterval(-86400)),
            ExpenseItem(id: UUID(), title: "Coffee", category: "Lifestyle", amount: 4.80, date: .now.addingTimeInterval(-172800))
        ]
    }
}
