import SwiftUI

struct FinanceCsvImportToolView: View {
    @ObservedObject var viewModel: AppViewModel
    @AppStorage(AppCurrencyFormat.defaultsKey) private var currencyCode = AppCurrencyFormat.defaultCode

    @State private var csvText = ""
    @State private var importError: String?
    @State private var templateKind: TemplateKind = .simple
    @State private var hasHeaderRow = true
    @State private var showingTemplatePreview = false

    private var preview: CSVImportPreview {
        CSVExpenseImportParser.parse(csvText, ledger: viewModel.ledger, hasHeaderRow: hasHeaderRow)
    }

    private var totalAmount: Decimal {
        preview.rows.reduce(Decimal.zero) { $0 + $1.draft.amount }
    }

    private var inferredCategoryCount: Int {
        preview.rows.filter { $0.source == .ruleMatch }.count
    }

    private var flowStage: String {
        if csvText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Elegir"
        }
        if preview.rows.isEmpty {
            return "Mapear"
        }
        return "Vista previa"
    }

    private var templateSummary: String {
        switch templateKind {
        case .simple:
            return AppLocalization.localized(
                "Simple CSV template with merchant, amount, category, date, and note columns. Headers are %@, so the first row can stay readable when you paste or preview a file.",
                arguments: (hasHeaderRow ? "enabled" : "disabled").appLocalized
            )
        case .debitCredit:
            return AppLocalization.localized(
                "Debit / credit template for statements that split charges and credits into separate columns. Headers are %@, so you can keep the first row readable while checking the mapping.",
                arguments: (hasHeaderRow ? "enabled" : "disabled").appLocalized
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Pegar e importar",
                    title: "Importar CSV",
                    summary: "Pega una exportación CSV simple, revisa las filas válidas y trae transacciones al libro local en un solo paso.",
                    systemImage: "tablecells.fill",
                    surface: .csvImport
                )

                if let notice = viewModel.notice {
                    FinanceNoticeCard(message: notice)
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Flujo de importación")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)
                            Spacer()
                            BrandBadge(text: flowStage, systemImage: "arrow.right.circle.fill")
                        }

                        Text("Elige una plantilla, revisa el archivo pegado y luego mira qué aterrizará en el libro.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)

                        HStack(spacing: 8) {
                            flowChip(title: "Elegir", isActive: flowStage == "Elegir", systemImage: "square.and.pencil")
                            flowChip(title: "Mapear", isActive: flowStage == "Mapear", systemImage: "slider.horizontal.3")
                            flowChip(title: "Vista previa", isActive: flowStage == "Vista previa", systemImage: "doc.text.magnifyingglass")
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Plantillas y presets")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text("Elige una plantilla, carga un ejemplo y mira la forma exacta del CSV antes de importar.")
                            .foregroundStyle(BrandTheme.muted)

                        Picker("Plantilla", selection: $templateKind) {
                            ForEach(TemplateKind.allCases) { kind in
                                Text(kind.localizedTitle).tag(kind)
                            }
                        }
                        .pickerStyle(.segmented)

                        Toggle("Encabezados en la primera fila", isOn: $hasHeaderRow)
                            .tint(BrandTheme.primary)

                        HStack(spacing: 12) {
                            Button("Cargar ejemplo") {
                                csvText = templateKind.sampleCSV
                            }
                            .buttonStyle(SecondaryCTAStyle())

                            Button("Ver plantilla") {
                                showingTemplatePreview = true
                            }
                            .buttonStyle(SecondaryCTAStyle())

                            Button("Limpiar") {
                                csvText = ""
                                importError = nil
                            }
                            .buttonStyle(SecondaryCTAStyle())
                        }

                        BrandFeatureRow(
                            systemImage: "rectangle.on.rectangle.angled",
                            title: "Guía de plantilla",
                            detail: templateSummary
                        )

                        BrandFeatureRow(
                            systemImage: "slider.horizontal.3",
                            title: "Pista de mapeo",
                            detail: "Alias de comercio, monto, categoría, fecha y nota se reconocen automáticamente para que un estado pegado siga previsualizándose bien."
                        )
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Columnas esperadas")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text("Usa encabezados como merchant, amount, category, date y note. El parser también acepta alias como title, payee, description, memo, posted y transaction date.")
                            .foregroundStyle(BrandTheme.muted)

                        Text("Alias como merchant/title/payee, amount/total/price y date/posted ya se reconocen para mantener la importación rápida.")
                            .font(.footnote)
                            .foregroundStyle(BrandTheme.muted)
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        FinanceMultilineField(
                            label: "Pega el texto CSV",
                            placeholder: CSVExpenseImportParser.sample,
                            text: $csvText,
                            accessibilityIdentifier: "csvImport.field.rawText"
                        )
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Vista previa de importación")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                            spacing: 12
                        ) {
                            BrandMetricTile(
                                title: "Filas listas",
                                value: "\(preview.rows.count)",
                                systemImage: "checkmark.circle.fill"
                            )
                            BrandMetricTile(
                                title: "Saltadas",
                                value: "\(preview.skippedLines.count)",
                                systemImage: "exclamationmark.triangle.fill"
                            )
                            BrandMetricTile(
                                title: "Total",
                                value: totalAmount.formatted(.currency(code: currencyCode)),
                                systemImage: "banknote.fill"
                            )
                            BrandMetricTile(
                                title: "Regla aplicada",
                                value: "\(inferredCategoryCount)",
                                systemImage: "slider.horizontal.3"
                            )
                        }

                        if !preview.headers.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Columnas detectadas")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(BrandTheme.muted)

                                FlowStack(spacing: 8, rowSpacing: 8) {
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

                        if preview.rows.isEmpty {
                            FinanceEmptyStateCard(
                                title: "Todavía no hay nada listo",
                                summary: "Pega texto CSV o carga el ejemplo para revisar filas importables.",
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
                                        Text(
                                            AppLocalization.localized(
                                                "Line %d: %@",
                                                arguments: item.lineNumber,
                                                item.reason.appLocalized
                                            )
                                        )
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
                        .accessibilityIdentifier("csvImport.action.import")
                        .disabled(preview.rows.isEmpty)
                        .opacity(preview.rows.isEmpty ? 0.6 : 1)
                    }
                }
            }
            .padding(24)
        }
        .background(FinanceScreenBackground())
        .accessibilityIdentifier("csvImport.screen")
        .navigationTitle("CSV Import")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTemplatePreview) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        SurfaceCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Template preview")
                                    .font(.headline)
                                    .foregroundStyle(BrandTheme.ink)

                                Text("This is the exact sample layout that loads into the paste field.")
                                    .foregroundStyle(BrandTheme.muted)

                                Text(templateKind.sampleCSV)
                                    .font(.system(.footnote, design: .monospaced))
                                    .foregroundStyle(BrandTheme.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(14)
                                    .background(BrandTheme.surfaceTint)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(24)
                    }
                }
                .background(BrandTheme.canvas)
                .navigationTitle("Template Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            showingTemplatePreview = false
                        }
                    }
                }
            }
        }
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
                Text("\(row.draft.category.localizedTitle) · \(row.draft.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
                if !row.draft.note.isEmpty {
                    Text(row.draft.note)
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }

                Label(AppLocalization.localized("Line %d", arguments: row.lineNumber), systemImage: row.source.symbolName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(row.source.color)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(row.draft.amount, format: .currency(code: currencyCode))
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                Text(row.source.localizedTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(row.source.color)
            }
        }
    }

    private func flowChip(title: String, isActive: Bool, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
            Text(title.appLocalized)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(isActive ? BrandTheme.primary : BrandTheme.muted)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background((isActive ? BrandTheme.primary : BrandTheme.muted).opacity(0.12))
        .clipShape(Capsule())
    }

    private func importDrafts() async {
        guard !preview.rows.isEmpty else {
            importError = "Paste a valid CSV dataset first.".appLocalized
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

    var localizedTitle: String {
        rawValue.appLocalized
    }

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

private enum TemplateKind: String, CaseIterable, Identifiable {
    case simple = "Simple"
    case debitCredit = "Debit / credit"

    var id: String { rawValue }

    var localizedTitle: String {
        rawValue.appLocalized
    }

    var sampleCSV: String {
        switch self {
        case .simple:
            return CSVExpenseImportParser.simpleSample
        case .debitCredit:
            return CSVExpenseImportParser.debitCreditSample
        }
    }
}

private enum CSVExpenseImportParser {
    static let simpleSample = """
merchant,amount,category,date,note
Whole Foods,48.20,groceries,2026-04-01,Weekly restock
Uber,16.40,transport,2026-04-02,Airport ride
Dropbox,11.99,subscriptions,2026-04-02,Team files
"""

    static let debitCreditSample = """
date,description,debit,credit,merchant
2026-04-01,Coffee run,4.80,,Morning Grounds
2026-04-02,Refund,,16.40,Ride Share
2026-04-02,Grocery top-up,86.40,,Supermarket
"""

    static let sample = simpleSample

    private static let defaultHeaders = ["merchant", "amount", "category", "date", "note"]
    private static let merchantAliases: Set<String> = ["merchant", "title", "name", "payee", "vendor", "description"]
    private static let amountAliases: Set<String> = ["amount", "total", "price", "value", "charge"]
    private static let categoryAliases: Set<String> = ["category", "type", "classification"]
    private static let dateAliases: Set<String> = ["date", "posted", "transactiondate", "transaction_date"]
    private static let noteAliases: Set<String> = ["note", "memo", "details", "comment", "notes"]

    static func parse(_ text: String, ledger: LocalFinanceLedger?, hasHeaderRow: Bool? = nil) -> CSVImportPreview {
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
        let inferredHasHeaderRow = containsKnownHeader(headers)
        let effectiveHasHeaderRow = hasHeaderRow ?? inferredHasHeaderRow
        let bodyRows = effectiveHasHeaderRow ? Array(rows.dropFirst()) : rows
        let effectiveHeaders = effectiveHasHeaderRow ? headers : defaultHeaders

        var drafts: [CSVImportRowPreview] = []
        var skippedLines: [CSVImportSkippedLine] = []

        for (index, row) in bodyRows.enumerated() {
            let lineNumber = index + (effectiveHasHeaderRow ? 2 : 1)
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

        return CSVImportPreview(rows: drafts, skippedLines: skippedLines, headers: effectiveHasHeaderRow ? displayHeaders(for: headers) : [])
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
