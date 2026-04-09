import Foundation

@MainActor
protocol FinanceDashboardStoring {
    func loadDashboardState(for session: SessionState, spaceID: String?) async -> FinanceDashboardState
    func loadLedger(for session: SessionState, spaceID: String?) async -> LocalFinanceLedger
    func saveExpense(_ draft: ExpenseDraft, for session: SessionState, spaceID: String?) async
    func updateExpense(_ expenseID: UUID, draft: ExpenseDraft, for session: SessionState, spaceID: String?) async
    func deleteExpense(_ expenseID: UUID, for session: SessionState, spaceID: String?) async
    func saveBudget(monthlyIncome: Decimal, monthlyBudget: Decimal, for session: SessionState, spaceID: String?) async
    func saveAccount(_ draft: AccountDraft, for session: SessionState, spaceID: String?) async
    func updateAccount(_ accountID: UUID, draft: AccountDraft, for session: SessionState, spaceID: String?) async
    func deleteAccount(_ accountID: UUID, for session: SessionState, spaceID: String?) async
    func setPrimaryAccount(_ accountID: UUID, for session: SessionState, spaceID: String?) async
    func saveBill(_ draft: BillDraft, for session: SessionState, spaceID: String?) async
    func updateBill(_ billID: UUID, draft: BillDraft, for session: SessionState, spaceID: String?) async
    func deleteBill(_ billID: UUID, for session: SessionState, spaceID: String?) async
    func toggleBillAutopay(_ billID: UUID, for session: SessionState, spaceID: String?) async
    func saveRule(_ draft: RuleDraft, for session: SessionState, spaceID: String?) async
    func updateRule(_ ruleID: UUID, draft: RuleDraft, for session: SessionState, spaceID: String?) async
    func deleteRule(_ ruleID: UUID, for session: SessionState, spaceID: String?) async
    func toggleRuleEnabled(_ ruleID: UUID, for session: SessionState, spaceID: String?) async
    func markBillPaid(_ billID: UUID, for session: SessionState, spaceID: String?) async
    func importExpenses(_ drafts: [ExpenseDraft], for session: SessionState, spaceID: String?) async
    func saveProfile(_ profile: ProfileRecord, for session: SessionState, spaceID: String?) async
}

