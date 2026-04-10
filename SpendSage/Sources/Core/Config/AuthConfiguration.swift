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
        let clientId: String
        let redirectSignIn: String
        let redirectSignOut: String
        let scopes: [String]
        let signInPath: String
        let signUpPath: String
        let tokenPath: String

        var authorizePath: String { "/oauth2/authorize" }

        func authorizationURL(
            for provider: SocialProvider?,
            action: AuthAction,
            codeChallenge: String,
            loginHint: String? = nil
        ) -> URL {
            let path: String
            switch action {
            case .signIn:
                path = signInPath
            case .createAccount:
                path = signUpPath
            case .social:
                path = authorizePath
            }

            var components = URLComponents(url: issuerBaseURL, resolvingAgainstBaseURL: false) ?? URLComponents()
            components.path = issuerBaseURL.path + path
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "client_id", value: clientId),
                URLQueryItem(name: "response_type", value: "code"),
                URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
                URLQueryItem(name: "redirect_uri", value: redirectSignIn),
                URLQueryItem(name: "code_challenge_method", value: "S256"),
                URLQueryItem(name: "code_challenge", value: codeChallenge),
            ]
            if let provider {
                let providerName = provider == .apple ? "SignInWithApple" : provider.rawValue
                queryItems.append(URLQueryItem(name: "identity_provider", value: providerName))
            }
            if let loginHint, !loginHint.isEmpty {
                queryItems.append(URLQueryItem(name: "login_hint", value: loginHint))
            }
            components.queryItems = queryItems
            return components.url ?? issuerBaseURL
        }

        var tokenURL: URL {
            var components = URLComponents(url: issuerBaseURL, resolvingAgainstBaseURL: false) ?? URLComponents()
            components.path = issuerBaseURL.path + tokenPath
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
        appName: "MichiFinanzas",
        allowsGuestAccess: false,
        emailPasswordEnabled: true,
        minimumPasswordLength: 8,
        supportedSocialProviders: SocialProvider.allCases,
        hostedUI: nil,
        previewEmailDomain: "spendsage.preview",
        localPreviewFootnote: "Your account is the home of your plan, progress, and personalization.",
        hostedUIFootnote: "Apple and Google sign in are available as fast account entry points."
    )

    static func liveFromBundle(_ bundle: Bundle = .main) -> AuthConfiguration? {
        guard
            let domain = bundle.object(forInfoDictionaryKey: "SpendSageCognitoHostedUIDomain") as? String,
            let clientId = bundle.object(forInfoDictionaryKey: "SpendSageCognitoUserPoolClientId") as? String,
            let redirectSignIn = bundle.object(forInfoDictionaryKey: "SpendSageCognitoRedirectSignIn") as? String,
            let redirectSignOut = bundle.object(forInfoDictionaryKey: "SpendSageCognitoRedirectSignOut") as? String
        else {
            return nil
        }

        let trimmedDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedClientId = clientId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRedirectSignIn = redirectSignIn.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRedirectSignOut = redirectSignOut.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            !trimmedDomain.isEmpty,
            !trimmedClientId.isEmpty,
            !trimmedRedirectSignIn.isEmpty,
            !trimmedRedirectSignOut.isEmpty,
            let issuerBaseURL = URL(string: "https://\(trimmedDomain)")
        else {
            return nil
        }

        let callbackScheme = URL(string: trimmedRedirectSignIn)?.scheme ?? "spendsage"

        return AuthConfiguration(
            mode: .hostedUI,
            appName: "MichiFinanzas",
            allowsGuestAccess: false,
            emailPasswordEnabled: true,
            minimumPasswordLength: 8,
            supportedSocialProviders: SocialProvider.allCases,
            hostedUI: HostedUI(
                issuerBaseURL: issuerBaseURL,
                callbackScheme: callbackScheme,
                clientId: trimmedClientId,
                redirectSignIn: trimmedRedirectSignIn,
                redirectSignOut: trimmedRedirectSignOut,
                scopes: ["openid", "email", "profile"],
                signInPath: "/login",
                signUpPath: "/signup",
                tokenPath: "/oauth2/token"
            ),
            previewEmailDomain: "michifinanzas.local",
            localPreviewFootnote: "Sign in with your MichiFinanzas account to keep your plan, profile, and restore path together.",
            hostedUIFootnote: "Apple and Google sign in use Cognito Hosted UI with a secure browser session."
        )
    }

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
            authorizationURL: hostedUI.issuerBaseURL,
            callbackScheme: hostedUI.callbackScheme,
            prefersEphemeralSession: true
        )
    }
}
