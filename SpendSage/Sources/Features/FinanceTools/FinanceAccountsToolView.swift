import SwiftUI

struct FinanceAccountsToolView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var name = ""
    @State private var institution = ""
    @State private var balance = ""
    @State private var kind = AccountKind.checking
    @State private var errorMessage: String?

    private var totalBalance: Decimal {
        viewModel.ledger?.totalAccountBalance() ?? 0
    }

    private var liquidBalance: Decimal {
        viewModel.ledger?.liquidAccountBalance() ?? 0
    }

    private var creditExposure: Decimal {
        viewModel.ledger?.creditExposure() ?? 0
    }

    private var primaryAccountID: UUID? {
        viewModel.ledger?.primaryAccount?.id
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Local-first accounts",
                    title: "Accounts",
                    summary: "Track cash, cards, savings, and investment balances without leaving your device.",
                    systemImage: "wallet.pass.fill"
                )

                if let notice = viewModel.notice {
                    FinanceNoticeCard(message: notice)
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Portfolio snapshot")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        HStack(spacing: 12) {
                            BrandMetricTile(
                                title: "Accounts",
                                value: "\(viewModel.accounts.count)",
                                systemImage: "square.stack.3d.up.fill"
                            )
                            BrandMetricTile(
                                title: "Balance",
                                value: totalBalance.formatted(.currency(code: "USD")),
                                systemImage: "banknote.fill"
                            )
                            BrandMetricTile(
                                title: "Liquid",
                                value: liquidBalance.formatted(.currency(code: "USD")),
                                systemImage: "arrow.up.circle.fill"
                            )
                            BrandMetricTile(
                                title: "Exposure",
                                value: creditExposure.formatted(.currency(code: "USD")),
                                systemImage: "arrow.down.circle.fill"
                            )
                        }
                    }
                }

                if viewModel.accounts.isEmpty {
                    FinanceEmptyStateCard(
                        title: "No accounts yet",
                        summary: "Add your first checking, savings, or credit card balance to anchor the rest of the ledger.",
                        systemImage: "tray.fill"
                    )
                } else {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Saved accounts")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)

                            ForEach(viewModel.accounts) { account in
                                accountRow(account)

                                if account.id != viewModel.accounts.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Add account")
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

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Button("Save account") {
                            Task { await saveAccount() }
                        }
                        .buttonStyle(PrimaryCTAStyle())
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

                if isPrimary {
                    accountChip(title: "Primary", systemImage: "star.fill")
                } else {
                    Button("Make primary") {
                        Task { await viewModel.setPrimaryAccount(account.id) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

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

        errorMessage = nil
        await viewModel.addAccount(
            AccountDraft(
                name: name,
                institution: institution,
                balance: balanceValue,
                kind: kind
            )
        )

        name = ""
        institution = ""
        balance = ""
        kind = .checking
    }
}