@MainActor
final class LocalFinanceStore: FinanceDashboardStoring {
    private let defaults: UserDefaults
    private let storageKeyPrefix = "spendsage.local.finance.ledger"
    private let legacyStorageKey = "spendsage.local.finance.ledger"
    private let seedLedger: LocalFinanceLedger
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        defaults: UserDefaults = .standard,
        seedLedger: LocalFinanceLedger = PreviewFinanceData.seedLedger
    ) {
        self.defaults = defaults
        self.seedLedger = seedLedger

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func loadDashboardState(for session: SessionState, spaceID: String?) async -> FinanceDashboardState {
        currentLedger(for: session, spaceID: spaceID).dashboardState()
    }

    func loadLedger(for session: SessionState, spaceID: String?) async -> LocalFinanceLedger {
        currentLedger(for: session, spaceID: spaceID)
    }

    func saveExpense(_ draft: ExpenseDraft, for session: SessionState, spaceID: String?) async {
        var ledger = currentLedger(for: session, spaceID: spaceID)
        ledger.appendExpense(draft)
        saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func updateExpense(_ expenseID: UUID, draft: ExpenseDraft, for session: SessionState, spaceID: String?) async {
        var ledger = currentLedger(for: session, spaceID: spaceID)
        ledger.updateExpense(expenseID, draft: draft)
        saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func deleteExpense(_ expenseID: UUID, for session: SessionState, spaceID: String?) async {
        var ledger = currentLedger(for: session, spaceID: spaceID)
        ledger.deleteExpense(expenseID)
        saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func saveBudget(monthlyIncome: Decimal, monthlyBudget: Decimal, for session: SessionState, spaceID: String?) async {
        var ledger = currentLedger(for: session, spaceID: spaceID)
        ledger.monthlyIncome = monthlyIncome
        ledger.monthlyBudget = monthlyBudget
        ledger.updatedAt = .now
        saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func saveAccount(_ draft: AccountDraft, for session: SessionState, spaceID: String?) async {
        var ledger = currentLedger(for: session, spaceID: spaceID)
        ledger.appendAccount(draft)
        saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func updateAccount(_ accountID: UUID, draft: AccountDraft, for session: SessionState, spaceID: String?) async {
        var ledger = currentLedger(for: session, spaceID: spaceID)
        ledger.updateAccount(accountID, draft: draft)
        saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func deleteAccount(_ accountID: UUID, for session: SessionState, spaceID: String?) async {
        var ledger = currentLedger(for: session, spaceID: spaceID)
        ledger.deleteAccount(accountID)
        saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func setPrimaryAccount(_ accountID: UUID, for session: SessionState, spaceID: String?) async {
        var ledger = currentLedger(for: session, spaceID: spaceID)
        ledger.setPrimaryAccount(accountID)
        saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func saveBill(_ draft: BillDraft, for session: SessionState, spaceID: String?) async {
        var ledger = currentLedger(for: session, spaceID: spaceID)
        ledger.appendBill(draft)
        saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func updateBill(_ billID: UUID, draft: BillDraft, for session: SessionState, spaceID: String?) async {
        var ledger = currentLedger(for: session, spaceID: spaceID)
        ledger.updateBill(billID, draft: draft)
        saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func deleteBill(_ billID: UUID, for session: SessionState, spaceID: String?) async {
        var ledger = currentLedger(for: session, spaceID: spaceID)
        ledger.deleteBill(billID)
        saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func toggleBillAutopay(_ billID: UUID, for session: SessionState, spaceID: String?) async {
        var ledger = currentLedger(for: session, spaceID: spaceID)
        ledger.toggleBillAutopay(billID)
        saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func saveRule(_ draft: RuleDraft, for session: SessionState, spaceID: String?) async {
        var ledger = currentLedger(for: session, spaceID: spaceID)
        ledger.appendRule(draft)
        saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func updateRule(_ ruleID: UUID, draft: RuleDraft, for session: SessionState, spaceID: String?) async {
        var ledger = currentLedger(for: session, spaceID: spaceID)
        ledger.updateRule(ruleID, draft: draft)
        saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func deleteRule(_ ruleID: UUID, for session: SessionState, spaceID: String?) async {
        var ledger = currentLedger(for: session, spaceID: spaceID)
        ledger.deleteRule(ruleID)
        saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func toggleRuleEnabled(_ ruleID: UUID, for session: SessionState, spaceID: String?) async {
        var ledger = currentLedger(for: session, spaceID: spaceID)
        ledger.toggleRuleEnabled(ruleID)
        saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func markBillPaid(_ billID: UUID, for session: SessionState, spaceID: String?) async {
        var ledger = currentLedger(for: session, spaceID: spaceID)
        ledger.markBillPaid(billID)
        saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func importExpenses(_ drafts: [ExpenseDraft], for session: SessionState, spaceID: String?) async {
        var ledger = currentLedger(for: session, spaceID: spaceID)
        ledger.importExpenses(drafts)
        saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func saveProfile(_ profile: ProfileRecord, for session: SessionState, spaceID: String?) async {
        var ledger = currentLedger(for: session, spaceID: spaceID)
        ledger.updateProfile(profile)
        saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func currentLedger(for session: SessionState, spaceID: String? = nil) -> LocalFinanceLedger {
        let storageKey = storageKey(for: session, spaceID: spaceID)
        let baseLedger: LocalFinanceLedger
        if let data = defaults.data(forKey: storageKey),
           let decodedLedger = try? decoder.decode(LocalFinanceLedger.self, from: data) {
            baseLedger = decodedLedger
        } else if let legacyData = defaults.data(forKey: legacyStorageKey),
                  let decodedLegacyLedger = try? decoder.decode(LocalFinanceLedger.self, from: legacyData) {
            baseLedger = decodedLegacyLedger
        } else {
            baseLedger = seedLedger
        }

        var normalizedLedger = baseLedger
        normalizedLedger.materializeScheduledAutopayBills()
        if normalizedLedger != baseLedger {
            saveLedger(normalizedLedger, for: session, spaceID: spaceID)
        }
        return normalizedLedger
    }

    func saveLedger(_ ledger: LocalFinanceLedger, for session: SessionState, spaceID: String? = nil) {
        guard let data = try? encoder.encode(ledger) else { return }
        defaults.set(data, forKey: storageKey(for: session, spaceID: spaceID))
    }

    func isSeedLedger(_ ledger: LocalFinanceLedger) -> Bool {
        ledger == seedLedger
    }

    private func storageKey(for session: SessionState, spaceID: String?) -> String {
        let trimmedSpace = spaceID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let normalizedSpace = trimmedSpace.isEmpty ? "personal" : trimmedSpace
        return "\(storageKeyPrefix).\(session.storageNamespace).\(normalizedSpace)"
    }
}

@MainActor
struct PreviewFinanceStore: FinanceDashboardStoring {
    func loadDashboardState(for session: SessionState, spaceID: String?) async -> FinanceDashboardState {
        PreviewFinanceData.seedLedger.dashboardState()
    }

    func loadLedger(for session: SessionState, spaceID: String?) async -> LocalFinanceLedger {
        PreviewFinanceData.seedLedger
    }

    func saveExpense(_ draft: ExpenseDraft, for session: SessionState, spaceID: String?) async {}

    func updateExpense(_ expenseID: UUID, draft: ExpenseDraft, for session: SessionState, spaceID: String?) async {}

    func deleteExpense(_ expenseID: UUID, for session: SessionState, spaceID: String?) async {}

    func saveBudget(monthlyIncome: Decimal, monthlyBudget: Decimal, for session: SessionState, spaceID: String?) async {}

    func saveAccount(_ draft: AccountDraft, for session: SessionState, spaceID: String?) async {}

    func updateAccount(_ accountID: UUID, draft: AccountDraft, for session: SessionState, spaceID: String?) async {}

    func deleteAccount(_ accountID: UUID, for session: SessionState, spaceID: String?) async {}

    func setPrimaryAccount(_ accountID: UUID, for session: SessionState, spaceID: String?) async {}

    func saveBill(_ draft: BillDraft, for session: SessionState, spaceID: String?) async {}

    func updateBill(_ billID: UUID, draft: BillDraft, for session: SessionState, spaceID: String?) async {}

    func deleteBill(_ billID: UUID, for session: SessionState, spaceID: String?) async {}

    func toggleBillAutopay(_ billID: UUID, for session: SessionState, spaceID: String?) async {}

    func saveRule(_ draft: RuleDraft, for session: SessionState, spaceID: String?) async {}

    func updateRule(_ ruleID: UUID, draft: RuleDraft, for session: SessionState, spaceID: String?) async {}

    func deleteRule(_ ruleID: UUID, for session: SessionState, spaceID: String?) async {}

    func toggleRuleEnabled(_ ruleID: UUID, for session: SessionState, spaceID: String?) async {}

    func markBillPaid(_ billID: UUID, for session: SessionState, spaceID: String?) async {}

    func importExpenses(_ drafts: [ExpenseDraft], for session: SessionState, spaceID: String?) async {}

    func saveProfile(_ profile: ProfileRecord, for session: SessionState, spaceID: String?) async {}
}
