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
        case .guest, .signedIn:
            return true
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
