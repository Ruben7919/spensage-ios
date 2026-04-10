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

    var localizedTitle: String {
        rawValue.appLocalized
    }

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

enum ExpenseEntrySource: String, CaseIterable, Codable, Identifiable {
    case manual = "Manual"
    case email = "Email import"
    case receiptScan = "Receipt scan"
    case subscriptionAutomation = "Subscription automation"

    var id: String { rawValue }

    var localizedTitle: String {
        rawValue.appLocalized
    }

    var systemImage: String {
        switch self {
        case .manual:
            return "keyboard"
        case .email:
            return "envelope.fill"
        case .receiptScan:
            return "camera.viewfinder"
        case .subscriptionAutomation:
            return "repeat.circle.fill"
        }
    }
}

enum RecurringCadence: String, CaseIterable, Codable, Identifiable {
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: String { rawValue }

    var localizedTitle: String {
        rawValue.appLocalized
    }
}

struct RecurringExpensePlan: Codable, Equatable {
    var cadence: RecurringCadence
    var renewalDate: Date
    var autoRecord: Bool

    init(
        cadence: RecurringCadence = .monthly,
        renewalDate: Date = .now,
        autoRecord: Bool = true
    ) {
        self.cadence = cadence
        self.renewalDate = renewalDate
        self.autoRecord = autoRecord
    }
}

enum AccountKind: String, CaseIterable, Codable, Identifiable {
    case checking = "Checking"
    case savings = "Savings"
    case cash = "Cash"
    case creditCard = "Credit Card"
    case investment = "Investment"

    var id: String { rawValue }

    var localizedTitle: String {
        rawValue.appLocalized
    }

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

    var localizedTitle: String {
        rawValue.appLocalized
    }

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

    var localizedTitle: String {
        rawValue.appLocalized
    }

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

    var localizedTitle: String {
        rawValue.appLocalized
    }

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
    var cloudID: String?
    var name: String
    var institution: String
    var balance: Decimal
    var kind: AccountKind
    var isPrimary: Bool
    var needsCloudUpdate: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case cloudID
        case name
        case institution
        case balance
        case kind
        case isPrimary
        case needsCloudUpdate
    }

    init(
        id: UUID = UUID(),
        cloudID: String? = nil,
        name: String,
        institution: String,
        balance: Decimal,
        kind: AccountKind,
        isPrimary: Bool = false,
        needsCloudUpdate: Bool = false
    ) {
        self.id = id
        self.cloudID = cloudID
        self.name = name
        self.institution = institution
        self.balance = balance
        self.kind = kind
        self.isPrimary = isPrimary
        self.needsCloudUpdate = needsCloudUpdate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        cloudID = try container.decodeIfPresent(String.self, forKey: .cloudID)
        name = try container.decode(String.self, forKey: .name)
        institution = try container.decode(String.self, forKey: .institution)
        balance = try container.decode(Decimal.self, forKey: .balance)
        kind = try container.decode(AccountKind.self, forKey: .kind)
        isPrimary = try container.decodeIfPresent(Bool.self, forKey: .isPrimary) ?? false
        needsCloudUpdate = try container.decodeIfPresent(Bool.self, forKey: .needsCloudUpdate) ?? false
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
        [institution.trimmingCharacters(in: .whitespacesAndNewlines), kind.localizedTitle]
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
    var cadence: RecurringCadence
    var renewalMonth: Int?

    init(
        title: String = "",
        amount: Decimal = 0,
        dueDay: Int = 1,
        category: ExpenseCategory = .bills,
        autopay: Bool = false,
        cadence: RecurringCadence = .monthly,
        renewalMonth: Int? = nil
    ) {
        self.title = title
        self.amount = amount
        self.dueDay = dueDay
        self.category = category
        self.autopay = autopay
        self.cadence = cadence
        self.renewalMonth = renewalMonth
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && amount > 0 && (1...31).contains(dueDay)
    }
}

