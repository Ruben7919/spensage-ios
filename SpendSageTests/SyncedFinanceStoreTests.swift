import Foundation
import Testing
@testable import SpendSage

@MainActor
struct SyncedFinanceStoreTests {
    @Test
    func localFinanceStorePartitionsLedgerByAuthenticatedSession() async {
        let defaults = makeDefaults()
        let store = LocalFinanceStore(defaults: defaults, seedLedger: .emptyTestLedger)
        let firstSession = SessionState.signedIn(email: "one@spendsage.ai", provider: "Email")
        let secondSession = SessionState.signedIn(email: "two@spendsage.ai", provider: "Email")

        await store.saveExpense(
            ExpenseDraft(merchant: "Coffee One", amount: 5, category: .coffee),
            for: firstSession,
            spaceID: nil
        )
        await store.saveExpense(
            ExpenseDraft(merchant: "Coffee Two", amount: 7, category: .coffee),
            for: secondSession,
            spaceID: nil
        )

        let firstLedger = await store.loadLedger(for: firstSession, spaceID: nil)
        let secondLedger = await store.loadLedger(for: secondSession, spaceID: nil)

        #expect(firstLedger.expenses.count == 1)
        #expect(firstLedger.expenses.first?.merchant == "Coffee One")
        #expect(secondLedger.expenses.count == 1)
        #expect(secondLedger.expenses.first?.merchant == "Coffee Two")
    }

    @Test
    func syncedFinanceStoreMergesRemoteBootstrapWithUnsyncedLocalLedger() async {
        let defaults = makeDefaults()
        let localStore = LocalFinanceStore(defaults: defaults, seedLedger: .emptyTestLedger)
        let session = SessionState.signedIn(email: "merge@spendsage.ai", provider: "Email")

        var localLedger = LocalFinanceLedger.emptyTestLedger
        localLedger.appendExpense(
            ExpenseDraft(
                merchant: "Local Lunch",
                amount: 18,
                category: .dining,
                date: referenceDate(offsetDays: -1)
            ),
            date: referenceDate(offsetDays: -1)
        )
        localStore.saveLedger(localLedger, for: session, spaceID: nil)

        let remoteExpense = CloudExpenseMirror(
            cloudID: "exp-remote-1",
            merchant: "Cloud Rent",
            category: .home,
            amount: 800,
            date: referenceDate(offsetDays: -2),
            locationLabel: "Guayaquil",
            note: "Remote",
            source: .manual
        )
        let cloud = MockCloudFinanceClient(
            snapshots: [
                CloudFinanceSnapshot(
                    spaceID: "space-1",
                    role: "owner",
                    pulledAt: referenceDate(),
                    monthlyIncome: 2200,
                    monthlyBudget: 1200,
                    profile: .default,
                    expenses: [remoteExpense],
                    accounts: [],
                    bills: [],
                    rules: []
                )
            ]
        )

        let store = SyncedFinanceStore(
            localStore: localStore,
            authService: MockSyncedStoreAuthService(),
            backendConfiguration: BackendConfiguration.make(
                apiBaseURL: "https://api.spendsage.ai/dev/",
                environmentName: "dev"
            ),
            cloudClient: cloud,
            pullInterval: 0
        )

        let merged = await store.loadLedger(for: session, spaceID: nil)
        let hasRemoteExpense = merged.expenses.contains { expense in
            expense.cloudID == "exp-remote-1" && expense.merchant == "Cloud Rent"
        }
        let hasLocalExpense = merged.expenses.contains { $0.merchant == "Local Lunch" }

        #expect(merged.monthlyIncome == 2200)
        #expect(merged.monthlyBudget == 1200)
        #expect(merged.expenses.count == 2)
        #expect(hasRemoteExpense)
        #expect(hasLocalExpense)
    }

