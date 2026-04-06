import Foundation
import Testing
@testable import SpendSage

struct ExpenseImportAndAutomationTests {
    @Test
    func emailImportParsesMerchantAmountAndCategory() {
        let analysis = ExpenseEmailImportService.analyze(
            """
            Order from Spotify
            Merchant: Spotify
            Charged today: $12.99
            Apr 03, 2026
            """,
            locale: Locale(identifier: "en_US")
        )

        #expect(analysis.merchant == "Spotify")
        #expect(analysis.amount == Decimal(string: "12.99"))
        #expect(analysis.category == .subscriptions)
        #expect(analysis.date != nil)
    }

    @Test
    func autopaySubscriptionMaterializesOnlyOncePerCycle() {
        var ledger = LocalFinanceLedger(
            monthlyIncome: 2_000,
            monthlyBudget: 1_500,
            expenses: [],
            accounts: [],
            bills: [
                BillRecord(
                    id: UUID(),
                    title: "Spotify",
                    amount: 12.99,
                    dueDay: 3,
                    category: .subscriptions,
                    autopay: true,
                    lastPaidAt: nil,
                    cadence: .monthly,
                    renewalMonth: nil
                )
            ],
            rules: [],
            profile: .default,
            updatedAt: .distantPast
        )

        let referenceDate = ISO8601DateFormatter().date(from: "2026-04-05T12:00:00Z") ?? .now
        ledger.materializeScheduledAutopayBills(referenceDate: referenceDate)
        ledger.materializeScheduledAutopayBills(referenceDate: referenceDate)

        #expect(ledger.expenses.count == 1)
        #expect(ledger.expenses.first?.merchant == "Spotify")
        #expect(ledger.expenses.first?.source == .subscriptionAutomation)
    }
}