struct BillRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var cloudID: String?
    var title: String
    var amount: Decimal
    var dueDay: Int
    var category: ExpenseCategory
    var autopay: Bool
    var lastPaidAt: Date?
    var cadence: RecurringCadence? = nil
    var renewalMonth: Int? = nil
    var needsCloudUpdate: Bool = false

    init(
        id: UUID = UUID(),
        cloudID: String? = nil,
        title: String,
        amount: Decimal,
        dueDay: Int,
        category: ExpenseCategory,
        autopay: Bool,
        lastPaidAt: Date?,
        cadence: RecurringCadence? = nil,
        renewalMonth: Int? = nil,
        needsCloudUpdate: Bool = false
    ) {
        self.id = id
        self.cloudID = cloudID
        self.title = title
        self.amount = amount
        self.dueDay = dueDay
        self.category = category
        self.autopay = autopay
        self.lastPaidAt = lastPaidAt
        self.cadence = cadence
        self.renewalMonth = renewalMonth
        self.needsCloudUpdate = needsCloudUpdate
    }

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
    var cloudID: String?
    var merchantKeyword: String
    var category: ExpenseCategory
    var note: String?
    var isEnabled: Bool
    var needsCloudUpdate: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case cloudID
        case merchantKeyword
        case category
        case note
        case isEnabled
        case needsCloudUpdate
    }

    init(
        id: UUID = UUID(),
        cloudID: String? = nil,
        merchantKeyword: String,
        category: ExpenseCategory,
        note: String? = nil,
        isEnabled: Bool = true,
        needsCloudUpdate: Bool = false
    ) {
        self.id = id
        self.cloudID = cloudID
        self.merchantKeyword = merchantKeyword
        self.category = category
        self.note = note
        self.isEnabled = isEnabled
        self.needsCloudUpdate = needsCloudUpdate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        cloudID = try container.decodeIfPresent(String.self, forKey: .cloudID)
        merchantKeyword = try container.decode(String.self, forKey: .merchantKeyword)
        category = try container.decode(ExpenseCategory.self, forKey: .category)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        needsCloudUpdate = try container.decodeIfPresent(Bool.self, forKey: .needsCloudUpdate) ?? false
    }
}

struct ProfileRecord: Codable, Equatable {
    var fullName: String
    var householdName: String
    var email: String
    var countryCode: String
    var marketingOptIn: Bool

    static let `default` = ProfileRecord(
        fullName: "Usuario MichiFinanzas",
        householdName: "Mi hogar",
        email: "hello@michifinanzas.local",
        countryCode: "US",
        marketingOptIn: false
    )

    var normalizedFullName: String? {
        let trimmed = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != Self.default.fullName else { return nil }
        return trimmed
    }

    var normalizedEmail: String? {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != Self.default.email else { return nil }
        return trimmed
    }

    func needsWelcomeProfile(for sessionEmail: String?) -> Bool {
        guard let sessionEmail, !sessionEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return normalizedFullName == nil
        }

        return normalizedFullName == nil || normalizedEmail != sessionEmail
    }
}

struct ExpenseDraft: Equatable {
    var merchant: String
    var amount: Decimal
    var category: ExpenseCategory
    var date: Date
    var locationLabel: String
    var note: String
    var source: ExpenseEntrySource
    var sourceText: String
    var recurringPlan: RecurringExpensePlan?

    init(
        merchant: String = "",
        amount: Decimal = 0,
        category: ExpenseCategory = .groceries,
        date: Date = .now,
        locationLabel: String = "",
        note: String = "",
        source: ExpenseEntrySource = .manual,
        sourceText: String = "",
        recurringPlan: RecurringExpensePlan? = nil
    ) {
        self.merchant = merchant
        self.amount = amount
        self.category = category
        self.date = date
        self.locationLabel = locationLabel
        self.note = note
        self.source = source
        self.sourceText = sourceText
        self.recurringPlan = recurringPlan
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
            locationLabel: locationLabel.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            source: source,
            sourceText: sourceText.trimmingCharacters(in: .whitespacesAndNewlines),
            recurringPlan: recurringPlan
        )
    }
}

