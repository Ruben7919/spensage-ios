import Foundation
import Testing
@testable import SpendSage

struct SpendSageTests {
    @Test
    func budgetRemainingIsComputed() {
        let snapshot = BudgetSnapshot(monthlyIncome: 3000, monthlySpent: 1200, monthlyBudget: 2200)
        #expect(snapshot.remaining == 1000)
    }

    @Test
    func signedOutIsNotAuthenticated() {
        #expect(SessionState.signedOut.isAuthenticated == false)
        #expect(SessionState.guest.isAuthenticated == false)
        #expect(SessionState.signedIn(email: "test@spendsage.ai", provider: "Email").isAuthenticated == true)
    }

    @Test
    @MainActor
    func localFinanceStorePersistsAddedExpense() async {
        let suiteName = "SpendSageTests.\(Foundation.UUID().uuidString)"
        let defaults = Foundation.UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = LocalFinanceStore(defaults: defaults, seedLedger: PreviewFinanceData.seedLedger)
        let before = await store.loadDashboardState(for: SessionState.guest, spaceID: nil)

        await store.saveExpense(
            ExpenseDraft(
                merchant: "Train ticket",
                amount: 18.25,
                category: ExpenseCategory.transport,
                date: .now,
                note: "Airport run"
            ),
            for: SessionState.guest,
            spaceID: nil
        )

        let after = await store.loadDashboardState(for: SessionState.guest, spaceID: nil)
        #expect(after.budgetSnapshot.monthlySpent == before.budgetSnapshot.monthlySpent + 18.25)
        #expect(after.recentExpenses.first?.title == "Train ticket")
        #expect(after.categoryBreakdown.contains(where: { $0.category == ExpenseCategory.transport }))
    }

    @Test
    @MainActor
    func localFinanceStorePersistsAccountsBillsAndRules() async {
        let suiteName = "SpendSageTests.\(Foundation.UUID().uuidString)"
        let defaults = Foundation.UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = LocalFinanceStore(defaults: defaults, seedLedger: PreviewFinanceData.seedLedger)

        await store.saveAccount(
            AccountDraft(name: "Travel Card", institution: "Atlas Bank", balance: 420, kind: .creditCard),
            for: SessionState.guest,
            spaceID: nil
        )
        await store.saveBill(
            BillDraft(title: "Phone", amount: 45, dueDay: 15, category: .bills, autopay: true),
            for: SessionState.guest,
            spaceID: nil
        )
        await store.saveRule(
            RuleDraft(merchantKeyword: "atlas", category: .transport, note: "Travel merchants"),
            for: SessionState.guest,
            spaceID: nil
        )

        let ledger = await store.loadLedger(for: SessionState.guest, spaceID: nil)
        #expect(ledger.accounts.contains(where: { $0.name == "Travel Card" }))
        #expect(ledger.bills.contains(where: { $0.title == "Phone" }))
        #expect(ledger.rules.contains(where: { $0.merchantKeyword == "atlas" }))
    }

    @Test
    @MainActor
    func markBillPaidCreatesExpenseEntry() async {
        let suiteName = "SpendSageTests.\(Foundation.UUID().uuidString)"
        let defaults = Foundation.UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let billID = UUID()
        let seedLedger = LocalFinanceLedger(
            monthlyIncome: 3000,
            monthlyBudget: 2200,
            expenses: [],
            accounts: [],
            bills: [
                BillRecord(
                    id: billID,
                    title: "Internet",
                    amount: 54.99,
                    dueDay: 8,
                    category: .bills,
                    autopay: true,
                    lastPaidAt: nil
                )
            ],
            rules: [],
            profile: .default,
            updatedAt: .now
        )

        let store = LocalFinanceStore(defaults: defaults, seedLedger: seedLedger)
        await store.markBillPaid(billID, for: SessionState.guest, spaceID: nil)

        let ledger = await store.loadLedger(for: SessionState.guest, spaceID: nil)
        #expect(ledger.expenses.contains(where: { $0.merchant == "Internet" && $0.amount == 54.99 }))
        #expect(ledger.bills.first?.lastPaidAt != nil)
    }
}
