import SwiftUI
import UIKit

private enum SupportIssueType: String, CaseIterable, Identifiable {
    case account = "Account"
    case budget = "Budget"
    case importExport = "Import / Export"
    case growth = "Growth"
    case bug = "Bug"

    var id: String { rawValue }

    var localizedTitle: String {
        rawValue.appLocalized
    }
}

private enum SupportPriority: String, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"

    var id: String { rawValue }

    var localizedTitle: String {
        rawValue.appLocalized
    }
}

private struct RecentSupportPacket: Identifiable {
    let id = UUID()
    let createdAt: Date
    let ticketID: String
    let issueType: SupportIssueType
    let priority: SupportPriority
    let subject: String
    let includeDiagnostics: Bool

    init(
        createdAt: Date = .now,
        issueType: SupportIssueType,
        priority: SupportPriority,
        subject: String,
        includeDiagnostics: Bool
    ) {
        self.createdAt = createdAt
        ticketID = "SUP-\(String(UUID().uuidString.prefix(8)).uppercased())"
        self.issueType = issueType
        self.priority = priority
        self.subject = subject
        self.includeDiagnostics = includeDiagnostics
    }
}

struct SupportCenterView: View {
    @ObservedObject var viewModel: AppViewModel

    @Environment(\.openURL) private var openURL

    @State private var issueType: SupportIssueType = .bug
    @State private var priority: SupportPriority = .medium
    @State private var subject = "SpendSage support request"
    @State private var detail = ""
    @State private var includeDiagnostics = true
    @State private var copiedState = false
    @State private var recentPackets: [RecentSupportPacket] = []

    private var recentExpense: ExpenseItem? {
        viewModel.ledger?.recentExpenseItems(limit: 1).first
    }

    private var nextBill: BillRecord? {
        viewModel.ledger?.upcomingBills().first
    }

    private var topRule: RuleRecord? {
        viewModel.rules.first
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Support-ready packet",
                    title: "Support Center",
                    summary: "Describe the issue, package a local summary, and share a cleaner troubleshooting packet from this device. Priority, category, and recent context stay visible so you can write a better report faster.",
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
                        BrandFeatureRow(
                            systemImage: "exclamationmark.bubble.fill",
                            title: "Current ticket framing",
                            detail: "Category, priority, and recent context are captured before you copy or share the packet, which keeps the note focused."
                        )
                        BrandFeatureRow(
                            systemImage: "icloud.slash.fill",
                            title: "Local only for now",
                            detail: "Tickets stay on this device in the free build. Cloud history and sync-style ticketing are intentionally hidden until premium sign-in is available."
                        )
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Recent local signals")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        if let recentExpense {
                            BrandFeatureRow(
                                systemImage: "receipt.fill",
                                title: recentExpense.title,
                                detail: "\(recentExpense.category) · \(recentExpense.amount.formatted(.currency(code: "USD")))"
                            )
                        }

                        if let nextBill {
                            BrandFeatureRow(
                                systemImage: "calendar.badge.clock",
                                title: nextBill.title,
                                detail: "Next due \(FinanceToolFormatting.dueDateText(for: nextBill, ledger: viewModel.ledger)) · \(nextBill.amount.formatted(.currency(code: "USD")))"
                            )
                        }

                        if let topRule {
                            let matches = viewModel.ledger?.matchingExpensesCount(for: topRule) ?? 0
                            BrandFeatureRow(
                                systemImage: "slider.horizontal.3",
                                title: topRule.merchantKeyword,
                                detail: AppLocalization.localized(
                                    "%@ · %d matching transaction%@",
                                    arguments: topRule.category.localizedTitle,
                                    matches,
                                    matches == 1 ? "" : "s"
                                )
                            )
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Compose packet")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Picker("Priority", selection: $priority) {
                            ForEach(SupportPriority.allCases) { value in
                                Text(value.localizedTitle).tag(value)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("Issue type", selection: $issueType) {
                            ForEach(SupportIssueType.allCases) { type in
                                Text(type.localizedTitle).tag(type)
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
                                recordRecentPacket()
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
                            recordRecentPacket()
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
                        HStack {
                            Text("Packet preview")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)
                            Spacer()
                            BrandBadge(text: priority.localizedTitle, systemImage: "exclamationmark.circle.fill")
                        }

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

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent tickets")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        if recentPackets.isEmpty {
                            Text("Copy or email a packet to build a local ticket trail on this device.")
                                .font(.subheadline)
                                .foregroundStyle(BrandTheme.muted)
                        } else {
                            ForEach(recentPackets) { packet in
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(packet.subject)
                                            .font(.headline)
                                            .foregroundStyle(BrandTheme.ink)
                                        Text("\(packet.ticketID) · \(packet.issueType.localizedTitle) · \(packet.priority.localizedTitle)")
                                            .font(.footnote)
                                            .foregroundStyle(BrandTheme.muted)
                                        Text(packet.createdAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.footnote)
                                            .foregroundStyle(BrandTheme.muted)
                                        Text(packet.includeDiagnostics ? "Context included" : "Context excluded")
                                            .font(.footnote)
                                            .foregroundStyle(packet.includeDiagnostics ? BrandTheme.primary : BrandTheme.muted)
                                    }

                                    Spacer()

                                    BrandBadge(
                                        text: packet.includeDiagnostics ? "Context" : "No context",
                                        systemImage: packet.includeDiagnostics ? "checkmark.shield.fill" : "shield.slash.fill"
                                    )
                                }
                            }
                        }
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
            issueType: issueType.localizedTitle,
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

    private func recordRecentPacket() {
        let packet = RecentSupportPacket(
            issueType: issueType,
            priority: priority,
            subject: subject.isEmpty ? "SpendSage support request" : subject,
            includeDiagnostics: includeDiagnostics
        )
        recentPackets.insert(packet, at: 0)
        recentPackets = Array(recentPackets.prefix(5))
    }
}