struct ExpenseRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var cloudID: String?
    var merchant: String
    var category: ExpenseCategory
    var amount: Decimal
    var date: Date
    var locationLabel: String?
    var note: String?
    var source: ExpenseEntrySource? = nil
    var sourceText: String? = nil
    var recurringPlan: RecurringExpensePlan? = nil
    var needsCloudUpdate: Bool = false

    init(
        id: UUID = UUID(),
        cloudID: String? = nil,
        merchant: String,
        category: ExpenseCategory,
        amount: Decimal,
        date: Date,
        locationLabel: String? = nil,
        note: String? = nil,
        source: ExpenseEntrySource? = nil,
        sourceText: String? = nil,
        recurringPlan: RecurringExpensePlan? = nil,
        needsCloudUpdate: Bool = false
    ) {
        self.id = id
        self.cloudID = cloudID
        self.merchant = merchant
        self.category = category
        self.amount = amount
        self.date = date
        self.locationLabel = locationLabel
        self.note = note
        self.source = source
        self.sourceText = sourceText
        self.recurringPlan = recurringPlan
        self.needsCloudUpdate = needsCloudUpdate
    }
}

enum PendingCloudDeletionKind: String, Codable, Equatable {
    case expense
    case account
    case bill
    case rule
}

struct PendingCloudDeletion: Codable, Equatable, Identifiable {
    var id: String { "\(kind.rawValue):\(cloudID)" }
    let kind: PendingCloudDeletionKind
    let cloudID: String
}

struct CategoryBreakdown: Identifiable, Codable, Equatable {
    var id: String { category.rawValue }
    let category: ExpenseCategory
    let total: Decimal
    let count: Int
}

struct MerchantAutofillSuggestion: Identifiable, Equatable {
    let id: String
    let merchant: String
    let category: ExpenseCategory
    let lastAmount: Decimal
    let averageAmount: Decimal
    let totalAmount: Decimal
    let frequency: Int
    let latestDate: Date
    let lastNote: String?

