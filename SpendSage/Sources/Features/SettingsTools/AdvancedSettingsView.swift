import SwiftUI
import UIKit

private enum ExportMode: String, CaseIterable, Identifiable {
    case readable = "Readable"
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
                exportCenterCard
                ledgerSummaryCard
                supportHandoffCard
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .overlay(alignment: .top) {
            BrandBackdropView()
        }
        .navigationTitle("Advanced settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingGuide) {
            GuideSheet(guide: GuideLibrary.guide(.sharing))
        }
    }

    private var heroCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                BrandBadge(text: "Control center", systemImage: "switch.2")

                Text("Advanced settings")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandTheme.ink)

                Text("Inspect the ledger, generate a safe export, and keep support details close without leaving the main flow.")
                    .foregroundStyle(BrandTheme.muted)

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(
                        title: "Overlay",
                        value: debugOverlayEnabled ? "On".appLocalized : "Off".appLocalized,
                        systemImage: "circle.grid.3x3.fill"
                    )
                    BrandMetricTile(
                        title: "Diagnostics",
                        value: includeDiagnostics ? "On".appLocalized : "Off".appLocalized,
                        systemImage: "doc.text.magnifyingglass"
                    )
                    BrandMetricTile(
                        title: "Format",
                        value: exportMode.localizedTitle,
                        systemImage: "square.and.arrow.up"
                    )
                    BrandMetricTile(
                        title: "Scope",
                        value: "On device".appLocalized,
                        systemImage: "lock.fill"
                    )
                }

                BrandScenePanel(
                    sceneKey: "guide_24_advanced_tools_manchas",
                    fallbackSystemImage: "slider.horizontal.3",
                    height: 200
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
                        Text("Sharing and support guide")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text("Open the interactive guide that explains exports, support packets, and the collaboration tone across the app.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                    }
                }

                Button("Open guide") {
                    isPresentingGuide = true
                }
                .buttonStyle(PrimaryCTAStyle())
            }
        }
    }

    private var deviceControlsCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Device controls")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                Toggle("Enable local debug overlay", isOn: $debugOverlayEnabled)
                Toggle("Include diagnostics in exports", isOn: $includeDiagnostics)

                BrandFeatureRow(
                    systemImage: "lock.doc",
                    title: "Private by default",
                    detail: "Exports are built from the ledger already loaded on this device, so you decide when anything leaves the app."
                )
            }
        }
    }

    private var exportCenterCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Export center")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Spacer()
                    if copiedState {
                        Text("Copied")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(BrandTheme.primary)
                    }
                }

                Picker("Format", selection: $exportMode) {
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
                    Button("Copy export") {
                        UIPasteboard.general.string = exportBody
                        copiedState = true
                    }
                    .buttonStyle(SecondaryCTAStyle())

                    ShareLink(item: exportBody, preview: SharePreview("SpendSage Local Export")) {
                        Text("Share export")
                    }
                    .buttonStyle(PrimaryCTAStyle())
                }
            }
        }
    }

    private var ledgerSummaryCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Ledger summary")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                let state = viewModel.dashboardState
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(
                        title: "Local spend",
                        value: LocalLedgerExportComposer.currency(state?.budgetSnapshot.monthlySpent ?? 0),
                        systemImage: "chart.bar.fill"
                    )
                    BrandMetricTile(
                        title: "Remaining",
                        value: LocalLedgerExportComposer.currency(state?.budgetSnapshot.remaining ?? 0),
                        systemImage: "shield.lefthalf.filled"
                    )
                    BrandMetricTile(
                        title: "Last update",
                        value: viewModel.ledger?.updatedAt.formatted(date: .abbreviated, time: .shortened) ?? "Pending",
                        systemImage: "clock.arrow.circlepath"
                    )
                    BrandMetricTile(
                        title: "Top category",
                        value: state?.topCategory?.category.localizedTitle ?? "None".appLocalized,
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
                return summary + "\n\nDiagnostics\n- Debug overlay: \(debugOverlayEnabled ? "Enabled" : "Disabled")"
            }
            return summary
        case .json:
            return LocalLedgerExportComposer.jsonSnapshot(viewModel: viewModel)
        }
    }

    private var supportHandoffCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Support packet")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                BrandFeatureRow(
                    systemImage: "square.and.arrow.up",
                    title: "Share exports only when you choose",
                    detail: "Support packets stay readable before they are copied or sent, so you can review exactly what leaves the device."
                )

                BrandFeatureRow(
                    systemImage: "hand.raised.fill",
                    title: "Keep trust links nearby",
                    detail: "Open privacy and support directly from here when you need a public reference while testing."
                )

                HStack(spacing: 12) {
                    Button("Open support") {
                        openURL(PublicLegalLinks.support)
                    }
                    .buttonStyle(SecondaryCTAStyle())

                    Button("Open privacy") {
                        openURL(PublicLegalLinks.privacy)
                    }
                    .buttonStyle(PrimaryCTAStyle())
                }
            }
        }
    }
}
