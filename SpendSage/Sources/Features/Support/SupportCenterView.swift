import SwiftUI
import UIKit

private enum SupportIssueType: String, CaseIterable, Identifiable {
    case account = "Cuenta"
    case budget = "Presupuesto"
    case importExport = "Importación / Exportación"
    case growth = "Crecimiento"
    case bug = "Bug"

    var id: String { rawValue }

    var localizedTitle: String {
        rawValue.appLocalized
    }
}

private enum SupportPriority: String, CaseIterable, Identifiable {
    case low = "Baja"
    case medium = "Media"
    case high = "Alta"
    case urgent = "Urgente"

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
    @AppStorage(AppCurrencyFormat.defaultsKey) private var currencyCode = AppCurrencyFormat.defaultCode

    @Environment(\.openURL) private var openURL
    @Environment(\.shellBottomInset) private var shellBottomInset

    @State private var issueType: SupportIssueType = .bug
    @State private var priority: SupportPriority = .medium
    @State private var subject = "Solicitud de soporte de MichiFinanzas"
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
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        BrandCardHeader(
                            badgeText: "Soporte",
                            badgeSystemImage: "lifepreserver.fill",
                            title: "Centro de soporte",
                            summary: "Describe el problema, genera un paquete local y compártelo solo si decides enviarlo.",
                            titleSize: 32
                        ) {
                            MascotAvatarView(character: .manchas, expression: .thinking, size: 76)
                        }
                    }
                }

                ExperienceDisclosureCard(
                    title: "Contexto desde este dispositivo",
                    summary: "Ábrelo solo si quieres revisar el contexto local que entrará al paquete.",
                    character: .tikki,
                    expression: .thinking
                ) {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        BrandMetricTile(title: "Gastos", value: "\(viewModel.dashboardState?.transactionCount ?? 0)", systemImage: "receipt.fill")
                        BrandMetricTile(title: "Cuentas", value: "\(viewModel.accounts.count)", systemImage: "creditcard.fill")
                        BrandMetricTile(title: "Reglas", value: "\(viewModel.rules.count)", systemImage: "line.3.horizontal.decrease.circle.fill")
                    }

                    BrandFeatureRow(
                        systemImage: includeDiagnostics ? "checkmark.shield.fill" : "shield.slash.fill",
                        title: includeDiagnostics ? "Diagnóstico incluido" : "Diagnóstico excluido",
                        detail: includeDiagnostics
                            ? "El paquete incluye resumen local de presupuesto y libro para acelerar la revisión."
                            : "Solo se compartirá tu descripción del problema."
                    )

                    if let recentExpense {
                        BrandFeatureRow(
                            systemImage: "receipt.fill",
                            title: recentExpense.title,
                            detail: AppLocalization.localized(
                                "%@ · %@",
                                arguments: recentExpense.category.appLocalized,
                                recentExpense.amount.formatted(.currency(code: currencyCode))
                            )
                        )
                    }

                    if let nextBill {
                        BrandFeatureRow(
                            systemImage: "calendar.badge.clock",
                            title: nextBill.title,
                            detail: "Próximo vencimiento \(FinanceToolFormatting.dueDateText(for: nextBill, ledger: viewModel.ledger)) · \(nextBill.amount.formatted(.currency(code: currencyCode)))"
                        )
                    }

                    if let topRule {
                        let matches = viewModel.ledger?.matchingExpensesCount(for: topRule) ?? 0
                        BrandFeatureRow(
                            systemImage: "slider.horizontal.3",
                            title: topRule.merchantKeyword,
                            detail: matches == 1
                                ? "\(topRule.category.localizedTitle) · \(matches) transacción coincidente"
                                : "\(topRule.category.localizedTitle) · \(matches) transacciones coincidentes"
                        )
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Redactar paquete")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Prioridad")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BrandTheme.muted)

                            Picker("Prioridad", selection: $priority) {
                                ForEach(SupportPriority.allCases) { value in
                                    Text(value.localizedTitle).tag(value)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(BrandTheme.surfaceTint)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
                            )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tipo de incidencia")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BrandTheme.muted)

                            Picker("Tipo de incidencia", selection: $issueType) {
                                ForEach(SupportIssueType.allCases) { type in
                                    Text(type.localizedTitle).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(BrandTheme.surfaceTint)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
                            )
                        }

                        FinanceField(
                            label: "Asunto",
                            placeholder: "Resume brevemente el problema",
                            text: $subject,
                            keyboard: .default,
                            capitalization: .sentences
                        )

                        FinanceMultilineField(
                            label: "¿Qué ocurrió?",
                            placeholder: "Incluye qué esperabas, qué viste en su lugar y cualquier paso reciente que ayude a reproducirlo.",
                            text: $detail
                        )

                        Toggle("Incluir diagnóstico local", isOn: $includeDiagnostics)
                            .tint(BrandTheme.primary)

                        HStack(spacing: 12) {
                            Button("Copiar paquete") {
                                recordRecentPacket()
                                UIPasteboard.general.string = supportPacket
                                showCopiedToast()
                            }
                            .buttonStyle(SecondaryCTAStyle())

                            ShareLink(item: supportPacket, preview: SharePreview("Paquete de soporte de MichiFinanzas")) {
                                Text("Compartir paquete")
                            }
                            .buttonStyle(PrimaryCTAStyle())
                        }

                        Button("Abrir borrador de correo") {
                            recordRecentPacket()
                            guard let url = mailtoURL else { return }
                            openURL(url)
                        }
                        .buttonStyle(SecondaryCTAStyle())

                        NavigationLink {
                            LegalCenterView()
                        } label: {
                            supportRouteRow(
                                title: "Abrir Centro legal",
                                summary: "Revisa privacidad, términos, aviso beta y contacto.",
                                systemImage: "doc.text.fill"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                ExperienceDisclosureCard(
                    title: "Vista previa e historial",
                    summary: "Ábrelo solo cuando quieras auditar el paquete o revisar tickets locales recientes.",
                    character: .mei,
                    expression: .thinking
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Vista previa del paquete")
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
                        .frame(minHeight: 220)
                        .padding(14)
                        .background(BrandTheme.surfaceTint)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
                        )

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tickets locales recientes")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)

                            if recentPackets.isEmpty {
                                Text("Copia o envía un paquete para construir un rastro local de tickets en este dispositivo.")
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
                                            Text(packet.includeDiagnostics ? "Contexto incluido" : "Contexto excluido")
                                                .font(.footnote)
                                                .foregroundStyle(packet.includeDiagnostics ? BrandTheme.primary : BrandTheme.muted)
                                        }

                                        Spacer()

                                        BrandBadge(
                                            text: packet.includeDiagnostics ? "Contexto" : "Sin contexto",
                                            systemImage: packet.includeDiagnostics ? "checkmark.shield.fill" : "shield.slash.fill"
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .accessibilityIdentifier("support.screen")
        .background(BrandTheme.canvas)
        .background(alignment: .top) {
            BrandBackdropView()
        }
        .overlay(alignment: .topLeading) {
            AccessibilityProbe(identifier: "support.screen")
        }
        .overlay(alignment: .bottom) {
            if copiedState {
                Text("Paquete de soporte copiado")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(BrandTheme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(BrandTheme.surface)
                    .clipShape(Capsule(style: .continuous))
                    .shadow(color: BrandTheme.shadow.opacity(0.12), radius: 12, x: 0, y: 6)
                    .padding(.bottom, shellBottomInset + 18)
            }
        }
        .navigationTitle("Centro de soporte")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func supportRouteRow(title: String, summary: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(BrandTheme.primary)
                .frame(width: 42, height: 42)
                .background(BrandTheme.accent.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(BrandTheme.muted)
                .padding(.top, 6)
        }
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
        return URL(string: "mailto:ruben.lazaro@clitecser.com?subject=\(encodedSubject)&body=\(encodedBody)")
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
            subject: subject.isEmpty ? "Solicitud de soporte de MichiFinanzas" : subject,
            includeDiagnostics: includeDiagnostics
        )
        recentPackets.insert(packet, at: 0)
        recentPackets = Array(recentPackets.prefix(5))
    }
}
