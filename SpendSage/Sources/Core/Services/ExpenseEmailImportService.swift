import Foundation

enum ExpenseEmailImportService {
    static func analyze(_ text: String, locale: Locale = .autoupdatingCurrent) -> ReceiptScanAnalysis {
        let cleanedText = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        let rawLines = cleanedText
            .components(separatedBy: .newlines)
            .map {
                $0.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }

        let projectedLines = rawLines.flatMap { line -> [String] in
            var items = [line]
            if line.contains(":") {
                items.append(contentsOf: line.split(separator: ":").map {
                    String($0).trimmingCharacters(in: .whitespacesAndNewlines)
                })
            }
            return items
        }
        .filter { !$0.isEmpty }

        let analysis = ReceiptVisionService.parse(recognizedLines: projectedLines, locale: locale)
        let merchant = detectedMerchant(from: projectedLines) ?? analysis.merchant
        let category = analysis.category ?? merchant.flatMap { ReceiptVisionService.parse(recognizedLines: [$0], locale: locale).category }

        return ReceiptScanAnalysis(
            recognizedText: rawLines.joined(separator: "\n"),
            merchant: merchant,
            amount: analysis.amount,
            date: analysis.date,
            category: category
        )
    }

    private static func detectedMerchant(from lines: [String]) -> String? {
        let merchantKeys = [
            "merchant", "store", "seller", "vendor", "business", "comercio", "tienda",
            "pedido en", "order from", "purchase from", "payment to", "bill from"
        ]

        for line in lines {
            let normalized = line.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            for key in merchantKeys where normalized.contains(key) {
                if let value = merchantValue(from: line) {
                    return value
                }
            }
        }

        return lines.first(where: candidateLooksLikeMerchant)
    }

    private static func merchantValue(from line: String) -> String? {
        if let range = line.range(of: ":") {
            let suffix = line[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
            return candidateLooksLikeMerchant(suffix) ? suffix : nil
        }

        let lowered = line.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let leadingFragments = [
            "order from ", "purchase from ", "payment to ", "bill from ", "pedido en "
        ]

        for fragment in leadingFragments where lowered.hasPrefix(fragment) {
            let dropped = String(line.dropFirst(fragment.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            return candidateLooksLikeMerchant(dropped) ? dropped : nil
        }

        return candidateLooksLikeMerchant(line) ? line : nil
    }

    private static func candidateLooksLikeMerchant(_ value: String) -> Bool {
        let letters = value.filter(\.isLetter).count
        let digits = value.filter(\.isNumber).count
        guard letters >= 3 else { return false }

        let normalized = value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let blocked = [
            "unsubscribe", "support", "total", "subtotal", "tax", "impuesto", "visa",
            "mastercard", "order number", "confirmation", "confirmacion", "help", "receipt"
        ]
        return digits < letters && !blocked.contains(where: normalized.contains)
    }
}
