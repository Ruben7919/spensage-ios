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

enum AccountKind: String, CaseIterable, Codable, Identifiable {
    case checking = "Checking"
    case savings = "Savings"
    case cash = "Cash"
    case creditCard = "Credit Card"
    case investment = "Investment"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .checking: return "building.columns.fill"
        case .savings: return "banknote.fill"
        case .cash: return "dollarsign.circle.fill"
        case .creditCard: return "creditcard.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        }
    }
}

struct AccountDraft: Equatable {
    var name: String
    var institution: String
    var balance: Decimal
    var kind: AccountKind

    init(
        name: String = "",
        institution: String = "",
        balance: Decimal = 0,
        kind: AccountKind = .checking
    ) {
        self.name = name
        self.institution = institution
        self.balance = balance
        self.kind = kind
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct AccountRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var institution: String
    var balance: Decimal
    var kind: AccountKind
}

struct BillDraft: Equatable {
    var title: String
    var amount: Decimal
    var dueDay: Int
    var category: ExpenseCategory
    var autopay: Bool

    init(
        title: String = "",
        amount: Decimal = 0,
        dueDay: Int = 1,
        category: ExpenseCategory = .bills,
        autopay: Bool = false
    ) {
        self.title = title
        self.amount = amount
        self.dueDay = dueDay
        self.category = category
        self.autopay = autopay
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && amount > 0 && (1...31).contains(dueDay)
    }
}

struct BillRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var amount: Decimal
    var dueDay: Int
    var category: ExpenseCategory
    var autopay: Bool
    var lastPaidAt: Date?
}

struct RuleDraft: Equatable {
    var merchantKeyword: String
    var category: ExpenseCategory
    var note: String

    init(
        merchantKeyword: String = "",
        category: ExpenseCategory = .other,
        note: String = ""
    ) {
        self.merchantKeyword = merchantKeyword
        self.category = category
        self.note = note
    }

    var isValid: Bool {
        !merchantKeyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct RuleRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var merchantKeyword: String
    var category: ExpenseCategory
    var note: String?
}

struct ProfileRecord: Codable, Equatable {
    var fullName: String
    var householdName: String
    var email: String
    var countryCode: String
    var marketingOptIn: Bool

    static let `default` = ProfileRecord(
        fullName: "SpendSage User",
        householdName: "My Household",
        email: "hello@spendsage.ai",
        countryCode: "US",
        marketingOptIn: false
    )
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
    var accounts: [AccountRecord]
    var bills: [BillRecord]
    var rules: [RuleRecord]
    var profile: ProfileRecord
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case monthlyIncome
        case monthlyBudget
        case expenses
        case accounts
        case bills
        case rules
        case profile
        case updatedAt
    }

