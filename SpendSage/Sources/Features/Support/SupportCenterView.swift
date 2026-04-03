import SwiftUI
import UIKit

private enum SupportIssueType: String, CaseIterable, Identifiable {
    case account = "Account"
    case budget = "Budget"
    case importExport = "Import / Export"
    case growth = "Growth"
    case bug = "Bug"

    var id: String { rawValue }
}

struct SupportCenterView: View {
    @ObservedObject var viewModel: AppViewModel

    @Environment(\.openURL) private var openURL

    @State private var issueType: SupportIssueType = .bug
    @State private var subject = "SpendSage support request"
    @State private var detail = ""
    @State private var includeDiagnostics = true
    @State private var copiedState = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Support-ready packet",
                    title: "Support Center",
                    summary: "Describe the issue, package a local summary, and share a cleaner troubleshooting packet from this device.",
                    systemImage: "lifepreserver.fill"
                )

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Packet at a glance")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        HStack(spacing: 12) {
                            BrandMetricTile(title: "Expenses", value: "\(viewModel.dashboardState?.transactionCount ?? 0)", systemImage: "receipt.fill")
                            BrandMetricTile(title: "Accounts", value: "\(viewModel.accounts.count)", systemImage: "creditcard.fill")
                            BrandMetricTile(title: "Rules", value: "\(viewModel.rules.count)", systemImage: "line.3.horizontal.decrease.circle.fill")
                        }

                        BrandFeatureRow(
                            systemImage: includeDiagnostics ? "checkmark.shield.fill" : "shield.slash.fill",
                            title: includeDiagnostics ? "Diagnostics included" : "Diagnostics excluded",
                            detail: includeDiagnostics
                                ? "The generated packet includes local budget and ledger summary details to speed up troubleshooting."
                                : "Only the issue description will be shared. You can toggle diagnostics back on any time."
                        )
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Compose packet")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Picker("Issue type", selection: $issueType) {
                            ForEach(SupportIssueType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)

                        FinanceField(
                            label: "Subject",
                            placeholder: "Briefly summarize the issue",
                            text: $subject,
                            keyboard: .default,
                            capitalization: .sentences
                        )

                        FinanceMultilineField(
                            label: "What happened?",
                            placeholder: "Include what you expected, what you saw instead, and any recent step that might help reproduce it.",
                            text: $detail
                        )

                        Toggle("Include local diagnostics", isOn: $includeDiagnostics)
                            .tint(BrandTheme.primary)

                        HStack(spacing: 12) {
                            Button("Copy packet") {
                                UIPasteboard.general.string = supportPacket
                                showCopiedToast()
                            }
                            .buttonStyle(SecondaryCTAStyle())

                            ShareLink(item: supportPacket, preview: SharePreview("SpendSage Support Packet")) {
                                Text("Share packet")
                            }
                            .buttonStyle(PrimaryCTAStyle())
                        }

                        Button("Open support email draft") {
                            guard let url = mailtoURL else { return }
                            openURL(url)
                        }
                        .buttonStyle(SecondaryCTAStyle())

                        NavigationLink {
                            LegalCenterView()
                        } label: {
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: "doc.text.fill")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(BrandTheme.primary)
                                    .frame(width: 42, height: 42)
                                    .background(BrandTheme.accent.opacity(0.18))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Review legal and public support links")
                                        .font(.headline)
                                        .foregroundStyle(BrandTheme.ink)
                                    Text("Open the public privacy, terms, and support pages if you need a policy or contact reference.")
                                        .font(.subheadline)
                                        .foregroundStyle(BrandTheme.muted)
                                }

                                Spacer(minLength: 0)

                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.bold))
                                    .foregroundStyle(BrandTheme.muted)
                                    .padding(.top, 6)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Packet preview")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        ScrollView {
                            Text(supportPacket)
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundStyle(BrandTheme.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .frame(minHeight: 240)
                        .padding(14)
                        .background(BrandTheme.surfaceTint)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .overlay(alignment: .top) {
            BrandBackdropView()
        }
        .overlay(alignment: .bottom) {
            if copiedState {
                Text("Support packet copied")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(BrandTheme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(BrandTheme.surface)
                    .clipShape(Capsule(style: .continuous))
                    .shadow(color: BrandTheme.shadow.opacity(0.12), radius: 12, x: 0, y: 6)
                    .padding(.bottom, 18)
            }
        }
        .navigationTitle("Support Center")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var supportPacket: String {
        LocalLedgerExportComposer.supportPacket(
            viewModel: viewModel,
            issueType: issueType.rawValue,
            subject: subject,
            detail: detail,
            includeDiagnostics: includeDiagnostics
        )
    }

    private var mailtoURL: URL? {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = supportPacket.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "mailto:support@spendsage.ai?subject=\(encodedSubject)&body=\(encodedBody)")
    }

    private func showCopiedToast() {
        copiedState = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            copiedState = false
        }
    }
}
