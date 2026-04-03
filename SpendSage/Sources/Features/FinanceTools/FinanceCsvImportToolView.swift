import SwiftUI

struct FinanceCsvImportToolView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var csvText = ""
    @State private var importError: String?

    private var preview: CSVImportPreview {
        CSVExpenseImportParser.parse(csvText, ledger: viewModel.ledger)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Paste and import",
                    title: "CSV Import",
                    summary: "Paste a simple CSV export, preview valid rows, and bring transactions into the local ledger in one step.",
                    systemImage: "tablecells.fill"
                )

                if let notice = viewModel.notice {
                    FinanceNoticeCard(message: notice)
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Expected columns")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text("Use headers like merchant, amount, category, date, note. If category is missing, saved rules are applied when possible.")
                            .foregroundStyle(BrandTheme.muted)

                        HStack(spacing: 12) {
                            Button("Load sample dataset") {
                                csvText = CSVExpenseImportParser.sample
                            }
                            .buttonStyle(SecondaryCTAStyle())

                            Button("Clear") {
                                csvText = ""
                                importError = nil
                            }
                            .buttonStyle(SecondaryCTAStyle())
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        FinanceMultilineField(
                            label: "Paste CSV text",
                            placeholder: CSVExpenseImportParser.sample,
                            text: $csvText
                        )
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Import preview")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        HStack(spacing: 12) {
                            BrandMetricTile(
                                title: "Ready rows",
                                value: "\(preview.drafts.count)",
                                systemImage: "checkmark.circle.fill"
                            )
                            BrandMetricTile(
                                title: "Skipped",
                                value: "\(preview.skippedLines.count)",
                                systemImage: "exclamationmark.triangle.fill"
                            )
                        }

                        if preview.drafts.isEmpty {
                            FinanceEmptyStateCard(
                                title: "Nothing ready yet",
                                summary: "Paste CSV text or load the sample dataset to preview importable rows.",
                                systemImage: "doc.text.magnifyingglass"
                            )
                        } else {
                            ForEach(Array(preview.drafts.enumerated()), id: \.offset) { _, draft in
                                previewRow(draft)
                            }
                        }

                        if !preview.skippedLines.isEmpty {
                            Text("Skipped lines: \(preview.skippedLines.joined(separator: ", "))")
                                .font(.footnote)
                                .foregroundStyle(BrandTheme.muted)
                        }

                        if let importError {
                            Text(importError)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Button("Import into ledger") {
                            Task { await importDrafts() }
                        }
                        .buttonStyle(PrimaryCTAStyle())
                        .disabled(preview.drafts.isEmpty)
                        .opacity(preview.drafts.isEmpty ? 0.6 : 1)
                    }
                }
            }
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .navigationTitle("CSV Import")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.ledger == nil {
                await viewModel.refreshDashboard()
            }
        }
    }

    private func previewRow(_ draft: ExpenseDraft) -> some View {
        HStack(spacing: 12) {
            Image(systemName: draft.category.symbolName)
                .font(.headline)
                .foregroundStyle(BrandTheme.primary)
                .frame(width: 38, height: 38)
                .background(BrandTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(draft.merchant)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text("\(draft.category.rawValue) · \(draft.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
                if !draft.note.isEmpty {
                    Text(draft.note)
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }
            }

            Spacer()

            Text(draft.amount, format: .currency(code: "USD"))
                .font(.headline)
                .foregroundStyle(BrandTheme.ink)
        }
    }

    private func importDrafts() async {
        guard !preview.drafts.isEmpty else {
            importError = "Paste a valid CSV dataset first."
            return
        }

        importError = nil
        await viewModel.importExpenses(preview.drafts)
        csvText = ""
    }
}

private struct CSVImportPreview {
    var drafts: [ExpenseDraft]
    var skippedLines: [String]
}

private enum CSVExpenseImportParser {
    static let sample = """
merchant,amount,category,date,note
Whole Foods,48.20,groceries,2026-04-01,Weekly restock
Uber,16.40,transport,2026-04-02,Airport ride
Dropbox,11.99,subscriptions,2026-04-02,Team files
"""

    private static let defaultHeaders = ["merchant", "amount", "category", "date", "note"]

    static func parse(_ text: String, ledger: LocalFinanceLedger?) -> CSVImportPreview {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else {
            return CSVImportPreview(drafts: [], skippedLines: [])
        }

        let rows = lines.map(parseRow)
        let headers = normalizedHeaders(for: rows.first ?? [])
        let hasHeaderRow = headers.contains("merchant") || headers.contains("amount")
        let bodyRows = hasHeaderRow ? Array(rows.dropFirst()) : rows
        let effectiveHeaders = hasHeaderRow ? headers : defaultHeaders

        var drafts: [ExpenseDraft] = []
        var skippedLines: [String] = []

        for (index, row) in bodyRows.enumerated() {
            guard let draft = makeDraft(from: row, headers: effectiveHeaders, ledger: ledger) else {
                skippedLines.append("\(index + (hasHeaderRow ? 2 : 1))")
                continue
            }
            drafts.append(draft)
        }

        return CSVImportPreview(drafts: drafts, skippedLines: skippedLines)
    }

    private static func normalizedHeaders(for row: [String]) -> [String] {
        row.map {
            $0
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
                .replacingOccurrences(of: " ", with: "")
        }
    }

    private static func makeDraft(from row: [String], headers: [String], ledger: LocalFinanceLedger?) -> ExpenseDraft? {
        var values: [String: String] = [:]
        for (index, value) in row.enumerated() where index < headers.count {
            values[headers[index]] = value.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let merchant = values["merchant"] ?? values["title"] ?? values["name"] ?? ""
        guard
            !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            let amount = FinanceToolFormatting.decimal(from: values["amount"] ?? "")
        else {
            return nil
        }

        let categoryText = values["category"] ?? ""
        let category = ExpenseCategory.allCases.first {
            $0.rawValue.lowercased() == categoryText.lowercased() || $0.id.lowercased() == categoryText.lowercased()
        } ?? ledger?.inferredCategory(for: merchant) ?? .other

        let date = parsedDate(from: values["date"] ?? "") ?? .now
        let note = values["note"] ?? values["memo"] ?? ""

        return ExpenseDraft(
            merchant: merchant,
            amount: amount,
            category: category,
            date: date,
            note: note
        )
    }

    private static func parsedDate(from value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let isoFormatter = ISO8601DateFormatter()
        if let isoDate = isoFormatter.date(from: trimmed) {
            return isoDate
        }

        for format in ["yyyy-MM-dd", "MM/dd/yyyy", "M/d/yyyy", "MM-dd-yyyy", "M-d-yyyy"] {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = .autoupdatingCurrent
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        return nil
    }

    private static func parseRow(_ line: String) -> [String] {
        var values: [String] = []
        var current = ""
        var insideQuotes = false

        for character in line {
            switch character {
            case "\"":
                insideQuotes.toggle()
            case "," where !insideQuotes:
                values.append(current)
                current = ""
            default:
                current.append(character)
            }
        }

        values.append(current)
        return values
    }
}
