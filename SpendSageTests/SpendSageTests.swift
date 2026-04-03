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
        #expect(SessionState.guest.isAuthenticated == true)
    }

    @Test
    @MainActor
    func localFinanceStorePersistsAddedExpense() async {
        let suiteName = "SpendSageTests.\(Foundation.UUID().uuidString)"
        let defaults = Foundation.UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = LocalFinanceStore(defaults: defaults, seedLedger: PreviewFinanceData.seedLedger)
        let before = await store.loadDashboardState(for: SessionState.guest)

        await store.saveExpense(
            ExpenseDraft(
                merchant: "Train ticket",
                amount: 18.25,
                category: ExpenseCategory.transport,
                date: .now,
                note: "Airport run"
            ),
            for: SessionState.guest
        )

        let after = await store.loadDashboardState(for: SessionState.guest)
        #expect(after.budgetSnapshot.monthlySpent == before.budgetSnapshot.monthlySpent + 18.25)
        #expect(after.recentExpenses.first?.title == "Train ticket")
        #expect(after.categoryBreakdown.contains(where: { $0.category == ExpenseCategory.transport }))
    }
}
