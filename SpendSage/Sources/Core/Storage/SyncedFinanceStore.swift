import Foundation

@MainActor
protocol FinanceCloudDebugControlling {
    func activateInternalTesterPlan(_ planID: InternalTesterPlanID, for session: SessionState) async throws
}

@MainActor
final class SyncedFinanceStore: FinanceDashboardStoring, FinanceCloudDebugControlling {
    private let localStore: LocalFinanceStore
    private let cloudClient: CloudFinanceSyncing
    private let pullInterval: TimeInterval

    init(
        localStore: LocalFinanceStore = LocalFinanceStore(),
        authService: AuthServicing,
        backendConfiguration: BackendConfiguration?,
        cloudClient: CloudFinanceSyncing? = nil,
        pullInterval: TimeInterval = 20
    ) {
        self.localStore = localStore
        self.cloudClient = cloudClient ?? DefaultCloudFinanceClient.make(
            authService: authService,
            configuration: backendConfiguration
        )
        self.pullInterval = pullInterval
    }

    func loadDashboardState(for session: SessionState, spaceID: String?) async -> FinanceDashboardState {
        await loadLedger(for: session, spaceID: spaceID).dashboardState()
    }

    func loadLedger(for session: SessionState, spaceID: String?) async -> LocalFinanceLedger {
        var ledger = localStore.currentLedger(for: session, spaceID: spaceID)
        guard session.isAuthenticated, cloudClient.isConfigured else {
            return ledger
        }

        var syncState = FinanceSyncMetadataStore.load(for: session, spaceID: spaceID)
        let shouldPull = syncState.lastSuccessfulPullAt == nil
            || Date().timeIntervalSince(syncState.lastSuccessfulPullAt ?? .distantPast) > pullInterval
            || ledger.hasPendingCloudSync

        guard shouldPull else {
            return ledger
        }

        do {
            let remoteBeforePush = try await cloudClient.fetchFinanceSnapshot(spaceID: spaceID)
            if shouldPushLocalSeedlessLedger(local: ledger, remote: remoteBeforePush, syncState: syncState)
                || ledger.hasPendingCloudSync
            {
                ledger = try await pushPendingLocalChanges(in: ledger, spaceID: spaceID)
                ledger = await persistNativeProfileIfNeeded(for: session, ledger: ledger)
                localStore.saveLedger(ledger, for: session, spaceID: spaceID)
            }

            let remote = try await cloudClient.fetchFinanceSnapshot(spaceID: spaceID)
            let merged = merge(remote: remote, local: ledger)
            localStore.saveLedger(merged, for: session, spaceID: spaceID)
            syncState.lastSuccessfulPullAt = .now
            FinanceSyncMetadataStore.save(syncState, for: session, spaceID: spaceID)
            return merged
        } catch {
            return ledger
        }
    }

