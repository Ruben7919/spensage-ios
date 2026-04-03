import SwiftUI

struct FinanceCsvImportToolView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var csvText = ""
    @State private var importError: String?

    private var preview: CSVImportPreview {
        CSVExpenseImportParser.parse(csvText, ledger: viewModel.ledger)
    }

    private var totalAmount: Decimal {
        preview.rows.reduce(Decimal.zero) { $0 + $1.draft.amount }
    }

    private var inferredCategoryCount: Int {
        preview.rows.filter { $0.source == .ruleMatch }.count
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

                        Text("Use headers like merchant, amount, category, date, note. The parser also accepts title, payee, description, memo, posted, and transaction date aliases.")
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
                                value: "\(preview.rows.count)",
                                systemImage: "checkmark.circle.fill"
                            )
                            BrandMetricTile(
                                title: "Skipped",
                                value: "\(preview.skippedLines.count)",
                                systemImage: "exclamationmark.triangle.fill"
                            )
                            BrandMetricTile(
                                title: "Total",
                                value: totalAmount.formatted(.currency(code: "USD")),
                                systemImage: "banknote.fill"
                            )
                            BrandMetricTile(
                                title: "Rule match",
                                value: "\(inferredCategoryCount)",
                                systemImage: "slider.horizontal.3"
                            )
                        }

                        if !preview.headers.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Detected columns")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(BrandTheme.muted)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(preview.headers, id: \.self) { header in
                                            Text(header)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(BrandTheme.primary)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(BrandTheme.primary.opacity(0.12))
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }

                        if preview.rows.isEmpty {
                            FinanceEmptyStateCard(
                                title: "Nothing ready yet",
                                summary: "Paste CSV text or load the sample dataset to preview importable rows.",
                                systemImage: "doc.text.magnifyingglass"
                            )
                        } else {
                            ForEach(preview.rows) { row in
                                previewRow(row)
                            }
                        }

                        if !preview.skippedLines.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Skipped lines")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(BrandTheme.muted)

                                ForEach(preview.skippedLines) { item in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.orange)
                                        Text("Line \(item.lineNumber): \(item.reason)")
                                            .font(.footnote)
                                            .foregroundStyle(BrandTheme.muted)
                                        Spacer()
                                    }
                                }
                            }
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
                        .disabled(preview.rows.isEmpty)
                        .opacity(preview.rows.isEmpty ? 0.6 : 1)
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

    private func previewRow(_ row: CSVImportRowPreview) -> some View {
        HStack(spacing: 12) {
            Image(systemName: row.draft.category.symbolName)
                .font(.headline)
                .foregroundStyle(BrandTheme.primary)
                .frame(width: 38, height: 38)
                .background(BrandTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(row.draft.merchant)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text("\(row.draft.category.rawValue) · \(row.draft.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
                if !row.draft.note.isEmpty {
                    Text(row.draft.note)
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }

                Label("Line \(row.lineNumber)", systemImage: row.source.symbolName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(row.source.color)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(row.draft.amount, format: .currency(code: "USD"))
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                Text(row.source.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(row.source.color)
            }
        }
    }

    private func importDrafts() async {
        guard !preview.rows.isEmpty else {
            importError = "Paste a valid CSV dataset first."
            return
        }

        importError = nil
        await viewModel.importExpenses(preview.rows.map(\.draft))
        csvText = ""
    }
}

private struct CSVImportPreview {
    var rows: [CSVImportRowPreview]
    var skippedLines: [CSVImportSkippedLine]
    var headers: [String]
}

private struct CSVImportRowPreview: Identifiable {
    let id = UUID()
    let lineNumber: Int
    let draft: ExpenseDraft
    let source: CSVImportSource
}

private struct CSVImportSkippedLine: Identifiable {
    let id = UUID()
    let lineNumber: Int
    let reason: String
}

private enum CSVImportSource: String {
    case explicitCategory = "Manual category"
    case ruleMatch = "Rule matched"
    case defaultCategory = "Default"

    var symbolName: String {
        switch self {
        case .explicitCategory: return "tag.fill"
        case .ruleMatch: return "sparkles"
        case .defaultCategory: return "circle.dashed"
        }
    }

    var color: Color {
        switch self {
        case .explicitCategory: return BrandTheme.primary
        case .ruleMatch: return .orange
        case .defaultCategory: return BrandTheme.muted
        }
    }
}

private enum CSVExpenseImportParser {
    static let sample = """
merchant,amount,category,date,note
Whole Foods,48.20,groceries,2026-04-01,Weekly restock
Uber,16.40,transport,2026-04-02,Airport ride
Dropbox,11.99,subscriptions,2026-04-02,Team files
"""

    private static let defaultHeaders = ["merchant", "amount", "category", "date", "note"]
    private static let merchantAliases: Set<String> = ["merchant", "title", "name", "payee", "vendor", "description"]
    private static let amountAliases: Set<String> = ["amount", "total", "price", "value", "charge"]
    private static let categoryAliases: Set<String> = ["category", "type", "classification"]
    private static let dateAliases: Set<String> = ["date", "posted", "transactiondate", "transaction_date"]
    private static let noteAliases: Set<String> = ["note", "memo", "details", "comment", "notes"]

    static func parse(_ text: String, ledger: LocalFinanceLedger?) -> CSVImportPreview {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else {
            return CSVImportPreview(rows: [], skippedLines: [], headers: [])
        }

        let delimiter = detectedDelimiter(in: lines.first ?? "")
        let rows = lines.map { parseRow($0, delimiter: delimiter) }
        let headers = normalizedHeaders(for: rows.first ?? [])
        let hasHeaderRow = containsKnownHeader(headers)
        let bodyRows = hasHeaderRow ? Array(rows.dropFirst()) : rows
        let effectiveHeaders = hasHeaderRow ? headers : defaultHeaders

        var drafts: [CSVImportRowPreview] = []
        var skippedLines: [CSVImportSkippedLine] = []

        for (index, row) in bodyRows.enumerated() {
            let lineNumber = index + (hasHeaderRow ? 2 : 1)
            guard let result = makeDraft(from: row, headers: effectiveHeaders, ledger: ledger) else {
                skippedLines.append(CSVImportSkippedLine(lineNumber: lineNumber, reason: "Missing merchant or amount"))
                continue
            }
            drafts.append(
                CSVImportRowPreview(
                    lineNumber: lineNumber,
                    draft: result.draft,
                    source: result.source
                )
            )
        }

        return CSVImportPreview(rows: drafts, skippedLines: skippedLines, headers: hasHeaderRow ? displayHeaders(for: headers) : [])
    }

    private static func normalizedHeaders(for row: [String]) -> [String] {
        row.map {
            $0
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "_", with: "")
                .replacingOccurrences(of: "-", with: "")
        }
    }

    private static func containsKnownHeader(_ headers: [String]) -> Bool {
        headers.contains {
            merchantAliases.contains($0) ||
            amountAliases.contains($0) ||
            categoryAliases.contains($0) ||
            dateAliases.contains($0) ||
            noteAliases.contains($0)
        }
    }

    private static func makeDraft(from row: [String], headers: [String], ledger: LocalFinanceLedger?) -> (draft: ExpenseDraft, source: CSVImportSource)? {
        var values: [String: String] = [:]
        for (index, value) in row.enumerated() where index < headers.count {
            values[headers[index]] = value.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let merchant = firstValue(in: values, matching: merchantAliases)
        guard
            let merchant,
            !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            let amount = FinanceToolFormatting.decimal(from: firstValue(in: values, matching: amountAliases) ?? "")
        else {
            return nil
        }

        let categoryText = firstValue(in: values, matching: categoryAliases) ?? ""
        let category: ExpenseCategory
        let source: CSVImportSource
        if let explicitCategory = ExpenseCategory.allCases.first(where: {
            $0.rawValue.lowercased() == categoryText.lowercased() || $0.id.lowercased() == categoryText.lowercased()
        }) {
            category = explicitCategory
            source = .explicitCategory
        } else if let inferredCategory = ledger?.inferredCategory(for: merchant) {
            category = inferredCategory
            source = .ruleMatch
        } else {
            category = .other
            source = .defaultCategory
        }

        let dateValue = firstValue(in: values, matching: dateAliases) ?? ""
        let date = parsedDate(from: dateValue) ?? .now
        let note = firstValue(in: values, matching: noteAliases) ?? ""

        return (
            ExpenseDraft(
            merchant: merchant,
            amount: amount,
            category: category,
            date: date,
            note: note
            ),
            source
        )
    }

    private static func firstValue(in values: [String: String], matching aliases: Set<String>) -> String? {
        aliases.compactMap { values[$0] }.first
    }

    private static func displayHeaders(for headers: [String]) -> [String] {
        headers.map {
            switch $0 {
            case "merchant", "title", "name", "payee", "vendor", "description":
                return "Merchant"
            case "amount", "total", "price", "value", "charge":
                return "Amount"
            case "category", "type", "classification":
                return "Category"
            case "date", "posted", "transactiondate", "transaction_date":
                return "Date"
            case "note", "memo", "details", "comment", "notes":
                return "Note"
            default:
                return $0.capitalized
            }
        }
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

    private static func detectedDelimiter(in line: String) -> Character {
        let candidates: [Character] = [",", ";", "\t", "|"]
        return candidates.max(by: { delimiterCount($0, in: line) < delimiterCount($1, in: line) }) ?? ","
    }

    private static func delimiterCount(_ delimiter: Character, in line: String) -> Int {
        line.filter { $0 == delimiter }.count
    }

    private static func parseRow(_ line: String, delimiter: Character) -> [String] {
        var values: [String] = []
        var current = ""
        var insideQuotes = false

        for character in line {
            switch character {
            case "\"":
                insideQuotes.toggle()
            case delimiter where !insideQuotes:
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
