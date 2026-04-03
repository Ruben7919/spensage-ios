import Foundation

@MainActor
protocol FinanceDashboardStoring {
    func loadDashboardState(for session: SessionState) async -> FinanceDashboardState
    func saveExpense(_ draft: ExpenseDraft, for session: SessionState) async
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

    func saveExpense(_ draft: ExpenseDraft, for session: SessionState) async {
        var ledger = loadLedger()
        ledger.appendExpense(draft)
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

    func saveExpense(_ draft: ExpenseDraft, for session: SessionState) async {}
}
