import Foundation

enum PublicLegalLinks {
    static let privacy = URL(string: "https://legal.spendsage.ai/privacy")!
    static let support = URL(string: "https://legal.spendsage.ai/support")!
    static let terms = URL(string: "https://legal.spendsage.ai/terms")!
}

private struct LocalExportPayload: Encodable {
    struct Counts: Encodable {
        let expenses: Int
        let accounts: Int
        let bills: Int
        let rules: Int
    }

    struct Budget: Encodable {
        let income: Decimal
        let budget: Decimal
        let spent: Decimal
        let remaining: Decimal
    }

    let exportedAt: Date
    let sessionMode: String
    let profile: ProfileRecord
    let counts: Counts
    let budget: Budget?
    let lastUpdated: Date?
}

enum LocalLedgerExportComposer {
    @MainActor
    static func readableSummary(viewModel: AppViewModel) -> String {
        let profile = viewModel.profile
        let state = viewModel.dashboardState
        let expensesCount = state?.transactionCount ?? 0
        let accountsCount = viewModel.accounts.count
        let billsCount = viewModel.bills.count
        let rulesCount = viewModel.rules.count
        let sessionMode = sessionLabel(for: viewModel.session)
        let lastUpdated = viewModel.ledger?.updatedAt.formatted(date: .abbreviated, time: .shortened) ?? "Not yet saved".appLocalized

        var lines = [
            "SpendSage local summary".appLocalized,
            AppLocalization.localized("Exported: %@", arguments: Date.now.formatted(date: .abbreviated, time: .shortened)),
            AppLocalization.localized("Session: %@", arguments: sessionMode),
            AppLocalization.localized("Profile: %@ · %@", arguments: profile.fullName, profile.householdName),
            AppLocalization.localized("Email: %@", arguments: profile.email),
            AppLocalization.localized("Country: %@", arguments: profile.countryCode),
            AppLocalization.localized("Marketing opt-in: %@", arguments: profile.marketingOptIn ? "Enabled".appLocalized : "Disabled".appLocalized),
            AppLocalization.localized("Accounts: %d", arguments: accountsCount),
            AppLocalization.localized("Bills: %d", arguments: billsCount),
            AppLocalization.localized("Rules: %d", arguments: rulesCount),
            AppLocalization.localized("Expenses: %d", arguments: expensesCount),
            AppLocalization.localized("Last local update: %@", arguments: lastUpdated)
        ]

        if let snapshot = state?.budgetSnapshot {
            lines.append(AppLocalization.localized("Income: %@", arguments: currency(snapshot.monthlyIncome)))
            lines.append(AppLocalization.localized("Budget: %@", arguments: currency(snapshot.monthlyBudget)))
            lines.append(AppLocalization.localized("Spent: %@", arguments: currency(snapshot.monthlySpent)))
            lines.append(AppLocalization.localized("Remaining: %@", arguments: currency(snapshot.remaining)))
        }

        if let topCategory = state?.topCategory {
            lines.append(AppLocalization.localized("Top category: %@ · %@", arguments: topCategory.category.localizedTitle, currency(topCategory.total)))
        }

        return lines.joined(separator: "\n")
    }

    @MainActor
    static func jsonSnapshot(viewModel: AppViewModel) -> String {
        let state = viewModel.dashboardState
        let payload = LocalExportPayload(
            exportedAt: .now,
            sessionMode: sessionLabel(for: viewModel.session),
            profile: viewModel.profile,
            counts: .init(
                expenses: state?.transactionCount ?? 0,
                accounts: viewModel.accounts.count,
                bills: viewModel.bills.count,
                rules: viewModel.rules.count
            ),
            budget: state.map {
                .init(
                    income: $0.budgetSnapshot.monthlyIncome,
                    budget: $0.budgetSnapshot.monthlyBudget,
                    spent: $0.budgetSnapshot.monthlySpent,
                    remaining: $0.budgetSnapshot.remaining
                )
            },
            lastUpdated: viewModel.ledger?.updatedAt
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(payload), let string = String(data: data, encoding: .utf8) else {
            return "{\n  \"error\": \"Unable to encode local snapshot\"\n}"
        }
        return string
    }

    @MainActor
    static func supportPacket(
        viewModel: AppViewModel,
        issueType: String,
        subject: String,
        detail: String,
        includeDiagnostics: Bool
    ) -> String {
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        var sections = [
            "SpendSage support packet".appLocalized,
            AppLocalization.localized("Issue type: %@", arguments: issueType),
            AppLocalization.localized("Subject: %@", arguments: subject.trimmingCharacters(in: .whitespacesAndNewlines)),
            "",
            "Details:".appLocalized,
            trimmedDetail.isEmpty ? "No extra details provided.".appLocalized : trimmedDetail
        ]

        if includeDiagnostics {
            sections.append("")
            sections.append(readableSummary(viewModel: viewModel))
        }

        sections.append("")
        sections.append(AppLocalization.localized("Public support: %@", arguments: PublicLegalLinks.support.absoluteString))
        return sections.joined(separator: "\n")
    }

    static func sessionLabel(for session: SessionState) -> String {
        switch session {
        case .signedOut:
            return "Signed out".appLocalized
        case .guest:
            return "Preview guest mode".appLocalized
        case let .signedIn(email, provider):
            if let provider, !provider.isEmpty {
                return AppLocalization.localized("Signed in as %@ via %@", arguments: email, provider)
            }
            return AppLocalization.localized("Signed in as %@", arguments: email)
        }
    }

    static func currency(_ value: Decimal) -> String {
        AppCurrencyFormat.format(value)
    }
}