    @Test
    func syncedFinanceStorePushesMeaningfulLocalLedgerIntoEmptyCloudBootstrap() async throws {
        let defaults = makeDefaults()
        let localStore = LocalFinanceStore(defaults: defaults, seedLedger: .emptyTestLedger)
        let session = SessionState.signedIn(email: "push@spendsage.ai", provider: "Email")

        var localLedger = LocalFinanceLedger.emptyTestLedger
        localLedger.monthlyIncome = 3000
        localLedger.monthlyBudget = 1400
        localLedger.updateProfile(
            ProfileRecord(
                fullName: "Push Tester",
                householdName: "Casa Push",
                email: "push@spendsage.ai",
                countryCode: "EC",
                marketingOptIn: false
            ),
            date: referenceDate(offsetDays: -1)
        )
        localLedger.appendExpense(
            ExpenseDraft(
                merchant: "Seedless Expense",
                amount: 40,
                category: .groceries,
                date: referenceDate(offsetDays: -1),
                locationLabel: "Quito",
                note: "First sync"
            ),
            date: referenceDate(offsetDays: -1)
        )
        localStore.saveLedger(localLedger, for: session, spaceID: nil)

        let emptySnapshot = CloudFinanceSnapshot(
            spaceID: "space-2",
            role: "owner",
            pulledAt: referenceDate(offsetDays: -1),
            monthlyIncome: 0,
            monthlyBudget: 0,
            profile: .default,
            expenses: [],
            accounts: [],
            bills: [],
            rules: []
        )
        let pushedSnapshot = CloudFinanceSnapshot(
            spaceID: "space-2",
            role: "owner",
            pulledAt: referenceDate(),
            monthlyIncome: 3000,
            monthlyBudget: 1400,
            profile: ProfileRecord(
                fullName: "Push Tester",
                householdName: "Casa Push",
                email: "push@spendsage.ai",
                countryCode: "EC",
                marketingOptIn: false
            ),
            expenses: [
                CloudExpenseMirror(
                    cloudID: "exp-pushed-1",
                    merchant: "Seedless Expense",
                    category: .groceries,
                    amount: 40,
                    date: referenceDate(offsetDays: -1),
                    locationLabel: "Quito",
                    note: "First sync",
                    source: .manual
                )
            ],
            accounts: [],
            bills: [],
            rules: []
        )
        let cloud = MockCloudFinanceClient(snapshots: [emptySnapshot, pushedSnapshot])

        let store = SyncedFinanceStore(
            localStore: localStore,
            authService: MockSyncedStoreAuthService(),
            backendConfiguration: BackendConfiguration.make(
                apiBaseURL: "https://api.spendsage.ai/dev/",
                environmentName: "dev"
            ),
            cloudClient: cloud,
            pullInterval: 0
        )

        let synced = await store.loadLedger(for: session, spaceID: nil)
        let firstExpenseCloudID = synced.expenses.first?.cloudID
        let syncedProfileName = synced.profile.fullName

        #expect(cloud.createdExpenses.count == 1)
        #expect(cloud.nativeProfileUpdates.count == 1)
        #expect(synced.expenses.count == 1)
        #expect(firstExpenseCloudID == "exp-pushed-1")
        #expect(syncedProfileName == "Push Tester")
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "SyncedFinanceStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func referenceDate(offsetDays: Int = 0) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: offsetDays, to: Date(timeIntervalSince1970: 1_775_520_000))!
    }
}

private extension LocalFinanceLedger {
    static var emptyTestLedger: LocalFinanceLedger {
        LocalFinanceLedger(
            monthlyIncome: 0,
            monthlyBudget: 0,
            expenses: [],
            accounts: [],
            bills: [],
            rules: [],
            profile: .default,
            updatedAt: Date(timeIntervalSince1970: 1_775_520_000)
        )
    }
}

@MainActor
private final class MockSyncedStoreAuthService: AuthServicing {
    let configuration = AuthConfiguration.preview

    func signIn(email: String, password: String) async throws -> SessionState {
        .signedIn(email: email, provider: "Email")
    }

    func createAccount(email: String, password: String) async throws -> SessionState {
        .signedIn(email: email, provider: "Email")
    }

    func signInWithSocial(_ provider: SocialProvider) async throws -> SessionState {
        .signedIn(email: "social@spendsage.ai", provider: provider.rawValue)
    }

    func continueAsGuest() async -> SessionState {
        .guest
    }

    func hostedUIRequest(for provider: SocialProvider) -> AuthHostedUIRequest? {
        nil
    }

    func consumeProfileSeed() -> AuthProfileSeed? {
        nil
    }

    func hasRememberedSession() -> Bool {
        false
    }

    func restoreRememberedSession() async -> SessionState? {
        nil
    }

    func currentIDToken() async -> String? {
        "id-token"
    }

    func forgetRememberedSession() {}
}

@MainActor
private final class MockCloudFinanceClient: CloudFinanceSyncing {
    let isConfigured = true
    private var snapshots: [CloudFinanceSnapshot]

    private(set) var createdExpenses: [ExpenseDraft] = []
    private(set) var createdAccounts: [AccountDraft] = []
    private(set) var createdBills: [BillDraft] = []
    private(set) var createdRules: [RuleDraft] = []
    private(set) var nativeProfileUpdates: [(Decimal, Decimal, ProfileRecord)] = []
    private(set) var claimedTesterPlans: [InternalTesterPlanID] = []

    init(snapshots: [CloudFinanceSnapshot]) {
        self.snapshots = snapshots
    }

