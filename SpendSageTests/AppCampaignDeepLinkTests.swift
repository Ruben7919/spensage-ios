import Foundation
import Testing
@testable import SpendSage

struct AppCampaignDeepLinkTests {
    @Test
    func inviteLinkIsStillResolved() {
        let url = URL(string: "spendsage://invite?code=ABCD1234")!
        let action = AppViewModel.resolveIncomingURL(url)

        #expect(action?.inviteCode == "ABCD1234")
        #expect(action?.selectedTab == nil)
        #expect(action?.presentedSheet == nil)
    }

    @Test
    func scanTabShortcutResolves() {
        let url = URL(string: "spendsage://open?tab=scan")!
        let action = AppViewModel.resolveIncomingURL(url)

        #expect(action?.selectedTab == .scan)
        #expect(action?.presentedSheet == nil)
    }

    @Test
    func addExpenseShortcutFallsBackToExpensesTab() {
        let url = URL(string: "spendsage://open?sheet=add-expense")!
        let action = AppViewModel.resolveIncomingURL(url)

        #expect(action?.selectedTab == .expenses)
        #expect(action?.presentedSheet == .addExpense)
    }

    @Test
    func spanishAliasesResolveForBudgetShortcut() {
        let url = URL(string: "spendsage://open?tab=ajustes&sheet=presupuesto")!
        let action = AppViewModel.resolveIncomingURL(url)

        #expect(action?.selectedTab == .settings)
        #expect(action?.presentedSheet == .budgetWizard)
    }
}
