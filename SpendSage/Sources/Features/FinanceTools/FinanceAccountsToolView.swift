import SwiftUI

private struct AccountDisplayMetadata: Codable {
    var note: String
    var isArchived: Bool
    var includeInNetWorth: Bool

    init(note: String = "", isArchived: Bool = false, includeInNetWorth: Bool = true) {
        self.note = note
        self.isArchived = isArchived
        self.includeInNetWorth = includeInNetWorth
    }
}

struct FinanceAccountsToolView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var name = ""
    @State private var institution = ""
    @State private var balance = ""
    @State private var kind = AccountKind.checking
    @State private var note = ""
    @State private var active = true
    @State private var includeInNetWorth = true
    @State private var errorMessage: String?
    @State private var editingAccountID: UUID?
    @AppStorage("native.accounts.displayMetadata") private var displayMetadataJSON = "{}"

    private var totalBalance: Decimal {
        viewModel.ledger?.totalAccountBalance() ?? 0
    }

    private var liquidBalance: Decimal {
        viewModel.ledger?.liquidAccountBalance() ?? 0
    }

    private var creditExposure: Decimal {
        viewModel.ledger?.creditExposure() ?? 0
    }

    private var assetBalance: Decimal {
        viewModel.ledger?.accounts
            .filter { $0.balance > 0 && $0.kind != .creditCard }
            .reduce(Decimal.zero) { $0 + $1.balance } ?? 0
    }

    private var primaryAccountID: UUID? {
        viewModel.ledger?.primaryAccount?.id
    }

    private var editingAccount: AccountRecord? {
        guard let editingAccountID else { return nil }
        return viewModel.accounts.first(where: { $0.id == editingAccountID })
    }

    private var displayMetadata: [String: AccountDisplayMetadata] {
        decodeDisplayMetadata(displayMetadataJSON)
    }

    private var activeAccounts: [AccountRecord] {
        viewModel.accounts.filter { !isArchived($0.id) }
    }

    private var archivedAccounts: [AccountRecord] {
        viewModel.accounts.filter { isArchived($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Local-first accounts",
                    title: "Accounts",
                    summary: "Track cash, cards, savings, and investment balances without leaving your device. The net worth line stays visible, and the primary account stays anchored at the top.",
                    systemImage: "wallet.pass.fill"
                )

                if let notice = viewModel.notice {
                    FinanceNoticeCard(message: notice)
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Net worth snapshot")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            BrandMetricTile(
                                title: "Assets",
                                value: assetBalance.formatted(.currency(code: "USD")),
                                systemImage: "arrow.up.circle.fill"
                            )
                            BrandMetricTile(
                                title: "Liabilities",
                                value: creditExposure.formatted(.currency(code: "USD")),
                                systemImage: "arrow.down.circle.fill"
                            )
                            BrandMetricTile(
                                title: "Liquid",
                                value: liquidBalance.formatted(.currency(code: "USD")),
                                systemImage: "drop.fill"
                            )
                            BrandMetricTile(
                                title: "Net worth",
                                value: totalBalance.formatted(.currency(code: "USD")),
                                systemImage: "chart.line.uptrend.xyaxis"
                            )
                            BrandMetricTile(
                                title: "Primary",
                                value: viewModel.ledger?.primaryAccount?.name ?? "None",
                                systemImage: "star.fill"
                            )
                        }

                        BrandFeatureRow(
                            systemImage: "lock.fill",
                            title: "Local-only balance sheet",
                            detail: "The balance sheet is computed from the balances saved on this device. Deleting removes an account from the local ledger when you want it archived."
                        )
                    }
                }

                if activeAccounts.isEmpty && archivedAccounts.isEmpty {
                    FinanceEmptyStateCard(
                        title: "No accounts yet",
                        summary: "Add your first checking, savings, or credit card balance to anchor the rest of the ledger.",
                        systemImage: "tray.fill"
                    )
                } else {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Active accounts")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)

                            if activeAccounts.isEmpty {
                                Text("No active accounts right now. Archived accounts stay visible below.")
                                    .font(.footnote)
                                    .foregroundStyle(BrandTheme.muted)
                            }

                            ForEach(activeAccounts) { account in
                                accountRow(account)

                                if account.id != activeAccounts.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                if !archivedAccounts.isEmpty {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Archived accounts")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)

                            Text("Archived accounts stay on device and can be brought back with one tap.")
                                .font(.footnote)
                                .foregroundStyle(BrandTheme.muted)

                            ForEach(archivedAccounts) { account in
                                accountRow(account)

                                if account.id != archivedAccounts.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(editingAccountID == nil ? "Add account" : "Edit account")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        FinanceField(label: "Account name", placeholder: "Emergency Fund", text: $name)
                        FinanceField(label: "Institution", placeholder: "Chase", text: $institution)
                        FinanceField(
                            label: "Current balance",
                            placeholder: "2500.00",
                            text: $balance,
                            keyboard: .decimalPad,
                            capitalization: .never
                        )

                        FinanceField(
                            label: "Notes (optional)",
                            placeholder: "Emergency fund, card reserve, payroll account...",
                            text: $note
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Account type")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BrandTheme.muted)

                            Picker("Account type", selection: $kind) {
                                ForEach(AccountKind.allCases) { item in
                                    Label(item.rawValue, systemImage: item.symbolName)
                                        .tag(item)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        Toggle("Active", isOn: $active)
                            .tint(BrandTheme.primary)

                        Toggle("Include in net worth", isOn: $includeInNetWorth)
                            .tint(BrandTheme.primary)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Text("Primary accounts stay easy to spot. Archiving hides a balance from the active list without deleting it, and net worth inclusion follows the toggle below.")
                            .font(.footnote)
                            .foregroundStyle(BrandTheme.muted)

                        Button(editingAccountID == nil ? "Save account" : "Save changes") {
                            Task { await saveAccount() }
                        }
                        .buttonStyle(PrimaryCTAStyle())

                        if editingAccountID != nil {
                            Button("Cancel edit") {
                                resetForm()
                            }
                            .buttonStyle(SecondaryCTAStyle())
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .navigationTitle("Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.ledger == nil {
                await viewModel.refreshDashboard()
            }
        }
    }

    private func accountRow(_ account: AccountRecord) -> some View {
        let balanceState = account.balanceState
        let isPrimary = primaryAccountID == account.id
        let isArchivedAccount = isArchived(account.id)
        let isIncluded = isIncludedInNetWorth(account.id)
        let accountNote = note(for: account.id)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: account.kind.symbolName)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.primary)
                    .frame(width: 42, height: 42)
                    .background(BrandTheme.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Text(account.summaryLabel)
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                    if !accountNote.isEmpty {
                        Text(accountNote)
                            .font(.footnote)
                            .foregroundStyle(BrandTheme.muted)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(account.balance, format: .currency(code: "USD"))
                        .font(.headline)
                        .foregroundStyle(balanceState == .liability ? .red : BrandTheme.ink)

                    Text(balanceState.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(balanceState == .liability ? .red : BrandTheme.muted)
                }
            }

            HStack(spacing: 8) {
                accountChip(title: account.kind.rawValue, systemImage: account.kind.symbolName)
                accountChip(title: balanceState.rawValue, systemImage: balanceState.symbolName)
                accountChip(
                    title: isIncluded ? "Included in net worth" : "Excluded from net worth",
                    systemImage: isIncluded ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis",
                    color: isIncluded ? BrandTheme.primary : BrandTheme.muted
                )
                accountChip(
                    title: isArchivedAccount ? "Archived" : "Active",
                    systemImage: isArchivedAccount ? "archivebox.fill" : "checkmark.circle.fill",
                    color: isArchivedAccount ? BrandTheme.muted : BrandTheme.primary
                )

                if isPrimary {
                    accountChip(title: "Primary", systemImage: "star.fill")
                } else {
                    Button("Make primary") {
                        Task { await viewModel.setPrimaryAccount(account.id) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Button("Edit") {
                    beginEdit(account)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button(isArchivedAccount ? "Restore" : "Archive") {
                    toggleArchive(account.id)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button(isIncluded ? "Exclude" : "Include") {
                    toggleNetWorthInclusion(account.id)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button(role: .destructive) {
                    Task { await viewModel.deleteAccount(account.id) }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private func beginEdit(_ account: AccountRecord) {
        editingAccountID = account.id
        name = account.name
        institution = account.institution
        balance = account.balance.description
        kind = account.kind
        note = note(for: account.id)
        active = !isArchived(account.id)
        includeInNetWorth = isIncludedInNetWorth(account.id)
        errorMessage = nil
    }

    private func resetForm() {
        editingAccountID = nil
        name = ""
        institution = ""
        balance = ""
        kind = .checking
        note = ""
        active = true
        includeInNetWorth = true
        errorMessage = nil
    }

    private func accountChip(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(BrandTheme.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(BrandTheme.primary.opacity(0.12))
            .clipShape(Capsule())
    }

    private func saveAccount() async {
        guard let balanceValue = FinanceToolFormatting.decimal(from: balance) else {
            errorMessage = "Enter a valid balance."
            return
        }

        let wasPrimary = editingAccount?.isPrimary ?? false
        let originalEditingID = editingAccountID
        let previousIDs = Set(viewModel.accounts.map(\.id))
        let draftedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        errorMessage = nil

        if let originalEditingID {
            await viewModel.deleteAccount(originalEditingID)
        }

        await viewModel.addAccount(
            AccountDraft(
                name: name,
                institution: institution,
                balance: balanceValue,
                kind: kind
            )
        )

        if wasPrimary, let newPrimaryID = viewModel.accounts.first?.id {
            await viewModel.setPrimaryAccount(newPrimaryID)
        }

        if let newAccountID = Set(viewModel.accounts.map(\.id)).subtracting(previousIDs).first {
            updateMetadata(for: newAccountID) { metadata in
                metadata.note = draftedNote
                metadata.isArchived = !active
                metadata.includeInNetWorth = includeInNetWorth
            }
        } else if let originalEditingID {
            updateMetadata(for: originalEditingID) { metadata in
                metadata.note = draftedNote
                metadata.isArchived = !active
                metadata.includeInNetWorth = includeInNetWorth
            }
        }

        resetForm()
    }

    private func accountChip(title: String, systemImage: String, color: Color = BrandTheme.primary) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func note(for accountID: UUID) -> String {
        displayMetadata[accountID.uuidString]?.note ?? ""
    }

    private func isArchived(_ accountID: UUID) -> Bool {
        displayMetadata[accountID.uuidString]?.isArchived ?? false
    }

    private func isIncludedInNetWorth(_ accountID: UUID) -> Bool {
        displayMetadata[accountID.uuidString]?.includeInNetWorth ?? true
    }

    private func updateMetadata(for accountID: UUID, mutate: (inout AccountDisplayMetadata) -> Void) {
        var metadata = displayMetadata
        var entry = metadata[accountID.uuidString] ?? AccountDisplayMetadata()
        mutate(&entry)
        metadata[accountID.uuidString] = entry
        displayMetadataJSON = encodeDisplayMetadata(metadata)
    }

    private func toggleArchive(_ accountID: UUID) {
        updateMetadata(for: accountID) { metadata in
            metadata.isArchived.toggle()
        }
    }

    private func toggleNetWorthInclusion(_ accountID: UUID) {
        updateMetadata(for: accountID) { metadata in
            metadata.includeInNetWorth.toggle()
        }
    }

    private func decodeDisplayMetadata(_ raw: String) -> [String: AccountDisplayMetadata] {
        guard let data = raw.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: AccountDisplayMetadata].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private func encodeDisplayMetadata(_ metadata: [String: AccountDisplayMetadata]) -> String {
        guard let data = try? JSONEncoder().encode(metadata),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }
}