    var frequencyLabel: String {
        if frequency == 1 {
            return AppLocalization.localized("%d time", arguments: frequency)
        }
        return AppLocalization.localized("%d times", arguments: frequency)
    }
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
    var pendingCloudDeletions: [PendingCloudDeletion]
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case monthlyIncome
        case monthlyBudget
        case expenses
        case accounts
        case bills
        case rules
        case profile
        case pendingCloudDeletions
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
        pendingCloudDeletions: [PendingCloudDeletion] = [],
        updatedAt: Date
    ) {
        self.monthlyIncome = monthlyIncome
        self.monthlyBudget = monthlyBudget
        self.expenses = expenses
        self.accounts = accounts
        self.bills = bills
        self.rules = rules
        self.profile = profile
        self.pendingCloudDeletions = pendingCloudDeletions
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
        pendingCloudDeletions = try container.decodeIfPresent([PendingCloudDeletion].self, forKey: .pendingCloudDeletions) ?? []
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

    mutating func appendExpense(_ draft: ExpenseDraft, id: UUID = UUID(), cloudID: String? = nil, date: Date = .now) {
        let normalized = draft.normalized()
        expenses.insert(
            ExpenseRecord(
                id: id,
                cloudID: cloudID,
                merchant: normalized.merchant,
                category: normalized.category,
                amount: normalized.amount,
                date: normalized.date == .distantPast ? date : normalized.date,
                locationLabel: normalized.locationLabel.isEmpty ? nil : normalized.locationLabel,
                note: normalized.note.isEmpty ? nil : normalized.note,
                source: normalized.source,
                sourceText: normalized.sourceText.isEmpty ? nil : normalized.sourceText,
                recurringPlan: normalized.recurringPlan,
                needsCloudUpdate: false
            ),
            at: 0
        )
        upsertTrackedSubscription(from: normalized, referenceDate: normalized.date == .distantPast ? date : normalized.date)
        updatedAt = date
    }

    mutating func appendAccount(_ draft: AccountDraft, id: UUID = UUID(), cloudID: String? = nil, date: Date = .now) {
        let shouldMarkPrimary = primaryAccount == nil
        accounts.insert(
            AccountRecord(
                id: id,
                cloudID: cloudID,
                name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                institution: draft.institution.trimmingCharacters(in: .whitespacesAndNewlines),
                balance: draft.balance,
                kind: draft.kind,
                isPrimary: shouldMarkPrimary,
                needsCloudUpdate: false
            ),
            at: 0
        )
        updatedAt = date
    }

    mutating func appendBill(_ draft: BillDraft, id: UUID = UUID(), cloudID: String? = nil, date: Date = .now) {
        bills.insert(
            BillRecord(
                id: id,
                cloudID: cloudID,
                title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                amount: draft.amount,
                dueDay: draft.dueDay,
                category: draft.category,
                autopay: draft.autopay,
                lastPaidAt: nil,
                cadence: draft.cadence,
                renewalMonth: draft.renewalMonth,
                needsCloudUpdate: false
            ),
            at: 0
        )
        updatedAt = date
    }

    mutating func appendRule(_ draft: RuleDraft, id: UUID = UUID(), cloudID: String? = nil, date: Date = .now) {
        rules.insert(
            RuleRecord(
                id: id,
                cloudID: cloudID,
                merchantKeyword: draft.merchantKeyword.trimmingCharacters(in: .whitespacesAndNewlines),
                category: draft.category,
                note: draft.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : draft.note.trimmingCharacters(in: .whitespacesAndNewlines),
                isEnabled: true,
                needsCloudUpdate: false
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
                locationLabel: "",
                note: bills[index].autopay ? "Autopay bill".appLocalized : "Bill payment".appLocalized,
                source: bills[index].autopay ? .subscriptionAutomation : .manual,
                recurringPlan: RecurringExpensePlan(
                    cadence: bills[index].cadence ?? .monthly,
                    renewalDate: dueDate(for: bills[index], referenceDate: date),
                    autoRecord: bills[index].autopay
                )
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

    var hasPendingCloudSync: Bool {
        expenses.contains(where: { $0.cloudID == nil })
            || expenses.contains(where: { $0.needsCloudUpdate })
            || accounts.contains(where: { $0.cloudID == nil })
            || accounts.contains(where: { $0.needsCloudUpdate })
            || bills.contains(where: { $0.cloudID == nil })
            || bills.contains(where: { $0.needsCloudUpdate })
            || rules.contains(where: { $0.cloudID == nil })
            || rules.contains(where: { $0.needsCloudUpdate })
            || !pendingCloudDeletions.isEmpty
    }

    var hasMeaningfulContent: Bool {
        !expenses.isEmpty
            || !accounts.isEmpty
            || !bills.isEmpty
            || !rules.isEmpty
            || monthlyIncome > 0
            || monthlyBudget > 0
            || profile != .default
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

    mutating func updateExpense(_ expenseID: UUID, draft: ExpenseDraft, date: Date = .now) {
        guard let index = expenses.firstIndex(where: { $0.id == expenseID }) else { return }
        let normalized = draft.normalized()
        expenses[index].merchant = normalized.merchant
        expenses[index].amount = normalized.amount
        expenses[index].category = normalized.category
        expenses[index].date = normalized.date
        expenses[index].locationLabel = normalized.locationLabel.isEmpty ? nil : normalized.locationLabel
        expenses[index].note = normalized.note.isEmpty ? nil : normalized.note
        expenses[index].source = normalized.source
        expenses[index].sourceText = normalized.sourceText.isEmpty ? nil : normalized.sourceText
        expenses[index].recurringPlan = normalized.recurringPlan
        if expenses[index].cloudID != nil {
            expenses[index].needsCloudUpdate = true
        }
        updatedAt = date
    }

    mutating func updateAccount(_ accountID: UUID, draft: AccountDraft, date: Date = .now) {
        guard let index = accounts.firstIndex(where: { $0.id == accountID }) else { return }
        accounts[index].name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        accounts[index].institution = draft.institution.trimmingCharacters(in: .whitespacesAndNewlines)
        accounts[index].balance = draft.balance
        accounts[index].kind = draft.kind
        if accounts[index].cloudID != nil {
            accounts[index].needsCloudUpdate = true
        }
        updatedAt = date
    }

    mutating func updateBill(_ billID: UUID, draft: BillDraft, date: Date = .now) {
        guard let index = bills.firstIndex(where: { $0.id == billID }) else { return }
        bills[index].title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        bills[index].amount = draft.amount
        bills[index].dueDay = draft.dueDay
        bills[index].category = draft.category
        bills[index].autopay = draft.autopay
        bills[index].cadence = draft.cadence
        bills[index].renewalMonth = draft.renewalMonth
        if bills[index].cloudID != nil {
            bills[index].needsCloudUpdate = true
        }
        updatedAt = date
    }

    mutating func updateRule(_ ruleID: UUID, draft: RuleDraft, date: Date = .now) {
        guard let index = rules.firstIndex(where: { $0.id == ruleID }) else { return }
        rules[index].merchantKeyword = draft.merchantKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        rules[index].category = draft.category
        rules[index].note = draft.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
        if rules[index].cloudID != nil {
            rules[index].needsCloudUpdate = true
        }
        updatedAt = date
    }

    mutating func deleteExpense(_ expenseID: UUID, date: Date = .now) {
        if let record = expenses.first(where: { $0.id == expenseID }), let cloudID = record.cloudID {
            pendingCloudDeletions.append(PendingCloudDeletion(kind: .expense, cloudID: cloudID))
        }
        expenses.removeAll { $0.id == expenseID }
        updatedAt = date
    }

    mutating func deleteAccount(_ accountID: UUID, date: Date = .now) {
        if let record = accounts.first(where: { $0.id == accountID }), let cloudID = record.cloudID {
            pendingCloudDeletions.append(PendingCloudDeletion(kind: .account, cloudID: cloudID))
        }
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
        if let record = bills.first(where: { $0.id == billID }), let cloudID = record.cloudID {
            pendingCloudDeletions.append(PendingCloudDeletion(kind: .bill, cloudID: cloudID))
        }
        bills.removeAll { $0.id == billID }
        updatedAt = date
    }

    mutating func toggleBillAutopay(_ billID: UUID, date: Date = .now) {
        guard let index = bills.firstIndex(where: { $0.id == billID }) else { return }
        bills[index].autopay.toggle()
        if bills[index].cloudID != nil {
            bills[index].needsCloudUpdate = true
        }
        updatedAt = date
    }

    mutating func deleteRule(_ ruleID: UUID, date: Date = .now) {
        if let record = rules.first(where: { $0.id == ruleID }), let cloudID = record.cloudID {
            pendingCloudDeletions.append(PendingCloudDeletion(kind: .rule, cloudID: cloudID))
        }
        rules.removeAll { $0.id == ruleID }
        updatedAt = date
    }

    mutating func toggleRuleEnabled(_ ruleID: UUID, date: Date = .now) {
        guard let index = rules.firstIndex(where: { $0.id == ruleID }) else { return }
        rules[index].isEnabled.toggle()
        if rules[index].cloudID != nil {
            rules[index].needsCloudUpdate = true
        }
        updatedAt = date
    }

    mutating func clearPendingCloudDeletion(kind: PendingCloudDeletionKind, cloudID: String) {
        pendingCloudDeletions.removeAll { $0.kind == kind && $0.cloudID == cloudID }
    }

    func upcomingBills(referenceDate: Date = .now) -> [BillRecord] {
        bills.sorted {
            dueDate(for: $0, referenceDate: referenceDate) < dueDate(for: $1, referenceDate: referenceDate)
        }
    }

    func dueDate(for bill: BillRecord, referenceDate: Date = .now) -> Date {
        let calendar = Calendar.autoupdatingCurrent
        let day = min(max(bill.dueDay, 1), 28)
        switch bill.cadence ?? .monthly {
        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: referenceDate)
            let currentMonthDate = calendar.date(from: DateComponents(year: components.year, month: components.month, day: day)) ?? referenceDate
            if currentMonthDate >= calendar.startOfDay(for: referenceDate) {
                return currentMonthDate
            }
            return calendar.date(byAdding: .month, value: 1, to: currentMonthDate) ?? currentMonthDate
        case .yearly:
            let components = calendar.dateComponents([.year], from: referenceDate)
            let month = min(max(bill.renewalMonth ?? calendar.component(.month, from: referenceDate), 1), 12)
            let currentYearDate = calendar.date(from: DateComponents(year: components.year, month: month, day: day)) ?? referenceDate
            if currentYearDate >= calendar.startOfDay(for: referenceDate) {
                return currentYearDate
            }
            return calendar.date(byAdding: .year, value: 1, to: currentYearDate) ?? currentYearDate
        }
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

    func merchantSuggestions(limit: Int = 6) -> [MerchantAutofillSuggestion] {
        let grouped = Dictionary(grouping: expenses) { normalizedMerchantKey(for: $0.merchant) }

        return grouped
            .compactMap { key, records in
                merchantSuggestion(from: records, key: key)
            }
            .sorted { lhs, rhs in
                if lhs.frequency != rhs.frequency {
                    return lhs.frequency > rhs.frequency
                }
                if lhs.totalAmount != rhs.totalAmount {
                    return lhs.totalAmount > rhs.totalAmount
                }
                return lhs.latestDate > rhs.latestDate
            }
            .prefix(limit)
            .map { $0 }
    }

    func merchantSuggestions(matching query: String, limit: Int = 4) -> [MerchantAutofillSuggestion] {
        let normalizedQuery = normalizedMerchantKey(for: query)
        guard !normalizedQuery.isEmpty else { return merchantSuggestions(limit: limit) }

        return merchantSuggestions(limit: max(limit * 2, 8))
            .filter { suggestion in
                suggestion.id.contains(normalizedQuery) || normalizedMerchantKey(for: suggestion.merchant).contains(normalizedQuery)
            }
            .prefix(limit)
            .map { $0 }
    }

    func autofillSuggestion(for merchant: String) -> MerchantAutofillSuggestion? {
        let normalizedQuery = normalizedMerchantKey(for: merchant)
        guard !normalizedQuery.isEmpty else { return nil }

        if let exact = merchantSuggestions(limit: 24).first(where: { $0.id == normalizedQuery }) {
            return exact
        }

        return merchantSuggestions(matching: merchant, limit: 1).first
    }

    func discretionaryHotspots(limit: Int = 3) -> [MerchantAutofillSuggestion] {
        let watchedCategories: Set<ExpenseCategory> = [.dining, .coffee, .shopping]
        return merchantSuggestions(limit: 24)
            .filter { suggestion in
                watchedCategories.contains(suggestion.category) && suggestion.frequency >= 2
            }
            .sorted { lhs, rhs in
                if lhs.totalAmount != rhs.totalAmount {
                    return lhs.totalAmount > rhs.totalAmount
                }
                return lhs.frequency > rhs.frequency
            }
            .prefix(limit)
            .map { $0 }
    }

    func exactMerchantMatch(for merchant: String) -> MerchantAutofillSuggestion? {
        let normalizedQuery = normalizedMerchantKey(for: merchant)
        guard !normalizedQuery.isEmpty else { return nil }
        return merchantSuggestions(limit: 24).first(where: { $0.id == normalizedQuery })
    }

    private func merchantSuggestion(from records: [ExpenseRecord], key: String) -> MerchantAutofillSuggestion? {
        guard !key.isEmpty else { return nil }
        let sorted = records.sorted { $0.date > $1.date }
        guard let latest = sorted.first else { return nil }

        let category = Dictionary(grouping: sorted, by: \.category)
            .max { lhs, rhs in
                if lhs.value.count != rhs.value.count {
                    return lhs.value.count < rhs.value.count
                }
                let lhsTotal = lhs.value.reduce(Decimal.zero) { $0 + $1.amount }
                let rhsTotal = rhs.value.reduce(Decimal.zero) { $0 + $1.amount }
                return lhsTotal < rhsTotal
            }?
            .key ?? latest.category

        let totalAmount = sorted.reduce(Decimal.zero) { $0 + $1.amount }
        let averageAmount = totalAmount / Decimal(max(sorted.count, 1))

        return MerchantAutofillSuggestion(
            id: key,
            merchant: latest.merchant,
            category: inferredCategory(for: latest.merchant) ?? category,
            lastAmount: latest.amount,
            averageAmount: averageAmount,
            totalAmount: totalAmount,
            frequency: sorted.count,
            latestDate: latest.date,
            lastNote: latest.note
        )
    }

    private func normalizedMerchantKey(for merchant: String) -> String {
        merchant
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    mutating func materializeScheduledAutopayBills(referenceDate: Date = .now) {
        let calendar = Calendar.autoupdatingCurrent
        let startOfToday = calendar.startOfDay(for: referenceDate)

        for index in bills.indices {
            guard bills[index].autopay else { continue }

            let cycleDate = currentCycleDueDate(for: bills[index], referenceDate: referenceDate)
            guard cycleDate <= startOfToday || calendar.isDate(cycleDate, inSameDayAs: startOfToday) else { continue }

            if hasRecordedExpense(for: bills[index], inSameCycleAs: cycleDate, calendar: calendar) {
                if !didRecord(bills[index].lastPaidAt, inSameCycleAs: cycleDate, cadence: bills[index].cadence ?? .monthly, calendar: calendar) {
                    bills[index].lastPaidAt = cycleDate
                    updatedAt = referenceDate
                }
                continue
            }

            appendExpense(
                ExpenseDraft(
                    merchant: bills[index].title,
                    amount: bills[index].amount,
                    category: bills[index].category,
                    date: cycleDate,
                    note: "Registro automático de suscripción".appLocalized,
                    source: .subscriptionAutomation,
                    recurringPlan: RecurringExpensePlan(
                        cadence: bills[index].cadence ?? .monthly,
                        renewalDate: cycleDate,
                        autoRecord: true
                    )
                ),
                date: referenceDate
            )
            bills[index].lastPaidAt = cycleDate
            updatedAt = referenceDate
        }
    }

    private mutating func upsertTrackedSubscription(from draft: ExpenseDraft, referenceDate: Date) {
        guard draft.category == .subscriptions, let recurringPlan = draft.recurringPlan else { return }

        let calendar = Calendar.autoupdatingCurrent
        let dueDay = min(max(calendar.component(.day, from: recurringPlan.renewalDate), 1), 28)
        let renewalMonth = recurringPlan.cadence == .yearly ? calendar.component(.month, from: recurringPlan.renewalDate) : nil
        let normalizedMerchant = normalizedMerchantKey(for: draft.merchant)

        if let index = bills.firstIndex(where: {
            $0.category == .subscriptions && normalizedMerchantKey(for: $0.title) == normalizedMerchant
        }) {
            bills[index].title = draft.merchant
            bills[index].amount = draft.amount
            bills[index].dueDay = dueDay
            bills[index].category = .subscriptions
            bills[index].autopay = recurringPlan.autoRecord
            bills[index].lastPaidAt = referenceDate
            bills[index].cadence = recurringPlan.cadence
            bills[index].renewalMonth = renewalMonth
        } else {
            bills.insert(
                BillRecord(
                    id: UUID(),
                    cloudID: nil,
                    title: draft.merchant,
                    amount: draft.amount,
                    dueDay: dueDay,
                    category: .subscriptions,
                    autopay: recurringPlan.autoRecord,
                    lastPaidAt: referenceDate,
                    cadence: recurringPlan.cadence,
                    renewalMonth: renewalMonth
                ),
                at: 0
            )
        }
    }

    private func currentCycleDueDate(for bill: BillRecord, referenceDate: Date) -> Date {
        let calendar = Calendar.autoupdatingCurrent
        let day = min(max(bill.dueDay, 1), 28)

        switch bill.cadence ?? .monthly {
        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: referenceDate)
            return calendar.date(from: DateComponents(year: components.year, month: components.month, day: day)) ?? referenceDate
        case .yearly:
            let year = calendar.component(.year, from: referenceDate)
            let month = min(max(bill.renewalMonth ?? calendar.component(.month, from: referenceDate), 1), 12)
            return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? referenceDate
        }
    }

    private func hasRecordedExpense(for bill: BillRecord, inSameCycleAs cycleDate: Date, calendar: Calendar) -> Bool {
        expenses.contains { expense in
            normalizedMerchantKey(for: expense.merchant) == normalizedMerchantKey(for: bill.title)
                && expense.category == bill.category
                && didRecord(expense.date, inSameCycleAs: cycleDate, cadence: bill.cadence ?? .monthly, calendar: calendar)
        }
    }

    private func didRecord(_ date: Date?, inSameCycleAs cycleDate: Date, cadence: RecurringCadence, calendar: Calendar) -> Bool {
        guard let date else { return false }

        switch cadence {
        case .monthly:
            return calendar.isDate(date, equalTo: cycleDate, toGranularity: .month)
        case .yearly:
            return calendar.isDate(date, equalTo: cycleDate, toGranularity: .year)
                && calendar.component(.month, from: date) == calendar.component(.month, from: cycleDate)
        }
    }
}

private extension ExpenseRecord {
    func mapExpenseItem() -> ExpenseItem {
        ExpenseItem(id: id, title: merchant, category: category.rawValue, amount: amount, date: date)
    }
}
