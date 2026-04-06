import AuthenticationServices
import CryptoKit
import Foundation
import UIKit

@MainActor
final class HostedUIAuthService: NSObject, AuthServicing {
    let configuration: AuthConfiguration
    private var lastProfileSeed: AuthProfileSeed?

    init(configuration: AuthConfiguration) {
        self.configuration = configuration
    }

    func signIn(email: String, password: String) async throws -> SessionState {
        try AuthValidation.validate(
            email: email,
            password: String(repeating: "x", count: max(password.count, configuration.minimumPasswordLength)),
            minimumPasswordLength: configuration.minimumPasswordLength
        )
        return try await authorize(action: .signIn, provider: nil, loginHint: email)
    }

    func createAccount(email: String, password: String) async throws -> SessionState {
        try AuthValidation.validate(
            email: email,
            password: String(repeating: "x", count: max(password.count, configuration.minimumPasswordLength)),
            minimumPasswordLength: configuration.minimumPasswordLength
        )
        return try await authorize(action: .createAccount, provider: nil, loginHint: email)
    }

    func signInWithSocial(_ provider: SocialProvider) async throws -> SessionState {
        guard configuration.supportedSocialProviders.contains(provider) else {
            throw AuthError.providerUnavailable(provider)
        }
        return try await authorize(action: .social, provider: provider, loginHint: nil)
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

    private func authorize(
        action: AuthConfiguration.AuthAction,
        provider: SocialProvider?,
        loginHint: String?
    ) async throws -> SessionState {
        guard let hostedUI = configuration.hostedUI else {
            throw AuthError.providerUnavailable(provider ?? .google)
        }

        let verifier = Self.randomVerifier()
        let challenge = Self.codeChallenge(for: verifier)
        let url = hostedUI.authorizationURL(
            for: provider,
            action: action,
            codeChallenge: challenge,
            loginHint: loginHint
        )

        let callbackURL = try await startSession(url: url, callbackScheme: hostedUI.callbackScheme)
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
            throw NSError(domain: "HostedUIAuthService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid callback URL."])
        }

        if let errorValue = components.queryItems?.first(where: { $0.name == "error" })?.value {
            let description = components.queryItems?.first(where: { $0.name == "error_description" })?.value ?? errorValue
            throw NSError(domain: "HostedUIAuthService", code: 2, userInfo: [NSLocalizedDescriptionKey: description])
        }

        guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw NSError(domain: "HostedUIAuthService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Authorization code was not returned."])
        }

        let tokenResponse = try await exchangeCode(
            code: code,
            verifier: verifier,
            hostedUI: hostedUI
        )

        let profileSeed = Self.profileSeed(
            fromIDToken: tokenResponse.idToken,
            fallbackEmail: loginHint ?? "\(provider?.rawValue.lowercased() ?? "user")@spendsage.ai"
        )
        lastProfileSeed = profileSeed
        let email = profileSeed.preferredEmail ?? loginHint ?? "\(provider?.rawValue.lowercased() ?? "user")@spendsage.ai"
        let providerLabel = provider?.rawValue ?? "Hosted UI"
        return .signedIn(email: email, provider: providerLabel)
    }

    private func startSession(url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: NSError(domain: "HostedUIAuthService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Authentication was cancelled."]))
                    return
                }
                continuation.resume(returning: callbackURL)
            }
            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = PresentationAnchorProvider.shared
            if !session.start() {
                continuation.resume(throwing: NSError(domain: "HostedUIAuthService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Unable to start secure browser session."]))
            }
        }
    }

    private func exchangeCode(
        code: String,
        verifier: String,
        hostedUI: AuthConfiguration.HostedUI
    ) async throws -> HostedUITokenResponse {
        var request = URLRequest(url: hostedUI.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let formItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "client_id", value: hostedUI.clientId),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: hostedUI.redirectSignIn),
            URLQueryItem(name: "code_verifier", value: verifier),
        ]

        var components = URLComponents()
        components.queryItems = formItems
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown token exchange error."
            throw NSError(domain: "HostedUIAuthService", code: 6, userInfo: [NSLocalizedDescriptionKey: body])
        }

        return try JSONDecoder().decode(HostedUITokenResponse.self, from: data)
    }

    private static func randomVerifier() -> String {
        let data = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        return base64url(data)
    }

    private static func codeChallenge(for verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return base64url(Data(digest))
    }

    private static func base64url(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func tokenPayload(from token: String) -> [String: Any]? {
        let segments = token.split(separator: ".")
        guard segments.count > 1 else { return nil }
        var payload = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while payload.count % 4 != 0 {
            payload.append("=")
        }
        guard
            let data = Data(base64Encoded: payload),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }
        return json
    }

    private static func profileSeed(fromIDToken token: String, fallbackEmail: String?) -> AuthProfileSeed {
        let payload = tokenPayload(from: token)
        let givenName = payload?["given_name"] as? String
        let familyName = payload?["family_name"] as? String
        let fullName = (payload?["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let mergedName = [givenName, familyName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return AuthProfileSeed(
            fullName: (fullName?.isEmpty == false ? fullName : nil) ?? (mergedName.isEmpty ? nil : mergedName),
            email: (payload?["email"] as? String) ?? (payload?["cognito:username"] as? String) ?? fallbackEmail
        )
    }
}

private struct HostedUITokenResponse: Decodable {
    let accessToken: String
    let idToken: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case idToken = "id_token"
        case refreshToken = "refresh_token"
    }
}

private final class PresentationAnchorProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = PresentationAnchorProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}
