import Foundation

@MainActor
protocol FinanceDashboardStoring {
    func loadDashboardState(for session: SessionState) async -> FinanceDashboardState
    func loadLedger(for session: SessionState) async -> LocalFinanceLedger
    func saveExpense(_ draft: ExpenseDraft, for session: SessionState) async
    func saveBudget(monthlyIncome: Decimal, monthlyBudget: Decimal, for session: SessionState) async
    func saveAccount(_ draft: AccountDraft, for session: SessionState) async
    func saveBill(_ draft: BillDraft, for session: SessionState) async
    func saveRule(_ draft: RuleDraft, for session: SessionState) async
    func markBillPaid(_ billID: UUID, for session: SessionState) async
    func importExpenses(_ drafts: [ExpenseDraft], for session: SessionState) async
    func saveProfile(_ profile: ProfileRecord, for session: SessionState) async
}

@MainActor
final class LocalFinanceStore: FinanceDashboardStoring {
    private let defaults: UserDefaults
    private let storageKey = "spendsage.local.finance.ledger"
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

    func loadDashboardState(for session: SessionState) async -> FinanceDashboardState {
        loadLedger().dashboardState()
    }

    func loadLedger(for session: SessionState) async -> LocalFinanceLedger {
        loadLedger()
    }

    func saveExpense(_ draft: ExpenseDraft, for session: SessionState) async {
        var ledger = loadLedger()
        ledger.appendExpense(draft)
        saveLedger(ledger)
    }

    func saveBudget(monthlyIncome: Decimal, monthlyBudget: Decimal, for session: SessionState) async {
        var ledger = loadLedger()
        ledger.monthlyIncome = monthlyIncome
        ledger.monthlyBudget = monthlyBudget
        ledger.updatedAt = .now
        saveLedger(ledger)
    }

    func saveAccount(_ draft: AccountDraft, for session: SessionState) async {
        var ledger = loadLedger()
        ledger.appendAccount(draft)
        saveLedger(ledger)
    }

    func saveBill(_ draft: BillDraft, for session: SessionState) async {
        var ledger = loadLedger()
        ledger.appendBill(draft)
        saveLedger(ledger)
    }

    func saveRule(_ draft: RuleDraft, for session: SessionState) async {
        var ledger = loadLedger()
        ledger.appendRule(draft)
        saveLedger(ledger)
    }

    func markBillPaid(_ billID: UUID, for session: SessionState) async {
        var ledger = loadLedger()
        ledger.markBillPaid(billID)
        saveLedger(ledger)
    }

    func importExpenses(_ drafts: [ExpenseDraft], for session: SessionState) async {
        var ledger = loadLedger()
        ledger.importExpenses(drafts)
        saveLedger(ledger)
    }

    func saveProfile(_ profile: ProfileRecord, for session: SessionState) async {
        var ledger = loadLedger()
        ledger.updateProfile(profile)
        saveLedger(ledger)
    }

    private func loadLedger() -> LocalFinanceLedger {
        guard let data = defaults.data(forKey: storageKey),
              let ledger = try? decoder.decode(LocalFinanceLedger.self, from: data) else {
            return seedLedger
        }
        return ledger
    }

    private func saveLedger(_ ledger: LocalFinanceLedger) {
        guard let data = try? encoder.encode(ledger) else { return }
        defaults.set(data, forKey: storageKey)
    }
}

@MainActor
struct PreviewFinanceStore: FinanceDashboardStoring {
    func loadDashboardState(for session: SessionState) async -> FinanceDashboardState {
        PreviewFinanceData.seedLedger.dashboardState()
    }

    func loadLedger(for session: SessionState) async -> LocalFinanceLedger {
        PreviewFinanceData.seedLedger
    }

    func saveExpense(_ draft: ExpenseDraft, for session: SessionState) async {}

    func saveBudget(monthlyIncome: Decimal, monthlyBudget: Decimal, for session: SessionState) async {}

    func saveAccount(_ draft: AccountDraft, for session: SessionState) async {}

    func saveBill(_ draft: BillDraft, for session: SessionState) async {}

    func saveRule(_ draft: RuleDraft, for session: SessionState) async {}

    func markBillPaid(_ billID: UUID, for session: SessionState) async {}

    func importExpenses(_ drafts: [ExpenseDraft], for session: SessionState) async {}

    func saveProfile(_ profile: ProfileRecord, for session: SessionState) async {}
}
