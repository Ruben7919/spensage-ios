import SwiftUI
import UIKit

private enum ExportMode: String, CaseIterable, Identifiable {
    case readable = "Legible"
    case json = "JSON"

    var id: String { rawValue }

    var localizedTitle: String {
        rawValue.appLocalized
    }
}

struct AdvancedSettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.openURL) private var openURL

    @AppStorage("native.settings.localDebugOverlay") private var debugOverlayEnabled = false
    @AppStorage("native.settings.exportIncludesDiagnostics") private var includeDiagnostics = true
    @State private var exportMode: ExportMode = .readable
    @State private var copiedState = false
    @State private var isPresentingGuide = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                guideCard
                deviceControlsCard
                backendCloudCard
                exportCenterCard
                ledgerSummaryCard
                supportHandoffCard
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .background(alignment: .top) {
            BrandBackdropView()
        }
        .navigationTitle("Avanzado")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingGuide) {
            GuideSheet(guide: GuideLibrary.guide(.sharing))
        }
    }

    private var heroCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                BrandBadge(text: "Centro de control", systemImage: "switch.2")

                Text("Avanzado")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandTheme.ink)

                Text("Revisa el libro local, genera una exportación segura y ten el soporte a mano sin recargar el flujo principal.")
                    .foregroundStyle(BrandTheme.muted)

                BrandFeatureRow(
                    systemImage: "lock.fill",
                    title: "Todo sigue en este dispositivo",
                    detail: "Exportación, soporte y diagnóstico se mantienen como acciones conscientes, no como ruido dentro del flujo principal."
                )
            }
        }
    }

    private var guideCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    MascotAvatarView(character: .manchas, expression: .happy, size: 62)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Guía de exportación y soporte")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text("Abre la guía interactiva para entender exportaciones, paquetes de soporte y qué información sale realmente del dispositivo.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                    }
                }

                Button("Abrir guía") {
                    isPresentingGuide = true
                }
                .buttonStyle(PrimaryCTAStyle())
            }
        }
    }

    private var deviceControlsCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Controles del dispositivo")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                Toggle("Activar overlay local", isOn: $debugOverlayEnabled)
                Toggle("Incluir diagnóstico en exportaciones", isOn: $includeDiagnostics)

                BrandFeatureRow(
                    systemImage: "lock.doc",
                    title: "Privado por defecto",
                    detail: "Las exportaciones se arman con el libro ya cargado en este dispositivo, así que tú decides cuándo algo sale de la app."
                )
            }
        }
    }

    private var exportCenterCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Centro de exportación")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Spacer()
                    if copiedState {
                        Text("Copiado")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(BrandTheme.primary)
                    }
                }

                Picker("Formato", selection: $exportMode) {
                    ForEach(ExportMode.allCases) { mode in
                        Text(mode.localizedTitle).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                ScrollView {
                    Text(exportBody)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(BrandTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(minHeight: 220)
                .padding(14)
                .background(BrandTheme.surfaceTint)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                HStack(spacing: 12) {
                    Button("Copiar exportación") {
                        UIPasteboard.general.string = exportBody
                        copiedState = true
                    }
                    .buttonStyle(SecondaryCTAStyle())

                    ShareLink(item: exportBody, preview: SharePreview("Exportación local de SpendSage")) {
                        Text("Compartir exportación")
                    }
                    .buttonStyle(PrimaryCTAStyle())
                }
            }
        }
    }

    private var backendCloudCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Backend cloud")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        if let backendConfiguration = viewModel.backendConfiguration {
                            Text(
                                AppLocalization.localized(
                                    "%@ · %@",
                                    arguments: backendConfiguration.environmentName,
                                    backendConfiguration.hostLabel
                                )
                            )
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                        } else {
                            Text("Sin configuración remota en el bundle.")
                                .font(.subheadline)
                                .foregroundStyle(BrandTheme.muted)
                        }
                    }

                    Spacer(minLength: 0)

                    Button("Actualizar") {
                        Task {
                            await viewModel.refreshBackendStatus(force: true)
                        }
                    }
                    .buttonStyle(SecondaryCTAStyle())
                    .disabled(viewModel.backendConfiguration == nil)
                }

                if let backendStatus = viewModel.backendStatus {
                    BrandFeatureRow(
                        systemImage: backendStatus.securityIcon,
                        title: AppLocalization.localized("Seguridad: %@", arguments: backendStatus.securitySummary),
                        detail: backendStatus.featureSummary
                    )

                    if let entitlements = backendStatus.entitlements {
                        BrandFeatureRow(
                            systemImage: "person.2.crop.square.stack.fill",
                            title: AppLocalization.localized("Plan cloud: %@", arguments: entitlements.planDisplayName),
                            detail: AppLocalization.localized("Features: %@", arguments: entitlements.featuresDisplayLine)
                        )
                    } else {
                        BrandFeatureRow(
                            systemImage: "person.crop.circle.badge.questionmark",
                            title: "Entitlements pendientes",
                            detail: "La sesión actual todavía no devolvió plan ni features cloud."
                        )
                    }
                } else if let backendStatusError = viewModel.backendStatusError {
                    BrandFeatureRow(
                        systemImage: "exclamationmark.triangle.fill",
                        title: "Cloud no verificado",
                        detail: backendStatusError
                    )
                } else {
                    BrandFeatureRow(
                        systemImage: "icloud.slash",
                        title: "Cloud sin leer",
                        detail: "Usa Actualizar para consultar capacidades, billing y flags del backend."
                    )
                }
            }
        }
    }

    private var ledgerSummaryCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Resumen del libro")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                let state = viewModel.dashboardState
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(
                        title: "Gasto local",
                        value: LocalLedgerExportComposer.currency(state?.budgetSnapshot.monthlySpent ?? 0),
                        systemImage: "chart.bar.fill"
                    )
                    BrandMetricTile(
                        title: "Restante",
                        value: LocalLedgerExportComposer.currency(state?.budgetSnapshot.remaining ?? 0),
                        systemImage: "shield.lefthalf.filled"
                    )
                    BrandMetricTile(
                        title: "Última actualización",
                        value: viewModel.ledger?.updatedAt.formatted(date: .abbreviated, time: .shortened) ?? "Pendiente",
                        systemImage: "clock.arrow.circlepath"
                    )
                    BrandMetricTile(
                        title: "Categoría líder",
                        value: state?.topCategory?.category.localizedTitle ?? "Sin datos",
                        systemImage: "sparkles.rectangle.stack"
                    )
                }
            }
        }
    }

    private var exportBody: String {
        switch exportMode {
        case .readable:
            let summary = LocalLedgerExportComposer.readableSummary(viewModel: viewModel)
            if includeDiagnostics {
                return summary + "\n\nDiagnóstico\n- Overlay local: \(debugOverlayEnabled ? "Activo" : "Inactivo")"
            }
            return summary
        case .json:
            return LocalLedgerExportComposer.jsonSnapshot(viewModel: viewModel)
        }
    }

    private var supportHandoffCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Soporte")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                BrandFeatureRow(
                    systemImage: "square.and.arrow.up",
                    title: "Comparte solo cuando quieras",
                    detail: "Los paquetes de soporte siguen siendo legibles antes de copiarse o enviarse, para que revises exactamente qué sale del dispositivo."
                )

                BrandFeatureRow(
                    systemImage: "hand.raised.fill",
                    title: "Ten los enlaces de confianza cerca",
                    detail: "Abre privacidad y soporte desde aquí cuando necesites una referencia pública mientras pruebas la app."
                )

                HStack(spacing: 12) {
                    Button("Abrir soporte") {
                        openURL(PublicLegalLinks.support)
                    }
                    .buttonStyle(SecondaryCTAStyle())

                    Button("Abrir privacidad") {
                        openURL(PublicLegalLinks.privacy)
                    }
                    .buttonStyle(PrimaryCTAStyle())
                }
            }
        }
    }
}

private extension BackendRuntimeStatus {
    var securitySummary: String {
        let checks = [
            capabilities.security.waf,
            capabilities.security.kmsAtRest,
            capabilities.security.cognitoAuth,
            capabilities.security.webhookSignatureValidation,
            capabilities.security.rateLimits,
        ]
        let readyChecks = checks.filter { $0 }.count
        return AppLocalization.localized("%d/5 listas", arguments: readyChecks)
    }

    var featureSummary: String {
        var flags = [
            capabilities.features.billing ? "billing" : nil,
            capabilities.features.pushRegistration ? "push" : nil,
            capabilities.features.spaces ? "family" : nil,
            capabilities.features.csvImport ? "csv" : nil,
            capabilities.features.invoiceScan ? "scan" : nil,
        ].compactMap(\.self)

        if capabilities.features.aiInsights {
            flags.append("ai")
        }

        return flags.isEmpty ? "Sin features cloud activas" : flags.joined(separator: ", ")
    }

    var securityIcon: String {
        capabilities.security.waf && capabilities.security.rateLimits && capabilities.security.cognitoAuth
            ? "checkmark.shield.fill"
            : "exclamationmark.shield.fill"
    }
}
