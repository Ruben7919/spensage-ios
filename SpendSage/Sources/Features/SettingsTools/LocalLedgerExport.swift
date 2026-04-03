import Foundation

enum PublicLegalLinks {
    static let privacy = URL(string: "https://cz2vxbcze4.execute-api.us-east-1.amazonaws.com/dev/public/legal/privacy-policy")!
    static let support = URL(string: "https://cz2vxbcze4.execute-api.us-east-1.amazonaws.com/dev/public/legal/support-and-contact")!
    static let terms = URL(string: "https://cz2vxbcze4.execute-api.us-east-1.amazonaws.com/dev/public/legal/terms-of-service")!
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
        let lastUpdated = viewModel.ledger?.updatedAt.formatted(date: .abbreviated, time: .shortened) ?? "Not yet saved"

        var lines = [
            "SpendSage local summary",
            "Exported: \(Date.now.formatted(date: .abbreviated, time: .shortened))",
            "Session: \(sessionMode)",
            "Profile: \(profile.fullName) · \(profile.householdName)",
            "Email: \(profile.email)",
            "Country: \(profile.countryCode)",
            "Marketing opt-in: \(profile.marketingOptIn ? "Enabled" : "Disabled")",
            "Accounts: \(accountsCount)",
            "Bills: \(billsCount)",
            "Rules: \(rulesCount)",
            "Expenses: \(expensesCount)",
            "Last local update: \(lastUpdated)"
        ]

        if let snapshot = state?.budgetSnapshot {
            lines.append("Income: \(currency(snapshot.monthlyIncome))")
            lines.append("Budget: \(currency(snapshot.monthlyBudget))")
            lines.append("Spent: \(currency(snapshot.monthlySpent))")
            lines.append("Remaining: \(currency(snapshot.remaining))")
        }

        if let topCategory = state?.topCategory {
            lines.append("Top category: \(topCategory.category.rawValue) · \(currency(topCategory.total))")
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
            "SpendSage support packet",
            "Issue type: \(issueType)",
            "Subject: \(subject.trimmingCharacters(in: .whitespacesAndNewlines))",
            "",
            "Details:",
            trimmedDetail.isEmpty ? "No extra details provided." : trimmedDetail
        ]

        if includeDiagnostics {
            sections.append("")
            sections.append(readableSummary(viewModel: viewModel))
        }

        sections.append("")
        sections.append("Public support: \(PublicLegalLinks.support.absoluteString)")
        return sections.joined(separator: "\n")
    }

    static func sessionLabel(for session: SessionState) -> String {
        switch session {
        case .signedOut:
            return "Signed out"
        case .guest:
            return "Guest local mode"
        case let .signedIn(email, provider):
            if let provider, !provider.isEmpty {
                return "Signed in as \(email) via \(provider)"
            }
            return "Signed in as \(email)"
        }
    }

    static func currency(_ value: Decimal) -> String {
        value.formatted(.currency(code: "USD"))
    }
}
