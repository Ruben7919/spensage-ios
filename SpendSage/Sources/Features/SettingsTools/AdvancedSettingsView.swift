import SwiftUI
import UIKit

private enum ExportMode: String, CaseIterable, Identifiable {
    case readable = "Readable"
    case json = "JSON"

    var id: String { rawValue }
}

struct AdvancedSettingsView: View {
    @ObservedObject var viewModel: AppViewModel

    @AppStorage("native.settings.localDebugOverlay") private var debugOverlayEnabled = false
    @AppStorage("native.settings.exportIncludesDiagnostics") private var includeDiagnostics = true
    @State private var exportMode: ExportMode = .readable
    @State private var copiedState = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Advanced settings")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)

                        Text("Inspect the local ledger, generate a device-safe export, and keep a practical summary ready for support or handoff.")
                            .foregroundStyle(BrandTheme.muted)

                        BrandBadge(text: "Local-first controls", systemImage: "switch.2")
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Device controls")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Toggle("Enable local debug overlay", isOn: $debugOverlayEnabled)
                        Toggle("Include diagnostics in exports", isOn: $includeDiagnostics)

                        BrandFeatureRow(
                            systemImage: "lock.doc",
                            title: "No backend required",
                            detail: "These exports are built from the ledger already loaded on this device."
                        )
                    }
                }

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
                                Text(mode.rawValue).tag(mode)
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

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Ledger summary")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        let state = viewModel.dashboardState
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
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
                                value: state?.topCategory?.category.rawValue ?? "None",
                                systemImage: "sparkles.rectangle.stack"
                            )
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .navigationTitle("Advanced settings")
        .navigationBarTitleDisplayMode(.inline)
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
}
