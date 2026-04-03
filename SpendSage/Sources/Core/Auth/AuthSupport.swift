import Foundation

struct AuthHostedUIRequest: Equatable {
    let provider: SocialProvider
    let action: AuthConfiguration.AuthAction
    let authorizationURL: URL
    let callbackScheme: String
    let prefersEphemeralSession: Bool
}

enum AuthError: LocalizedError, Equatable {
    case invalidEmail
    case weakPassword(minimum: Int)
    case passwordsDoNotMatch
    case providerUnavailable(SocialProvider)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Enter a valid email address."
        case let .weakPassword(minimum):
            return "Use at least \(minimum) characters."
        case .passwordsDoNotMatch:
            return "Passwords do not match."
        case let .providerUnavailable(provider):
            return "\(provider.rawValue) sign-in is not available yet."
        }
    }
}

enum AuthValidation {
    static func validate(email: String, password: String, minimumPasswordLength: Int) throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            throw AuthError.invalidEmail
        }
        guard password.count >= minimumPasswordLength else {
            throw AuthError.weakPassword(minimum: minimumPasswordLength)
        }
    }

    static func validateCreateAccount(
        email: String,
        password: String,
        confirmPassword: String,
        minimumPasswordLength: Int
    ) throws {
        try validate(email: email, password: password, minimumPasswordLength: minimumPasswordLength)
        guard password == confirmPassword else {
            throw AuthError.passwordsDoNotMatch
        }
    }
}