    init(
        monthlyIncome: Decimal,
        monthlyBudget: Decimal,
        expenses: [ExpenseRecord],
        accounts: [AccountRecord] = [],
        bills: [BillRecord] = [],
        rules: [RuleRecord] = [],
        profile: ProfileRecord = .default,
        updatedAt: Date
    ) {
        self.monthlyIncome = monthlyIncome
        self.monthlyBudget = monthlyBudget
        self.expenses = expenses
        self.accounts = accounts
        self.bills = bills
        self.rules = rules
        self.profile = profile
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        monthlyIncome = try container.decode(Decimal.self, forKey: .monthlyIncome)
        monthlyBudget = try container.decode(Decimal.self, forKey: .monthlyBudget)
        expenses = try container.decodeIfPresent([ExpenseRecord].self, forKey: .expenses) ?? []
        accounts = try container.decodeIfPresent([AccountRecord].self, forKey: .accounts) ?? []
        bills = try container.decodeIfPresent([BillRecord].self, forKey: .bills) ?? []
        rules = try container.decodeIfPresent([RuleRecord].self, forKey: .rules) ?? []
        profile = try container.decodeIfPresent(ProfileRecord.self, forKey: .profile) ?? .default
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .now
    }

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
        let matchedCategory = inferredCategory(for: normalized.merchant) ?? normalized.category
        expenses.insert(
            ExpenseRecord(
                id: id,
                merchant: normalized.merchant,
                category: matchedCategory,
                amount: normalized.amount,
                date: normalized.date == .distantPast ? date : normalized.date,
                note: normalized.note.isEmpty ? nil : normalized.note
            ),
            at: 0
        )
        updatedAt = date
    }

    mutating func appendAccount(_ draft: AccountDraft, id: UUID = UUID(), date: Date = .now) {
        accounts.insert(
            AccountRecord(
                id: id,
                name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                institution: draft.institution.trimmingCharacters(in: .whitespacesAndNewlines),
                balance: draft.balance,
                kind: draft.kind
            ),
            at: 0
        )
        updatedAt = date
    }

    mutating func appendBill(_ draft: BillDraft, id: UUID = UUID(), date: Date = .now) {
        bills.insert(
            BillRecord(
                id: id,
                title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                amount: draft.amount,
                dueDay: draft.dueDay,
                category: draft.category,
                autopay: draft.autopay,
                lastPaidAt: nil
            ),
            at: 0
        )
        updatedAt = date
    }

    mutating func appendRule(_ draft: RuleDraft, id: UUID = UUID(), date: Date = .now) {
        rules.insert(
            RuleRecord(
                id: id,
                merchantKeyword: draft.merchantKeyword.trimmingCharacters(in: .whitespacesAndNewlines),
                category: draft.category,
                note: draft.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
            ),
            at: 0
        )
        updatedAt = date
    }

    mutating func markBillPaid(_ billID: UUID, date: Date = .now) {
        guard let index = bills.firstIndex(where: { $0.id == billID }) else { return }
        bills[index].lastPaidAt = date
        appendExpense(
            ExpenseDraft(
                merchant: bills[index].title,
                amount: bills[index].amount,
                category: bills[index].category,
                date: date,
                note: bills[index].autopay ? "Autopay bill" : "Bill payment"
            ),
            date: date
        )
    }

    mutating func importExpenses(_ drafts: [ExpenseDraft], date: Date = .now) {
        for draft in drafts {
            appendExpense(draft, date: date)
        }
        updatedAt = date
    }

    mutating func updateProfile(_ profile: ProfileRecord, date: Date = .now) {
        self.profile = profile
        updatedAt = date
    }

    func totalAccountBalance() -> Decimal {
        accounts.reduce(Decimal.zero) { $0 + $1.balance }
    }

    func upcomingBills(referenceDate: Date = .now) -> [BillRecord] {
        bills.sorted {
            dueDate(for: $0, referenceDate: referenceDate) < dueDate(for: $1, referenceDate: referenceDate)
        }
    }

    func dueDate(for bill: BillRecord, referenceDate: Date = .now) -> Date {
        let calendar = Calendar.autoupdatingCurrent
        let components = calendar.dateComponents([.year, .month], from: referenceDate)
        let day = min(max(bill.dueDay, 1), 28)
        let currentMonthDate = calendar.date(from: DateComponents(year: components.year, month: components.month, day: day)) ?? referenceDate
        if currentMonthDate >= calendar.startOfDay(for: referenceDate) {
            return currentMonthDate
        }
        return calendar.date(byAdding: .month, value: 1, to: currentMonthDate) ?? currentMonthDate
    }

    func matchingExpensesCount(for rule: RuleRecord) -> Int {
        let keyword = rule.merchantKeyword.lowercased()
        return expenses.filter { $0.merchant.lowercased().contains(keyword) }.count
    }

    func inferredCategory(for merchant: String) -> ExpenseCategory? {
        let normalized = merchant.lowercased()
        return rules.first(where: { normalized.contains($0.merchantKeyword.lowercased()) })?.category
    }
}

private extension ExpenseRecord {
    func mapExpenseItem() -> ExpenseItem {
        ExpenseItem(id: id, title: merchant, category: category.rawValue, amount: amount, date: date)
    }
}
