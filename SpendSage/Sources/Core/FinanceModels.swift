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

enum AccountBalanceState: String, CaseIterable, Codable, Identifiable {
    case asset = "Asset"
    case neutral = "Neutral"
    case liability = "Liability"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .asset: return "arrow.up.circle.fill"
        case .neutral: return "minus.circle.fill"
        case .liability: return "arrow.down.circle.fill"
        }
    }
}

enum BillPaymentState: String, CaseIterable, Codable, Identifiable {
    case paid = "Paid"
    case dueSoon = "Due soon"
    case upcoming = "Upcoming"
    case overdue = "Overdue"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .paid: return "checkmark.circle.fill"
        case .dueSoon: return "clock.badge.exclamationmark.fill"
        case .upcoming: return "calendar.circle.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        }
    }
}

enum RuleActivityState: String, CaseIterable, Codable, Identifiable {
    case active = "Active"
    case quiet = "Quiet"
    case dormant = "Dormant"
    case disabled = "Disabled"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .active: return "sparkles"
        case .quiet: return "moon.zzz.fill"
        case .dormant: return "circle.dashed"
        case .disabled: return "pause.circle.fill"
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
    var isPrimary: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case institution
        case balance
        case kind
        case isPrimary
    }

    init(
        id: UUID = UUID(),
        name: String,
        institution: String,
        balance: Decimal,
        kind: AccountKind,
        isPrimary: Bool = false
    ) {
        self.id = id
        self.name = name
        self.institution = institution
        self.balance = balance
        self.kind = kind
        self.isPrimary = isPrimary
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        institution = try container.decode(String.self, forKey: .institution)
        balance = try container.decode(Decimal.self, forKey: .balance)
        kind = try container.decode(AccountKind.self, forKey: .kind)
        isPrimary = try container.decodeIfPresent(Bool.self, forKey: .isPrimary) ?? false
    }

    var balanceState: AccountBalanceState {
        if kind == .creditCard || balance < 0 {
            return .liability
        }
        if balance == 0 {
            return .neutral
        }
        return .asset
    }

    var summaryLabel: String {
        [institution.trimmingCharacters(in: .whitespacesAndNewlines), kind.rawValue]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
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

    func paymentState(referenceDate: Date = .now, ledger: LocalFinanceLedger? = nil) -> BillPaymentState {
        guard lastPaidAt == nil else {
            return .paid
        }

        let dueDate: Date
        if let ledger {
            dueDate = ledger.dueDate(for: self, referenceDate: referenceDate)
        } else {
            let calendar = Calendar.autoupdatingCurrent
            let components = calendar.dateComponents([.year, .month], from: referenceDate)
            let day = min(max(dueDay, 1), 28)
            dueDate = calendar.date(from: DateComponents(year: components.year, month: components.month, day: day)) ?? referenceDate
        }

        let calendar = Calendar.autoupdatingCurrent
        let startOfToday = calendar.startOfDay(for: referenceDate)
        if dueDate < startOfToday {
            return .overdue
        }

        if let warningDate = calendar.date(byAdding: .day, value: 3, to: startOfToday), dueDate <= warningDate {
            return .dueSoon
        }

        return .upcoming
    }
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
    var isEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case merchantKeyword
        case category
        case note
        case isEnabled
    }

    init(
        id: UUID = UUID(),
        merchantKeyword: String,
        category: ExpenseCategory,
        note: String? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.merchantKeyword = merchantKeyword
        self.category = category
        self.note = note
        self.isEnabled = isEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        merchantKeyword = try container.decode(String.self, forKey: .merchantKeyword)
        category = try container.decode(ExpenseCategory.self, forKey: .category)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
    }
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
        let shouldMarkPrimary = primaryAccount == nil
        accounts.insert(
            AccountRecord(
                id: id,
                name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                institution: draft.institution.trimmingCharacters(in: .whitespacesAndNewlines),
                balance: draft.balance,
                kind: draft.kind,
                isPrimary: shouldMarkPrimary
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
                note: draft.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : draft.note.trimmingCharacters(in: .whitespacesAndNewlines),
                isEnabled: true
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

    var primaryAccount: AccountRecord? {
        accounts.first(where: { $0.isPrimary }) ?? accounts.first
    }

    func accountBalanceState(for account: AccountRecord) -> AccountBalanceState {
        account.balanceState
    }

    func liquidAccountBalance() -> Decimal {
        accounts
            .filter { $0.kind != .creditCard && $0.balance > 0 }
            .reduce(Decimal.zero) { $0 + $1.balance }
    }

    func creditExposure() -> Decimal {
        accounts
            .filter { $0.kind == .creditCard || $0.balance < 0 }
            .reduce(Decimal.zero) { $0 + ($1.balance < 0 ? -$1.balance : $1.balance) }
    }

    func billStatus(for bill: BillRecord, referenceDate: Date = .now) -> BillPaymentState {
        bill.paymentState(referenceDate: referenceDate, ledger: self)
    }

    func ruleActivityState(for rule: RuleRecord) -> RuleActivityState {
        guard rule.isEnabled else { return .disabled }
        let matches = matchingExpensesCount(for: rule)
        if matches == 0 { return .dormant }
        if matches < 3 { return .quiet }
        return .active
    }

    mutating func deleteAccount(_ accountID: UUID, date: Date = .now) {
        accounts.removeAll { $0.id == accountID }
        updatedAt = date
    }

    mutating func setPrimaryAccount(_ accountID: UUID, date: Date = .now) {
        guard accounts.contains(where: { $0.id == accountID }) else { return }
        for index in accounts.indices {
            accounts[index].isPrimary = accounts[index].id == accountID
        }
        updatedAt = date
    }

    mutating func deleteBill(_ billID: UUID, date: Date = .now) {
        bills.removeAll { $0.id == billID }
        updatedAt = date
    }

    mutating func toggleBillAutopay(_ billID: UUID, date: Date = .now) {
        guard let index = bills.firstIndex(where: { $0.id == billID }) else { return }
        bills[index].autopay.toggle()
        updatedAt = date
    }

    mutating func deleteRule(_ ruleID: UUID, date: Date = .now) {
        rules.removeAll { $0.id == ruleID }
        updatedAt = date
    }

    mutating func toggleRuleEnabled(_ ruleID: UUID, date: Date = .now) {
        guard let index = rules.firstIndex(where: { $0.id == ruleID }) else { return }
        rules[index].isEnabled.toggle()
        updatedAt = date
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
        guard rule.isEnabled else { return 0 }
        let keyword = rule.merchantKeyword.lowercased()
        return expenses.filter { $0.merchant.lowercased().contains(keyword) }.count
    }

    func inferredCategory(for merchant: String) -> ExpenseCategory? {
        let normalized = merchant.lowercased()
        return rules.first(where: { $0.isEnabled && normalized.contains($0.merchantKeyword.lowercased()) })?.category
    }
}

private extension ExpenseRecord {
    func mapExpenseItem() -> ExpenseItem {
        ExpenseItem(id: id, title: merchant, category: category.rawValue, amount: amount, date: date)
    }
}