    func saveExpense(_ draft: ExpenseDraft, for session: SessionState, spaceID: String?) async {
        var ledger = localStore.currentLedger(for: session, spaceID: spaceID)
        ledger.appendExpense(draft)
        ledger = await persistCloudChangesIfNeeded(for: session, spaceID: spaceID, ledger: ledger)
        localStore.saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func updateExpense(_ expenseID: UUID, draft: ExpenseDraft, for session: SessionState, spaceID: String?) async {
        var ledger = localStore.currentLedger(for: session, spaceID: spaceID)
        ledger.updateExpense(expenseID, draft: draft)
        ledger = await persistCloudChangesIfNeeded(for: session, spaceID: spaceID, ledger: ledger)
        localStore.saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func deleteExpense(_ expenseID: UUID, for session: SessionState, spaceID: String?) async {
        var ledger = localStore.currentLedger(for: session, spaceID: spaceID)
        ledger.deleteExpense(expenseID)
        ledger = await persistCloudChangesIfNeeded(for: session, spaceID: spaceID, ledger: ledger)
        localStore.saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func saveBudget(monthlyIncome: Decimal, monthlyBudget: Decimal, for session: SessionState, spaceID: String?) async {
        var ledger = localStore.currentLedger(for: session, spaceID: spaceID)
        ledger.monthlyIncome = monthlyIncome
        ledger.monthlyBudget = monthlyBudget
        ledger.updatedAt = .now
        ledger = await persistNativeProfileIfNeeded(for: session, ledger: ledger)
        localStore.saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func saveAccount(_ draft: AccountDraft, for session: SessionState, spaceID: String?) async {
        var ledger = localStore.currentLedger(for: session, spaceID: spaceID)
        ledger.appendAccount(draft)
        ledger = await persistCloudChangesIfNeeded(for: session, spaceID: spaceID, ledger: ledger)
        localStore.saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func updateAccount(_ accountID: UUID, draft: AccountDraft, for session: SessionState, spaceID: String?) async {
        var ledger = localStore.currentLedger(for: session, spaceID: spaceID)
        ledger.updateAccount(accountID, draft: draft)
        ledger = await persistCloudChangesIfNeeded(for: session, spaceID: spaceID, ledger: ledger)
        localStore.saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func deleteAccount(_ accountID: UUID, for session: SessionState, spaceID: String?) async {
        var ledger = localStore.currentLedger(for: session, spaceID: spaceID)
        ledger.deleteAccount(accountID)
        ledger = await persistCloudChangesIfNeeded(for: session, spaceID: spaceID, ledger: ledger)
        localStore.saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func setPrimaryAccount(_ accountID: UUID, for session: SessionState, spaceID: String?) async {
        var ledger = localStore.currentLedger(for: session, spaceID: spaceID)
        ledger.setPrimaryAccount(accountID)
        localStore.saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func saveBill(_ draft: BillDraft, for session: SessionState, spaceID: String?) async {
        var ledger = localStore.currentLedger(for: session, spaceID: spaceID)
        ledger.appendBill(draft)
        ledger = await persistCloudChangesIfNeeded(for: session, spaceID: spaceID, ledger: ledger)
        localStore.saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func updateBill(_ billID: UUID, draft: BillDraft, for session: SessionState, spaceID: String?) async {
        var ledger = localStore.currentLedger(for: session, spaceID: spaceID)
        ledger.updateBill(billID, draft: draft)
        ledger = await persistCloudChangesIfNeeded(for: session, spaceID: spaceID, ledger: ledger)
        localStore.saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func deleteBill(_ billID: UUID, for session: SessionState, spaceID: String?) async {
        var ledger = localStore.currentLedger(for: session, spaceID: spaceID)
        ledger.deleteBill(billID)
        ledger = await persistCloudChangesIfNeeded(for: session, spaceID: spaceID, ledger: ledger)
        localStore.saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func toggleBillAutopay(_ billID: UUID, for session: SessionState, spaceID: String?) async {
        var ledger = localStore.currentLedger(for: session, spaceID: spaceID)
        ledger.toggleBillAutopay(billID)
        ledger = await persistCloudChangesIfNeeded(for: session, spaceID: spaceID, ledger: ledger)
        localStore.saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func saveRule(_ draft: RuleDraft, for session: SessionState, spaceID: String?) async {
        var ledger = localStore.currentLedger(for: session, spaceID: spaceID)
        ledger.appendRule(draft)
        ledger = await persistCloudChangesIfNeeded(for: session, spaceID: spaceID, ledger: ledger)
        localStore.saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func updateRule(_ ruleID: UUID, draft: RuleDraft, for session: SessionState, spaceID: String?) async {
        var ledger = localStore.currentLedger(for: session, spaceID: spaceID)
        ledger.updateRule(ruleID, draft: draft)
        ledger = await persistCloudChangesIfNeeded(for: session, spaceID: spaceID, ledger: ledger)
        localStore.saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func deleteRule(_ ruleID: UUID, for session: SessionState, spaceID: String?) async {
        var ledger = localStore.currentLedger(for: session, spaceID: spaceID)
        ledger.deleteRule(ruleID)
        ledger = await persistCloudChangesIfNeeded(for: session, spaceID: spaceID, ledger: ledger)
        localStore.saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func toggleRuleEnabled(_ ruleID: UUID, for session: SessionState, spaceID: String?) async {
        var ledger = localStore.currentLedger(for: session, spaceID: spaceID)
        ledger.toggleRuleEnabled(ruleID)
        if session.isAuthenticated,
           let rule = ledger.rules.first(where: { $0.id == ruleID }),
           let cloudID = rule.cloudID,
           let updated = try? await cloudClient.updateRule(
               cloudID: cloudID,
               draft: RuleDraft(
                   merchantKeyword: rule.merchantKeyword,
                   category: rule.category,
                   note: rule.note ?? ""
               ),
               isEnabled: rule.isEnabled,
               spaceID: spaceID
           ),
           let index = ledger.rules.firstIndex(where: { $0.id == ruleID }) {
            ledger.rules[index].category = updated.category
            ledger.rules[index].merchantKeyword = updated.merchantKeyword
            ledger.rules[index].note = updated.note
            ledger.rules[index].isEnabled = updated.isEnabled
            ledger.rules[index].needsCloudUpdate = false
        }
        localStore.saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func markBillPaid(_ billID: UUID, for session: SessionState, spaceID: String?) async {
        var ledger = localStore.currentLedger(for: session, spaceID: spaceID)
        ledger.markBillPaid(billID)
        ledger = await persistCloudChangesIfNeeded(for: session, spaceID: spaceID, ledger: ledger)
        localStore.saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func importExpenses(_ drafts: [ExpenseDraft], for session: SessionState, spaceID: String?) async {
        var ledger = localStore.currentLedger(for: session, spaceID: spaceID)
        ledger.importExpenses(drafts)
        ledger = await persistCloudChangesIfNeeded(for: session, spaceID: spaceID, ledger: ledger)
        localStore.saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func saveProfile(_ profile: ProfileRecord, for session: SessionState, spaceID: String?) async {
        var ledger = localStore.currentLedger(for: session, spaceID: spaceID)
        ledger.updateProfile(profile)
        ledger = await persistNativeProfileIfNeeded(for: session, ledger: ledger)
        localStore.saveLedger(ledger, for: session, spaceID: spaceID)
    }

    func activateInternalTesterPlan(_ planID: InternalTesterPlanID, for session: SessionState) async throws {
        guard session.isAuthenticated, cloudClient.isConfigured else { return }
        _ = try await cloudClient.claimTesterPlan(planID)
        FinanceSyncMetadataStore.markStale(for: session, spaceID: nil)
    }

    private func shouldPushLocalSeedlessLedger(
        local: LocalFinanceLedger,
        remote: CloudFinanceSnapshot,
        syncState: FinanceSyncMetadataStore.State
    ) -> Bool {
        guard syncState.lastSuccessfulPullAt == nil else { return false }
        guard remote.isEmpty else { return false }
        guard local.hasMeaningfulContent else { return false }
        return !localStore.isSeedLedger(local)
    }

    private func persistCloudChangesIfNeeded(
        for session: SessionState,
        spaceID: String?,
        ledger: LocalFinanceLedger
    ) async -> LocalFinanceLedger {
        guard session.isAuthenticated, cloudClient.isConfigured else {
            return ledger
        }

        var updated = ledger
        do {
            updated = try await pushPendingLocalChanges(in: updated, spaceID: spaceID)
        } catch {
            updated = ledger
        }
        updated = await persistNativeProfileIfNeeded(for: session, ledger: updated)
        FinanceSyncMetadataStore.markStale(for: session, spaceID: spaceID)
        return updated
    }

    private func persistNativeProfileIfNeeded(for session: SessionState, ledger: LocalFinanceLedger) async -> LocalFinanceLedger {
        guard session.isAuthenticated, cloudClient.isConfigured else {
            return ledger
        }
        do {
            try await cloudClient.upsertNativeProfile(
                monthlyIncome: ledger.monthlyIncome,
                monthlyBudget: ledger.monthlyBudget,
                profile: ledger.profile
            )
        } catch {
            return ledger
        }
        return ledger
    }

    private func pushPendingLocalChanges(in ledger: LocalFinanceLedger, spaceID: String?) async throws -> LocalFinanceLedger {
        var updated = ledger

        for deletion in updated.pendingCloudDeletions {
            do {
                switch deletion.kind {
                case .expense:
                    try await cloudClient.deleteExpense(cloudID: deletion.cloudID, spaceID: spaceID)
                case .account:
                    try await cloudClient.deleteAccount(cloudID: deletion.cloudID, spaceID: spaceID)
                case .bill:
                    try await cloudClient.deleteBill(cloudID: deletion.cloudID, spaceID: spaceID)
                case .rule:
                    try await cloudClient.deleteRule(cloudID: deletion.cloudID, spaceID: spaceID)
                }
                updated.clearPendingCloudDeletion(kind: deletion.kind, cloudID: deletion.cloudID)
            } catch {
                continue
            }
        }

        for index in updated.expenses.indices where updated.expenses[index].cloudID == nil {
            let draft = ExpenseDraft(
                merchant: updated.expenses[index].merchant,
                amount: updated.expenses[index].amount,
                category: updated.expenses[index].category,
                date: updated.expenses[index].date,
                locationLabel: updated.expenses[index].locationLabel ?? "",
                note: updated.expenses[index].note ?? "",
                source: updated.expenses[index].source ?? .manual,
                sourceText: updated.expenses[index].sourceText ?? "",
                recurringPlan: updated.expenses[index].recurringPlan
            )
            if let remote = try? await cloudClient.createExpense(draft, spaceID: spaceID) {
                updated.expenses[index].cloudID = remote.cloudID
                updated.expenses[index].needsCloudUpdate = false
            }
        }

        for index in updated.accounts.indices where updated.accounts[index].cloudID == nil {
            let draft = AccountDraft(
                name: updated.accounts[index].name,
                institution: updated.accounts[index].institution,
                balance: updated.accounts[index].balance,
                kind: updated.accounts[index].kind
            )
            if let remote = try? await cloudClient.createAccount(draft, spaceID: spaceID) {
                updated.accounts[index].cloudID = remote.cloudID
                updated.accounts[index].needsCloudUpdate = false
            }
        }

        for index in updated.bills.indices where updated.bills[index].cloudID == nil {
            let draft = BillDraft(
                title: updated.bills[index].title,
                amount: updated.bills[index].amount,
                dueDay: updated.bills[index].dueDay,
                category: updated.bills[index].category,
                autopay: updated.bills[index].autopay,
                cadence: updated.bills[index].cadence ?? .monthly,
                renewalMonth: updated.bills[index].renewalMonth
            )
            if let remote = try? await cloudClient.createBill(draft, spaceID: spaceID) {
                updated.bills[index].cloudID = remote.cloudID
                updated.bills[index].needsCloudUpdate = false
            }
        }

        for index in updated.rules.indices where updated.rules[index].cloudID == nil {
            let draft = RuleDraft(
                merchantKeyword: updated.rules[index].merchantKeyword,
                category: updated.rules[index].category,
                note: updated.rules[index].note ?? ""
            )
            if let remote = try? await cloudClient.createRule(draft, spaceID: spaceID) {
                updated.rules[index].cloudID = remote.cloudID
                updated.rules[index].needsCloudUpdate = false
            }
        }

        for index in updated.expenses.indices where updated.expenses[index].needsCloudUpdate && updated.expenses[index].cloudID != nil {
            let draft = ExpenseDraft(
                merchant: updated.expenses[index].merchant,
                amount: updated.expenses[index].amount,
                category: updated.expenses[index].category,
                date: updated.expenses[index].date,
                locationLabel: updated.expenses[index].locationLabel ?? "",
                note: updated.expenses[index].note ?? "",
                source: updated.expenses[index].source ?? .manual,
                sourceText: updated.expenses[index].sourceText ?? "",
                recurringPlan: updated.expenses[index].recurringPlan
            )
            if let cloudID = updated.expenses[index].cloudID,
               let remote = try? await cloudClient.updateExpense(cloudID: cloudID, draft: draft, spaceID: spaceID) {
                updated.expenses[index].merchant = remote.merchant
                updated.expenses[index].category = remote.category
                updated.expenses[index].amount = remote.amount
                updated.expenses[index].date = remote.date
                updated.expenses[index].locationLabel = remote.locationLabel
                updated.expenses[index].note = remote.note
                updated.expenses[index].source = remote.source
                updated.expenses[index].needsCloudUpdate = false
            }
        }

        for index in updated.accounts.indices where updated.accounts[index].needsCloudUpdate && updated.accounts[index].cloudID != nil {
            let draft = AccountDraft(
                name: updated.accounts[index].name,
                institution: updated.accounts[index].institution,
                balance: updated.accounts[index].balance,
                kind: updated.accounts[index].kind
            )
            if let cloudID = updated.accounts[index].cloudID,
               let remote = try? await cloudClient.updateAccount(cloudID: cloudID, draft: draft, spaceID: spaceID) {
                updated.accounts[index].name = remote.name
                updated.accounts[index].institution = remote.institution
                updated.accounts[index].balance = remote.balance
                updated.accounts[index].kind = remote.kind
                updated.accounts[index].needsCloudUpdate = false
            }
        }

        for index in updated.bills.indices where updated.bills[index].needsCloudUpdate && updated.bills[index].cloudID != nil {
            let draft = BillDraft(
                title: updated.bills[index].title,
                amount: updated.bills[index].amount,
                dueDay: updated.bills[index].dueDay,
                category: updated.bills[index].category,
                autopay: updated.bills[index].autopay,
                cadence: updated.bills[index].cadence ?? .monthly,
                renewalMonth: updated.bills[index].renewalMonth
            )
            if let cloudID = updated.bills[index].cloudID,
               let remote = try? await cloudClient.updateBill(cloudID: cloudID, draft: draft, spaceID: spaceID) {
                updated.bills[index].title = remote.title
                updated.bills[index].amount = remote.amount
                updated.bills[index].dueDay = remote.dueDay
                updated.bills[index].category = remote.category
                updated.bills[index].cadence = remote.cadence
                updated.bills[index].renewalMonth = remote.renewalMonth
                updated.bills[index].needsCloudUpdate = false
            }
        }

        for index in updated.rules.indices where updated.rules[index].needsCloudUpdate && updated.rules[index].cloudID != nil {
            let draft = RuleDraft(
                merchantKeyword: updated.rules[index].merchantKeyword,
                category: updated.rules[index].category,
                note: updated.rules[index].note ?? ""
            )
            if let cloudID = updated.rules[index].cloudID,
               let remote = try? await cloudClient.updateRule(
                   cloudID: cloudID,
                   draft: draft,
                   isEnabled: updated.rules[index].isEnabled,
                   spaceID: spaceID
               ) {
                updated.rules[index].merchantKeyword = remote.merchantKeyword
                updated.rules[index].category = remote.category
                updated.rules[index].note = remote.note
                updated.rules[index].isEnabled = remote.isEnabled
                updated.rules[index].needsCloudUpdate = false
            }
        }

        return updated
    }

    private func merge(remote: CloudFinanceSnapshot, local: LocalFinanceLedger) -> LocalFinanceLedger {
        let mergedExpenses = mergeRemoteExpenses(remote.expenses, local: local)
        let mergedAccounts = mergeRemoteAccounts(remote.accounts, local: local)
        let mergedBills = mergeRemoteBills(remote.bills, local: local)
        let mergedRules = mergeRemoteRules(remote.rules, local: local)

        return LocalFinanceLedger(
            monthlyIncome: remote.monthlyIncome == 0 && !localStore.isSeedLedger(local) ? local.monthlyIncome : remote.monthlyIncome,
            monthlyBudget: remote.monthlyBudget == 0 && !localStore.isSeedLedger(local) ? local.monthlyBudget : remote.monthlyBudget,
            expenses: mergedExpenses,
            accounts: mergedAccounts,
            bills: mergedBills,
            rules: mergedRules,
            profile: remote.profile == .default && !localStore.isSeedLedger(local) ? local.profile : remote.profile,
            pendingCloudDeletions: local.pendingCloudDeletions,
            updatedAt: remote.pulledAt > local.updatedAt ? remote.pulledAt : local.updatedAt
        )
    }

    private func mergeRemoteExpenses(_ remote: [CloudExpenseMirror], local: LocalFinanceLedger) -> [ExpenseRecord] {
        let localByCloud = Dictionary(uniqueKeysWithValues: local.expenses.compactMap { record in
            record.cloudID.map { ($0, record) }
        })
        let remoteCloudIDs = Set(remote.map(\.cloudID))
        let pendingDeleted = Set(local.pendingCloudDeletions.filter { $0.kind == .expense }.map(\.cloudID))
        var reconciledLocalIDs = Set<UUID>()
        var merged: [ExpenseRecord] = remote.compactMap { mirror -> ExpenseRecord? in
            guard pendingDeleted.contains(mirror.cloudID) == false else { return nil }
            let matchedLocal = localByCloud[mirror.cloudID] ?? local.expenses.first(where: { record in
                guard pendingDeleted.contains(record.cloudID ?? "") == false else { return false }
                guard remoteCloudIDs.contains(record.cloudID ?? "") == false else { return false }
                return recordsRepresentSameExpense(record, mirror)
            })
            var record = matchedLocal ?? ExpenseRecord(
                merchant: mirror.merchant,
                category: mirror.category,
                amount: mirror.amount,
                date: mirror.date
            )
            if let matchedLocal {
                reconciledLocalIDs.insert(matchedLocal.id)
            }
            if record.needsCloudUpdate {
                return record
            }
            record.cloudID = mirror.cloudID
            record.merchant = mirror.merchant
            record.category = mirror.category
            record.amount = mirror.amount
            record.date = mirror.date
            record.locationLabel = mirror.locationLabel
            record.note = mirror.note
            record.source = mirror.source
            record.needsCloudUpdate = false
            return record
        }
        merged.append(contentsOf: local.expenses.filter { record in
            guard reconciledLocalIDs.contains(record.id) == false else { return false }
            guard let cloudID = record.cloudID else { return true }
            return remoteCloudIDs.contains(cloudID) == false
        })
        return merged.sorted { $0.date > $1.date }
    }

    private func recordsRepresentSameExpense(_ record: ExpenseRecord, _ mirror: CloudExpenseMirror) -> Bool {
        record.merchant == mirror.merchant
            && record.category == mirror.category
            && record.amount == mirror.amount
            && record.date == mirror.date
            && record.locationLabel == mirror.locationLabel
            && record.note == mirror.note
            && record.source == mirror.source
    }

    private func mergeRemoteAccounts(_ remote: [CloudAccountMirror], local: LocalFinanceLedger) -> [AccountRecord] {
        let localByCloud = Dictionary(uniqueKeysWithValues: local.accounts.compactMap { record in
            record.cloudID.map { ($0, record) }
        })
        let remoteCloudIDs = Set(remote.map(\.cloudID))
        let pendingDeleted = Set(local.pendingCloudDeletions.filter { $0.kind == .account }.map(\.cloudID))
        let localPrimaryCloudID = local.accounts.first(where: { $0.isPrimary })?.cloudID
        var merged: [AccountRecord] = remote.compactMap { mirror -> AccountRecord? in
            guard pendingDeleted.contains(mirror.cloudID) == false else { return nil }
            var record = localByCloud[mirror.cloudID] ?? AccountRecord(
                name: mirror.name,
                institution: mirror.institution,
                balance: mirror.balance,
                kind: mirror.kind
            )
            if record.needsCloudUpdate {
                return record
            }
            record.cloudID = mirror.cloudID
            record.name = mirror.name
            record.institution = mirror.institution
            record.balance = mirror.balance
            record.kind = mirror.kind
            record.isPrimary = localPrimaryCloudID == mirror.cloudID
            record.needsCloudUpdate = false
            return record
        }
        merged.append(contentsOf: local.accounts.filter { record in
            guard let cloudID = record.cloudID else { return true }
            return remoteCloudIDs.contains(cloudID) == false
        })
        if merged.contains(where: { $0.isPrimary }) == false, let firstIndex = merged.indices.first {
            merged[firstIndex].isPrimary = true
        }
        return merged
    }

    private func mergeRemoteBills(_ remote: [CloudBillMirror], local: LocalFinanceLedger) -> [BillRecord] {
        let localByCloud = Dictionary(uniqueKeysWithValues: local.bills.compactMap { record in
            record.cloudID.map { ($0, record) }
        })
        let remoteCloudIDs = Set(remote.map(\.cloudID))
        let pendingDeleted = Set(local.pendingCloudDeletions.filter { $0.kind == .bill }.map(\.cloudID))
        var merged: [BillRecord] = remote.compactMap { mirror -> BillRecord? in
            guard pendingDeleted.contains(mirror.cloudID) == false else { return nil }
            let existing = localByCloud[mirror.cloudID]
            if let existing, existing.needsCloudUpdate {
                return existing
            }
            return BillRecord(
                id: existing?.id ?? UUID(),
                cloudID: mirror.cloudID,
                title: mirror.title,
                amount: mirror.amount,
                dueDay: mirror.dueDay,
                category: mirror.category,
                autopay: existing?.autopay ?? false,
                lastPaidAt: existing?.lastPaidAt,
                cadence: mirror.cadence,
                renewalMonth: mirror.renewalMonth,
                needsCloudUpdate: false
            )
        }
        merged.append(contentsOf: local.bills.filter { record in
            guard let cloudID = record.cloudID else { return true }
            return remoteCloudIDs.contains(cloudID) == false
        })
        return merged
    }

    private func mergeRemoteRules(_ remote: [CloudRuleMirror], local: LocalFinanceLedger) -> [RuleRecord] {
        let localByCloud = Dictionary(uniqueKeysWithValues: local.rules.compactMap { record in
            record.cloudID.map { ($0, record) }
        })
        let remoteCloudIDs = Set(remote.map(\.cloudID))
        let pendingDeleted = Set(local.pendingCloudDeletions.filter { $0.kind == .rule }.map(\.cloudID))
        var merged: [RuleRecord] = remote.compactMap { mirror -> RuleRecord? in
            guard pendingDeleted.contains(mirror.cloudID) == false else { return nil }
            var record = localByCloud[mirror.cloudID] ?? RuleRecord(
                merchantKeyword: mirror.merchantKeyword,
                category: mirror.category,
                note: mirror.note,
                isEnabled: mirror.isEnabled
            )
            if record.needsCloudUpdate {
                return record
            }
            record.cloudID = mirror.cloudID
            record.merchantKeyword = mirror.merchantKeyword
            record.category = mirror.category
            record.note = mirror.note
            record.isEnabled = mirror.isEnabled
            record.needsCloudUpdate = false
            return record
        }
        merged.append(contentsOf: local.rules.filter { record in
            guard let cloudID = record.cloudID else { return true }
            return remoteCloudIDs.contains(cloudID) == false
        })
        return merged
    }
}

enum FinanceSyncMetadataStore {
    struct State: Codable, Equatable {
        var lastSuccessfulPullAt: Date?
    }

    private static let storageKeyPrefix = "spendsage.finance.sync.state"

    static func load(for session: SessionState, spaceID: String?, defaults: UserDefaults = .standard) -> State {
        guard
            let data = defaults.data(forKey: storageKey(for: session, spaceID: spaceID)),
            let state = try? JSONDecoder().decode(State.self, from: data)
        else {
            return State()
        }
        return state
    }

    static func save(_ state: State, for session: SessionState, spaceID: String?, defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: storageKey(for: session, spaceID: spaceID))
    }

    static func markStale(for session: SessionState, spaceID: String?, defaults: UserDefaults = .standard) {
        var state = load(for: session, spaceID: spaceID, defaults: defaults)
        state.lastSuccessfulPullAt = nil
        save(state, for: session, spaceID: spaceID, defaults: defaults)
    }

    private static func storageKey(for session: SessionState, spaceID: String?) -> String {
        let trimmedSpace = spaceID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let normalizedSpace = trimmedSpace.isEmpty ? "personal" : trimmedSpace
        return "\(storageKeyPrefix).\(session.storageNamespace).\(normalizedSpace)"
    }
}
