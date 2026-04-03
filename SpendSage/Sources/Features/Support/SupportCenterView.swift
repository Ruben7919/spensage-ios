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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Support Center")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)
                        Text("Create a support packet from the device you are using now, then share it by email with enough context to speed up troubleshooting.")
                            .foregroundStyle(BrandTheme.muted)
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Compose support packet")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Picker("Issue type", selection: $issueType) {
                            ForEach(SupportIssueType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }

                        TextField("Subject", text: $subject)
                            .textInputAutocapitalization(.sentences)

                        TextField("What happened?", text: $detail, axis: .vertical)
                            .lineLimit(5...9)

                        Toggle("Include local diagnostics", isOn: $includeDiagnostics)

                        HStack(spacing: 12) {
                            Button("Copy packet") {
                                UIPasteboard.general.string = supportPacket
                                copiedState = true
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

                        if copiedState {
                            Text("Support packet copied to the clipboard.")
                                .font(.footnote)
                                .foregroundStyle(BrandTheme.primary)
                        }
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
                        .frame(minHeight: 220)
                        .padding(14)
                        .background(BrandTheme.surfaceTint)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
            .padding(24)
        }
        .background(BrandTheme.canvas)
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
}
