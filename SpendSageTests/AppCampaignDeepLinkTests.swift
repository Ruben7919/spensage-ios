import Foundation
import Testing
@testable import SpendSage

struct AppCampaignDeepLinkTests {
    @Test
    func inviteLinkIsStillResolved() {
        let url = URL(string: "spendsage://invite?code=ABCD1234")!
        let action = AppViewModel.resolveIncomingURL(url)

        #expect(action?.inviteCode == "ABCD1234")
        #expect(action?.selectedTab == .settings)
        #expect(action?.settingsRoute == .sharedSpaces)
        #expect(action?.presentedSheet == nil)
    }

    @Test
    func invitePathStyleIsResolved() {
        let url = URL(string: "spendsage://invite/INVITE-123")!
        let action = AppViewModel.resolveIncomingURL(url)

        #expect(action?.inviteCode == "INVITE-123")
        #expect(action?.selectedTab == .settings)
        #expect(action?.settingsRoute == .sharedSpaces)
    }

    @Test
    func universalInviteLinkIsResolved() {
        let url = URL(string: "https://michifinanzas.com/invite/INVITE-456")!
        let action = AppViewModel.resolveIncomingURL(url)

        #expect(action?.inviteCode == "INVITE-456")
        #expect(action?.selectedTab == .settings)
        #expect(action?.settingsRoute == .sharedSpaces)
    }

    @Test
    func universalInviteQueryLinkIsResolved() {
        let url = URL(string: "https://michifinanzas.com/invite?code=INVITE-789")!
        let action = AppViewModel.resolveIncomingURL(url)

        #expect(action?.inviteCode == "INVITE-789")
        #expect(action?.selectedTab == .settings)
        #expect(action?.settingsRoute == .sharedSpaces)
    }

    @Test
    func inviteShareURLIsCanonicalizedForWebFallback() {
        let invite = CreateInviteResult(
            invite: SpaceInvite(
                code: "inv_code_bf5f5ac0140bd-d444fabdd4",
                spaceId: "space-1",
                recipientEmailLower: "beta@example.com",
                role: .editor,
                inviterUserId: "owner-1",
                inviterEmailLower: "owner@example.com",
                createdAt: "2026-04-11T12:00:00Z",
                expiresAt: nil,
                status: .pending,
                acceptedByUserId: nil,
                acceptedAt: nil
            ),
            deepLink: "spendsage://invite?code=inv_code_bf5f5ac0140bd-d444fabdd4",
            webLink: "https://michifinanzas.com/invite?code=inv_code_bf5f5ac0140bd-d444fabdd4",
            emailDelivery: nil
        )

        let sharedURL = SharedSpacesView.sharedInviteURL(for: invite)

        #expect(sharedURL?.absoluteString == "https://michifinanzas.com/invite/inv_code_bf5f5ac0140bd-d444fabdd4?code=inv_code_bf5f5ac0140bd-d444fabdd4")
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
