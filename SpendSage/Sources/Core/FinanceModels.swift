import Foundation

enum ExpenseCategory: String, CaseIterable, Codable, Identifiable {
    case groceries = "Groceries"
    case dining = "Dining"
    case transport = "Transport"
    case coffee = "Coffee"
    case bills = "Bills"
    case shopping = "Shopping"
    case health = "Health"
    case home = "Home"
    case subscriptions = "Subscriptions"
    case education = "Education"
    case other = "Other"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .groceries: return "cart.fill"
        case .dining: return "fork.knife"
        case .transport: return "car.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .bills: return "doc.text.fill"
        case .shopping: return "bag.fill"
        case .health: return "cross.case.fill"
        case .home: return "house.fill"
        case .subscriptions: return "repeat"
        case .education: return "graduationcap.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

struct ExpenseDraft: Equatable {
    var merchant: String
    var amount: Decimal
    var category: ExpenseCategory
    var date: Date
    var note: String

    init(
        merchant: String = "",
        amount: Decimal = 0,
        category: ExpenseCategory = .groceries,
        date: Date = .now,
        note: String = ""
    ) {
        self.merchant = merchant
        self.amount = amount
        self.category = category
        self.date = date
        self.note = note
    }

    var isValid: Bool {
        !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && amount > 0
    }

    func normalized() -> ExpenseDraft {
        ExpenseDraft(
            merchant: merchant.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount,
            category: category,
            date: date,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

struct ExpenseRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var merchant: String
    var category: ExpenseCategory
    var amount: Decimal
    var date: Date
    var note: String?
}

struct CategoryBreakdown: Identifiable, Codable, Equatable {
    var id: String { category.rawValue }
    let category: ExpenseCategory
    let total: Decimal
    let count: Int
}

struct FinanceDashboardState: Equatable {
    let budgetSnapshot: BudgetSnapshot
    let recentExpenses: [ExpenseItem]
    let categoryBreakdown: [CategoryBreakdown]
    let largestExpense: ExpenseItem?
    let transactionCount: Int
    let lastUpdated: Date

    var utilizationRatio: Double {
        guard budgetSnapshot.monthlyBudget > 0 else { return 0 }
        let spent = NSDecimalNumber(decimal: budgetSnapshot.monthlySpent).doubleValue
        let budget = NSDecimalNumber(decimal: budgetSnapshot.monthlyBudget).doubleValue
        return spent / budget
    }

    var averageExpense: Decimal {
        guard transactionCount > 0 else { return 0 }
        return budgetSnapshot.monthlySpent / Decimal(transactionCount)
    }

    var topCategory: CategoryBreakdown? {
        categoryBreakdown.first
    }

    var remainingDaysInMonth: Int {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        guard let range = calendar.range(of: .day, in: .month, for: now) else {
            return 0
        }
        let day = calendar.component(.day, from: now)
        return max(range.count - day, 0)
    }
}

struct LocalFinanceLedger: Codable, Equatable {
    var monthlyIncome: Decimal
    var monthlyBudget: Decimal
    var expenses: [ExpenseRecord]
    var updatedAt: Date

    func budgetSnapshot(for date: Date = .now) -> BudgetSnapshot {
        let calendar = Calendar.autoupdatingCurrent
        let monthExpenses = expenses.filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }
        let monthlySpent = monthExpenses.reduce(Decimal.zero) { $0 + $1.amount }
        return BudgetSnapshot(
            monthlyIncome: monthlyIncome,
            monthlySpent: monthlySpent,
            monthlyBudget: monthlyBudget
        )
    }

    func recentExpenseItems(limit: Int = 8) -> [ExpenseItem] {
        expenses
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { record in
                ExpenseItem(
                    id: record.id,
                    title: record.merchant,
                    category: record.category.rawValue,
                    amount: record.amount,
                    date: record.date
                )
            }
    }

    func categoryBreakdown(for date: Date = .now, limit: Int = 3) -> [CategoryBreakdown] {
        let calendar = Calendar.autoupdatingCurrent
        let monthExpenses = expenses.filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }
        let grouped = Dictionary(grouping: monthExpenses, by: \.category)

        return grouped
            .map { category, records in
                CategoryBreakdown(
                    category: category,
                    total: records.reduce(Decimal.zero) { $0 + $1.amount },
                    count: records.count
                )
            }
            .sorted { $0.total > $1.total }
            .prefix(limit)
            .map { $0 }
    }

    func dashboardState(for date: Date = .now) -> FinanceDashboardState {
        let budgetSnapshot = budgetSnapshot(for: date)
        let recentExpenses = recentExpenseItems()
        let largestExpense = expenses.max { $0.amount < $1.amount }?.mapExpenseItem()

        return FinanceDashboardState(
            budgetSnapshot: budgetSnapshot,
            recentExpenses: recentExpenses,
            categoryBreakdown: categoryBreakdown(for: date),
            largestExpense: largestExpense,
            transactionCount: expenses.count,
            lastUpdated: updatedAt
        )
    }

    mutating func appendExpense(_ draft: ExpenseDraft, id: UUID = UUID(), date: Date = .now) {
        let normalized = draft.normalized()
        expenses.insert(
            ExpenseRecord(
                id: id,
                merchant: normalized.merchant,
                category: normalized.category,
                amount: normalized.amount,
                date: normalized.date == .distantPast ? date : normalized.date,
                note: normalized.note.isEmpty ? nil : normalized.note
            ),
            at: 0
        )
        updatedAt = date
    }
}

private extension ExpenseRecord {
    func mapExpenseItem() -> ExpenseItem {
        ExpenseItem(id: id, title: merchant, category: category.rawValue, amount: amount, date: date)
    }
}
