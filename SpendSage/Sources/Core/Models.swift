import Foundation

enum SocialProvider: String, CaseIterable, Identifiable {
    case google = "Google"
    case apple = "Apple"

    var id: String { rawValue }

    var displayName: String {
        rawValue.appLocalized
    }
}

enum SessionState: Equatable {
    case signedOut
    case guest
    case signedIn(email: String, provider: String?)

    var isAuthenticated: Bool {
        switch self {
        case .signedOut:
            return false
        case .guest:
            return false
        case .signedIn:
            return true
        }
    }

    var emailAddress: String? {
        switch self {
        case let .signedIn(email, _):
            return email
        case .signedOut, .guest:
            return nil
        }
    }

    var providerName: String? {
        switch self {
        case let .signedIn(_, provider):
            return provider
        case .signedOut, .guest:
            return nil
        }
    }

    var socialProvider: SocialProvider? {
        providerName.flatMap(SocialProvider.init(rawValue:))
    }

    var storageNamespace: String {
        switch self {
        case .signedOut:
            return "signed-out"
        case .guest:
            return "guest"
        case let .signedIn(email, provider):
            let raw = "\(email.lowercased())-\(provider ?? "email")"
            let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
            let sanitizedScalars = raw.unicodeScalars.map { scalar in
                allowed.contains(scalar) ? Character(scalar) : "_"
            }
            return String(sanitizedScalars)
                .replacingOccurrences(of: "__", with: "_")
                .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        }
    }
}

struct ExpenseItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let category: String
    let amount: Decimal
    let date: Date
}

struct BudgetSnapshot: Equatable {
    let monthlyIncome: Decimal
    let monthlySpent: Decimal
    let monthlyBudget: Decimal

    var remaining: Decimal {
        monthlyBudget - monthlySpent
    }
}
