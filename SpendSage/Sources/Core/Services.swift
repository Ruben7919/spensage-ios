import Foundation

@MainActor
protocol AuthServicing {
    var configuration: AuthConfiguration { get }
    func signIn(email: String, password: String) async throws -> SessionState
    func createAccount(email: String, password: String) async throws -> SessionState
    func signInWithSocial(_ provider: SocialProvider) async throws -> SessionState
    func continueAsGuest() async -> SessionState
    func hostedUIRequest(for provider: SocialProvider) -> AuthHostedUIRequest?
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
struct PreviewAuthService: AuthServicing {
    let configuration: AuthConfiguration

    init(configuration: AuthConfiguration = .preview) {
        self.configuration = configuration
    }

    func signIn(email: String, password: String) async throws -> SessionState {
        try AuthValidation.validate(email: email)
        try await Task.sleep(for: .milliseconds(150))
        return .signedIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines), provider: nil)
    }

    func createAccount(email: String, password: String) async throws -> SessionState {
        try AuthValidation.validate(email: email)
        try await Task.sleep(for: .milliseconds(180))
        return .signedIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines), provider: "Email")
    }

    func signInWithSocial(_ provider: SocialProvider) async throws -> SessionState {
        guard configuration.supportedSocialProviders.contains(provider) else {
            throw AuthError.providerUnavailable(provider)
        }
        try await Task.sleep(for: .milliseconds(180))
        return .signedIn(email: "\(provider.rawValue.lowercased())@spendsage.ai", provider: provider.rawValue)
    }

    func continueAsGuest() async -> SessionState {
        .guest
    }

    func hostedUIRequest(for provider: SocialProvider) -> AuthHostedUIRequest? {
        configuration.hostedUIRequest(for: provider, action: .social)
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
