import SwiftUI
import UIKit

struct FinanceScreenBackground: View {
    var body: some View {
        ZStack {
            BrandTheme.canvas
            BrandBackdropView()
        }
        .ignoresSafeArea()
    }
}

struct FinanceToolsHeaderCard: View {
    let eyebrow: String
    let title: String
    let summary: String
    let systemImage: String
    var surface: AppSurfaceID? = nil
    var character: BrandCharacterID = .tikki
    var expression: BrandExpression = .proud
    var sceneKey: String? = nil
    var sceneFileName: String? = nil
    var placeholderPrompt: String? = nil

    private var narrative: BrandNarrativeSpec? {
        guard let surface else { return nil }
        return BrandStoryCatalog.spec(for: surface)
    }

    private var resolvedCharacter: BrandCharacterID {
        narrative?.character ?? character
    }

    private var resolvedExpression: BrandExpression {
        narrative?.expression ?? expression
    }

    private var resolvedSceneKey: String? {
        sceneKey
    }

    private var resolvedSceneFileName: String? {
        narrative?.sceneSource?.fileName ?? sceneFileName
    }

    private var resolvedPrompt: String? {
        narrative?.scenePrompt ?? placeholderPrompt
    }

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                BrandCardHeader(
                    badgeText: eyebrow,
                    badgeSystemImage: systemImage,
                    title: title,
                    summary: summary
                ) {
                    MascotAvatarView(character: resolvedCharacter, expression: resolvedExpression, size: 78)
                }

                if resolvedSceneKey != nil || resolvedSceneFileName != nil || resolvedPrompt != nil {
                    BrandScenePanel(
                        sceneKey: resolvedSceneKey,
                        sceneFileName: resolvedSceneFileName,
                        fallbackSystemImage: systemImage,
                        placeholderPrompt: resolvedPrompt,
                        height: 164
                    )
                }

                if let narrative {
                    Text(narrative.roleSummary.appLocalized)
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct FinanceNoticeCard: View {
    let message: String

    var body: some View {
        SurfaceCard {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(BrandTheme.accent.opacity(0.18))
                    Image(systemName: "checkmark.message.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(BrandTheme.primary)
                }
                .frame(width: 42, height: 42)

                Text(message.appLocalized)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct FinanceEmptyStateCard: View {
    let title: String
    let summary: String
    let systemImage: String

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(BrandTheme.heroGlowGradient)
                    Image(systemName: systemImage)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(BrandTheme.primary)
                }
                .frame(width: 50, height: 50)

                Text(title.appLocalized)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(summary.appLocalized)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct FinanceField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var capitalization: TextInputAutocapitalization = .words
    var accessibilityIdentifier: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.appLocalized)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)

                TextField(placeholder.appLocalized, text: $text)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(capitalization)
                    .autocorrectionDisabled()
                    .padding()
                    .accessibilityIdentifier(accessibilityIdentifier ?? "")
                .background(BrandTheme.surfaceTint)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(BrandTheme.line.opacity(0.75), lineWidth: 1)
                )
        }
    }
}

struct FinanceMultilineField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var accessibilityIdentifier: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.appLocalized)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(BrandTheme.surfaceTint)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(BrandTheme.line.opacity(0.75), lineWidth: 1)
                    )

                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(placeholder.appLocalized)
                        .foregroundStyle(BrandTheme.muted.opacity(0.8))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                }

                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 108)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .foregroundStyle(BrandTheme.ink)
                    .background(Color.clear)
                    .accessibilityIdentifier(accessibilityIdentifier ?? "")
            }
        }
    }
}

struct FinanceToolRowLabel: View {
    let title: String
    let summary: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(BrandTheme.accent.opacity(0.2))
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(BrandTheme.primary)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(title.appLocalized)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text(summary.appLocalized)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

enum FinanceToolFormatting {
    static func decimal(from text: String) -> Decimal? {
        let trimmed = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: " ", with: "")
        guard !trimmed.isEmpty else { return nil }

        if trimmed.contains(","), !trimmed.contains(".") {
            return Decimal(string: trimmed.replacingOccurrences(of: ",", with: "."))
        }

        if trimmed.contains(","),
           trimmed.contains("."),
           let lastComma = trimmed.lastIndex(of: ","),
           let lastDot = trimmed.lastIndex(of: "."),
           lastComma > lastDot {
            let normalized = trimmed
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: ".")
            return Decimal(string: normalized)
        }

        return Decimal(string: trimmed.replacingOccurrences(of: ",", with: ""))
    }

    static func dueDateText(for bill: BillRecord, ledger: LocalFinanceLedger?) -> String {
        guard let ledger else {
            return AppLocalization.localized("Due day %@", arguments: "\(bill.dueDay)")
        }
        return ledger.dueDate(for: bill).formatted(date: .abbreviated, time: .omitted)
    }

    static func paymentStatusText(for bill: BillRecord) -> String {
        guard let lastPaidAt = bill.lastPaidAt else {
            return bill.autopay ? "Autopay enabled".appLocalized : "Awaiting payment".appLocalized
        }
        return AppLocalization.localized(
            "Paid %@",
            arguments: lastPaidAt.formatted(date: .abbreviated, time: .omitted)
        )
    }
}