    func fetchFinanceSnapshot(spaceID: String?) async throws -> CloudFinanceSnapshot {
        if snapshots.count > 1 {
            return snapshots.removeFirst()
        }
        return snapshots.first ?? CloudFinanceSnapshot(
            spaceID: "preview",
            role: "owner",
            pulledAt: .now,
            monthlyIncome: 0,
            monthlyBudget: 0,
            profile: .default,
            expenses: [],
            accounts: [],
            bills: [],
            rules: []
        )
    }

    func createExpense(_ draft: ExpenseDraft, spaceID: String?) async throws -> CloudExpenseMirror {
        createdExpenses.append(draft)
        return CloudExpenseMirror(
            cloudID: "created-expense-\(createdExpenses.count)",
            merchant: draft.merchant,
            category: draft.category,
            amount: draft.amount,
            date: draft.date,
            locationLabel: draft.locationLabel.isEmpty ? nil : draft.locationLabel,
            note: draft.note.isEmpty ? nil : draft.note,
            source: draft.source
        )
    }

    func updateExpense(cloudID: String, draft: ExpenseDraft, spaceID: String?) async throws -> CloudExpenseMirror {
        CloudExpenseMirror(
            cloudID: cloudID,
            merchant: draft.merchant,
            category: draft.category,
            amount: draft.amount,
            date: draft.date,
            locationLabel: draft.locationLabel.isEmpty ? nil : draft.locationLabel,
            note: draft.note.isEmpty ? nil : draft.note,
            source: draft.source
        )
    }

    func deleteExpense(cloudID: String, spaceID: String?) async throws {}

    func createAccount(_ draft: AccountDraft, spaceID: String?) async throws -> CloudAccountMirror {
        createdAccounts.append(draft)
        return CloudAccountMirror(
            cloudID: "created-account-\(createdAccounts.count)",
            name: draft.name,
            institution: draft.institution,
            balance: draft.balance,
            kind: draft.kind
        )
    }

    func updateAccount(cloudID: String, draft: AccountDraft, spaceID: String?) async throws -> CloudAccountMirror {
        CloudAccountMirror(
            cloudID: cloudID,
            name: draft.name,
            institution: draft.institution,
            balance: draft.balance,
            kind: draft.kind
        )
    }

    func deleteAccount(cloudID: String, spaceID: String?) async throws {}

    func createBill(_ draft: BillDraft, spaceID: String?) async throws -> CloudBillMirror {
        createdBills.append(draft)
        return CloudBillMirror(
            cloudID: "created-bill-\(createdBills.count)",
            title: draft.title,
            amount: draft.amount,
            dueDay: draft.dueDay,
            category: draft.category,
            cadence: draft.cadence,
            renewalMonth: draft.renewalMonth
        )
    }

    func updateBill(cloudID: String, draft: BillDraft, spaceID: String?) async throws -> CloudBillMirror {
        CloudBillMirror(
            cloudID: cloudID,
            title: draft.title,
            amount: draft.amount,
            dueDay: draft.dueDay,
            category: draft.category,
            cadence: draft.cadence,
            renewalMonth: draft.renewalMonth
        )
    }

    func deleteBill(cloudID: String, spaceID: String?) async throws {}

    func createRule(_ draft: RuleDraft, spaceID: String?) async throws -> CloudRuleMirror {
        createdRules.append(draft)
        return CloudRuleMirror(
            cloudID: "created-rule-\(createdRules.count)",
            merchantKeyword: draft.merchantKeyword,
            category: draft.category,
            note: draft.note.nilIfEmptyForTest,
            isEnabled: true
        )
    }

    func updateRule(cloudID: String, draft: RuleDraft, isEnabled: Bool, spaceID: String?) async throws -> CloudRuleMirror {
        CloudRuleMirror(
            cloudID: cloudID,
            merchantKeyword: draft.merchantKeyword,
            category: draft.category,
            note: draft.note.nilIfEmptyForTest,
            isEnabled: isEnabled
        )
    }

    func deleteRule(cloudID: String, spaceID: String?) async throws {}

    func upsertNativeProfile(monthlyIncome: Decimal, monthlyBudget: Decimal, profile: ProfileRecord) async throws {
        nativeProfileUpdates.append((monthlyIncome, monthlyBudget, profile))
    }

    func claimTesterPlan(_ planID: InternalTesterPlanID) async throws -> BackendEntitlements {
        claimedTesterPlans.append(planID)
        return BackendEntitlements(
            userId: "tester-1",
            planId: planID.rawValue,
            features: ["all_features"],
            updatedAt: "2026-04-07T00:00:00Z"
        )
    }
}

private extension String {
    var nilIfEmptyForTest: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
