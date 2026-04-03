import Foundation

struct AuthConfiguration: Equatable {
    enum Mode: String, Equatable {
        case localPreview
        case hostedUI
    }

    enum AuthAction: String, Equatable {
        case signIn
        case createAccount
        case social
    }

    struct HostedUI: Equatable {
        let issuerBaseURL: URL
        let callbackScheme: String
        let signInPath: String
        let signUpPath: String
        let applePath: String
        let googlePath: String

        func authorizationURL(for provider: SocialProvider, action: AuthAction) -> URL {
            let path: String
            switch action {
            case .signIn:
                path = signInPath
            case .createAccount:
                path = signUpPath
            case .social:
                path = provider == .apple ? applePath : googlePath
            }

            var components = URLComponents(url: issuerBaseURL, resolvingAgainstBaseURL: false) ?? URLComponents()
            components.path = issuerBaseURL.path + path
            components.queryItems = [
                URLQueryItem(name: "provider", value: provider.rawValue.lowercased()),
                URLQueryItem(name: "action", value: action.rawValue)
            ]
            return components.url ?? issuerBaseURL
        }
    }

    let mode: Mode
    let appName: String
    let allowsGuestAccess: Bool
    let emailPasswordEnabled: Bool
    let minimumPasswordLength: Int
    let supportedSocialProviders: [SocialProvider]
    let hostedUI: HostedUI?
    let previewEmailDomain: String
    let localPreviewFootnote: String
    let hostedUIFootnote: String

    static let preview = AuthConfiguration(
        mode: .localPreview,
        appName: "SpendSage",
        allowsGuestAccess: true,
        emailPasswordEnabled: true,
        minimumPasswordLength: 8,
        supportedSocialProviders: SocialProvider.allCases,
        hostedUI: nil,
        previewEmailDomain: "spendsage.preview",
        localPreviewFootnote: "Preview mode keeps auth local today and leaves room for Cognito Hosted UI later.",
        hostedUIFootnote: "Hosted UI is ready to be wired once Cognito and ASWebAuthenticationSession are added."
    )

    var isHostedUIReady: Bool {
        hostedUI != nil
    }

    var providerSummary: String {
        supportedSocialProviders.map(\.rawValue).joined(separator: ", ")
    }

    func hostedUIRequest(for provider: SocialProvider, action: AuthAction) -> AuthHostedUIRequest? {
        guard let hostedUI else { return nil }
        return AuthHostedUIRequest(
            provider: provider,
            action: action,
            authorizationURL: hostedUI.authorizationURL(for: provider, action: action),
            callbackScheme: hostedUI.callbackScheme,
            prefersEphemeralSession: true
        )
    }
}

