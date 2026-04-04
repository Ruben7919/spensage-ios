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
            return "Enter a valid email address.".appLocalized
        case let .weakPassword(minimum):
            return AppLocalization.localized("Use at least %d characters.", arguments: minimum)
        case .passwordsDoNotMatch:
            return "Passwords do not match.".appLocalized
        case let .providerUnavailable(provider):
            return AppLocalization.localized("%@ sign-in is not available yet.", arguments: provider.displayName)
        }
    }
}

enum AuthValidation {
    static func validate(email: String) throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            throw AuthError.invalidEmail
        }
    }

    static func validate(email: String, password: String, minimumPasswordLength: Int) throws {
        try validate(email: email)
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
