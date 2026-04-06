import Foundation
import ImageIO
import UIKit
import Vision

struct ReceiptScanAnalysis: Equatable {
    let recognizedText: String
    let merchant: String?
    let amount: Decimal?
    let date: Date?
    let category: ExpenseCategory?

    var hasDetectedValues: Bool {
        merchant != nil || amount != nil || date != nil
    }
}

enum ReceiptVisionServiceError: LocalizedError {
    case unsupportedImage

    var errorDescription: String? {
        switch self {
        case .unsupportedImage:
            return "We could not read text from this image.".appLocalized
        }
    }
}

enum ReceiptVisionService {
    static func analyze(image: UIImage, locale: Locale = .autoupdatingCurrent) async throws -> ReceiptScanAnalysis {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let analysis = try analyzeSynchronously(image: image, locale: locale)
                    continuation.resume(returning: analysis)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    static func parse(recognizedLines: [String], locale: Locale = .autoupdatingCurrent) -> ReceiptScanAnalysis {
        let lines = recognizedLines
            .map(normalizedLine)
            .filter { !$0.isEmpty }

        let merchant = detectedMerchant(from: lines)
        let amount = detectedAmount(from: lines)
        let date = detectedDate(from: lines, locale: locale)
        let category = merchant.flatMap(suggestedCategory(for:))

        return ReceiptScanAnalysis(
            recognizedText: lines.joined(separator: "\n"),
            merchant: merchant,
            amount: amount,
            date: date,
            category: category
        )
    }

    private static func analyzeSynchronously(image: UIImage, locale: Locale) throws -> ReceiptScanAnalysis {
        guard let cgImage = image.cgImage else {
            throw ReceiptVisionServiceError.unsupportedImage
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = preferredRecognitionLanguages(for: locale)

        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: image.cgImageOrientation,
            options: [:]
        )
        try handler.perform([request])

        let observations = request.results ?? []
        let lines = observations
            .compactMap { observation -> (text: String, box: CGRect)? in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                let text = normalizedLine(candidate.string)
                guard !text.isEmpty else { return nil }
                return (text, observation.boundingBox)
            }
            .sorted { lhs, rhs in
                if abs(lhs.box.midY - rhs.box.midY) > 0.03 {
                    return lhs.box.midY > rhs.box.midY
                }
                return lhs.box.minX < rhs.box.minX
            }
            .map(\.text)

        return parse(recognizedLines: lines, locale: locale)
    }

    private static func preferredRecognitionLanguages(for locale: Locale) -> [String] {
        let language = locale.identifier.lowercased()
        switch true {
        case language.hasPrefix("es"):
            return ["es-ES", "en-US"]
        default:
            return ["en-US", "es-ES"]
        }
    }

    private static func normalizedLine(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func detectedMerchant(from lines: [String]) -> String? {
        let merchantCandidates = Array(lines.prefix(8))
            .enumerated()
            .compactMap { index, line -> (line: String, score: Int)? in
                guard !isNoiseLine(line), !containsAmount(line), !containsDate(line) else { return nil }
                let letters = line.filter(\.isLetter).count
                let digits = line.filter(\.isNumber).count
                guard letters >= 3 else { return nil }

                var score = (letters * 3) - (digits * 4) - (index * 5)
                if digits == 0 { score += 8 }
                if line.count <= 28 { score += 5 }
                if isMostlyUppercase(line) { score += 4 }
                if line.contains("&") { score += 1 }
                return (line, score)
            }

        return merchantCandidates.max { $0.score < $1.score }?.line
    }

    private static func detectedAmount(from lines: [String]) -> Decimal? {
        let strongKeywords = ["total", "grand total", "amount due", "total due", "balance due", "importe total"]
        let weakKeywords = ["subtotal", "tax", "tip", "change", "cash", "fee"]

        var bestCandidate: (amount: Decimal, score: Int)?

        for (index, line) in lines.enumerated() {
            let lowered = line.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            let amounts = extractedAmounts(from: line)
            guard !amounts.isEmpty else { continue }

            var score = max(0, 50 - index)
            if strongKeywords.contains(where: { lowered.contains($0) }) {
                score += 100
            }
            if weakKeywords.contains(where: { lowered.contains($0) }) {
                score -= 20
            }

            for amount in amounts {
                var amountScore = score
                if amount > 0 && amount < 10_000 {
                    amountScore += Int(NSDecimalNumber(decimal: amount).doubleValue.rounded())
                }
                if bestCandidate == nil || amountScore > bestCandidate!.score {
                    bestCandidate = (amount, amountScore)
                }
            }
        }

        return bestCandidate?.amount
    }

    private static func extractedAmounts(from value: String) -> [Decimal] {
        let pattern = #"(?<!\d)(?:[$€£]\s*)?\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})(?!\d)|(?<!\d)(?:[$€£]\s*)?\d+(?:[.,]\d{2})(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(value.startIndex..<value.endIndex, in: value)

        return regex.matches(in: value, range: nsRange).compactMap { match in
            guard let range = Range(match.range, in: value) else { return nil }
            return decimalAmount(from: String(value[range]))
        }
    }

    private static func decimalAmount(from candidate: String) -> Decimal? {
        var value = candidate
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "£", with: "")
            .replacingOccurrences(of: " ", with: "")

        if value.contains(",") && value.contains(".") {
            if let lastComma = value.lastIndex(of: ","), let lastDot = value.lastIndex(of: ".") {
                if lastComma > lastDot {
                    value = value.replacingOccurrences(of: ".", with: "")
                    value = value.replacingOccurrences(of: ",", with: ".")
                } else {
                    value = value.replacingOccurrences(of: ",", with: "")
                }
            }
        } else if value.contains(",") && !value.contains(".") {
            let parts = value.split(separator: ",")
            if parts.count == 2, parts[1].count == 2 {
                value = value.replacingOccurrences(of: ",", with: ".")
            } else {
                value = value.replacingOccurrences(of: ",", with: "")
            }
        }

        return Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func detectedDate(from lines: [String], locale: Locale) -> Date? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        for line in lines {
            guard containsDate(line) else { continue }
            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            if let match = detector?.matches(in: line, range: range).first(where: { $0.date != nil }) {
                return match.date
            }
        }

        let joined = lines.joined(separator: " ")
        let range = NSRange(joined.startIndex..<joined.endIndex, in: joined)
        return detector?.matches(in: joined, range: range).first(where: { $0.date != nil })?.date
    }

    private static func suggestedCategory(for merchant: String) -> ExpenseCategory? {
        let value = merchant.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

        let mappings: [(ExpenseCategory, [String])] = [
            (.coffee, ["coffee", "cafe", "starbucks", "latte", "blue bottle"]),
            (.dining, ["mcdonald", "burger", "pizza", "restaurant", "taco", "doordash", "ubereats", "chipotle"]),
            (.groceries, ["market", "grocery", "super", "whole foods", "trader joe", "costco", "walmart"]),
            (.transport, ["uber", "lyft", "shell", "chevron", "fuel", "gas", "metro", "transit", "taxi"]),
            (.shopping, ["amazon", "target", "mall", "zara", "nike", "h&m", "store"]),
            (.subscriptions, ["spotify", "netflix", "icloud", "youtube premium", "prime", "adobe", "canva", "disney", "apple one", "membership", "subscription"]),
            (.bills, ["internet", "utility", "electric", "water", "rent", "phone"])
        ]

        for (category, keywords) in mappings {
            if keywords.contains(where: { value.contains($0) }) {
                return category
            }
        }
        return nil
    }

    private static func isNoiseLine(_ line: String) -> Bool {
        let lowered = line.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let blockedFragments = [
            "receipt",
            "invoice",
            "subtotal",
            "tax",
            "tip",
            "total",
            "change",
            "visa",
            "mastercard",
            "amex",
            "card",
            "auth",
            "transaction",
            "approval",
            "cashier",
            "thank",
            "visit again",
            "www.",
            "http",
            "tel",
            "phone"
        ]

        return blockedFragments.contains(where: { lowered.contains($0) })
    }

    private static func containsAmount(_ line: String) -> Bool {
        !extractedAmounts(from: line).isEmpty
    }

    private static func containsDate(_ line: String) -> Bool {
        line.range(of: #"\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b"#, options: .regularExpression) != nil
            || line.range(of: #"\b(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\b"#, options: [.regularExpression, .caseInsensitive]) != nil
    }

    private static func isMostlyUppercase(_ line: String) -> Bool {
        let letters = line.filter(\.isLetter)
        guard !letters.isEmpty else { return false }
        let uppercase = letters.filter(\.isUppercase).count
        return uppercase >= max(letters.count - 2, 1)
    }
}

private extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up:
            return .up
        case .down:
            return .down
        case .left:
            return .left
        case .right:
            return .right
        case .upMirrored:
            return .upMirrored
        case .downMirrored:
            return .downMirrored
        case .leftMirrored:
            return .leftMirrored
        case .rightMirrored:
            return .rightMirrored
        @unknown default:
            return .up
        }
    }
}
