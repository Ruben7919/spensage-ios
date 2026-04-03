import SwiftUI
import UIKit
import AudioToolbox

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel

    @AppStorage("native.settings.language") private var language = "en"
    @AppStorage("native.settings.currency") private var currency = "USD"
    @AppStorage("native.settings.theme") private var theme = "finance"
    @AppStorage("native.settings.reminders") private var remindersEnabled = true
    @AppStorage("native.settings.sound") private var soundStyle = "playful"
    @AppStorage("native.settings.quietHoursEnabled") private var quietHoursEnabled = true
    @AppStorage("native.settings.quietHoursStart") private var quietHoursStart = "22:00"
    @AppStorage("native.settings.quietHoursEnd") private var quietHoursEnd = "07:00"
    @AppStorage("native.settings.weekendQuietMode") private var weekendQuietMode = true
    @AppStorage("native.settings.maxNotificationsPerDay") private var maxNotificationsPerDay = 2
    @AppStorage("native.settings.maxNotificationsPerWeek") private var maxNotificationsPerWeek = 5
    @State private var showingGuideReplay = false

    private var deviceLabel: String {
        UIDevice.current.localizedModel
    }

    private var systemVersionLabel: String {
        "iOS \(UIDevice.current.systemVersion)"
    }

    private func soundDisplayName(_ value: String) -> String {
        switch value {
        case "miau":
            return "Miau"
        case "off":
            return "Off"
        default:
            return "Playful"
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Local-first settings",
                    title: "Settings",
                    summary: "Tune local preferences, open the budget wizard, and keep support, legal, and growth tools close in one place. Language, currency, notifications, and export cues stay visible without leaving the app.",
                    systemImage: "gearshape.fill"
                )

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Session snapshot")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            BrandMetricTile(
                                title: "Mode",
                                value: sessionModeLabel,
                                systemImage: "person.crop.circle"
                            )
                            BrandMetricTile(
                                title: "Language",
                                value: language.uppercased(),
                                systemImage: "globe"
                            )
                            BrandMetricTile(
                                title: "Currency",
                                value: currency,
                                systemImage: "dollarsign.circle.fill"
                            )
                            BrandMetricTile(
                                title: "Theme",
                                value: themeDisplayName(theme),
                                systemImage: "paintpalette.fill"
                            )
                            BrandMetricTile(
                                title: "Sound",
                                value: soundDisplayName(soundStyle),
                                systemImage: "speaker.wave.2.fill"
                            )
                            BrandMetricTile(
                                title: "Device",
                                value: deviceLabel,
                                systemImage: "iphone.gen3"
                            )
                            BrandMetricTile(
                                title: "Export",
                                value: "Ready",
                                systemImage: "square.and.arrow.up"
                            )
                        }

                        VStack(spacing: 12) {
                            Button("Open budget wizard") {
                                viewModel.presentBudgetWizard()
                            }
                            .buttonStyle(PrimaryCTAStyle())

                            NavigationLink {
                                AdvancedSettingsView(viewModel: viewModel)
                            } label: {
                                settingsRouteLabel(
                                    title: "Advanced settings",
                                    summary: "Inspect exports, support packets, device controls, and local debug tools.",
                                    systemImage: "switch.2"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                subscriptionSurface

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("App data preview")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text("Preview a strip of brand assets and guides so the local experience keeps the same visual tone as the rest of the app.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(BrandAssetCatalog.shared.allBadgeAssets().prefix(4).enumerated()), id: \.offset) { _, asset in
                                    previewAssetCard(title: asset.fileName, source: asset, fallback: "seal.fill")
                                }

                                ForEach(Array(BrandAssetCatalog.shared.allAccessoryAssets().prefix(4).enumerated()), id: \.offset) { _, asset in
                                    previewAssetCard(title: asset.fileName, source: asset, fallback: "wand.and.stars")
                                }
                            }
                            .padding(.horizontal, 2)
                        }

                        Button("Replay guides") {
                            GuideProgressStore.resetAll()
                            showingGuideReplay = true
                        }
                        .buttonStyle(SecondaryCTAStyle())
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Preferences")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        settingsPickerRow(title: "Language", selection: $language) {
                            Text("Auto").tag("auto")
                            Text("English").tag("en")
                            Text("Español").tag("es")
                            Text("日本語").tag("ja")
                        }

                        Divider()

                        settingsPickerRow(title: "Currency", selection: $currency) {
                            Text("USD").tag("USD")
                            Text("EUR").tag("EUR")
                            Text("GBP").tag("GBP")
                            Text("JPY").tag("JPY")
                            Text("MXN").tag("MXN")
                        }

                        Divider()

                        settingsPickerRow(title: "Theme", selection: $theme) {
                            Text("Finance").tag("finance")
                            Text("Midnight").tag("midnight")
                            Text("Sunrise").tag("sunrise")
                        }

                        Divider()

                        Toggle(isOn: $remindersEnabled) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Daily reminders")
                                    .font(.headline)
                                    .foregroundStyle(BrandTheme.ink)
                                Text("Keep lightweight nudges enabled while you stay on-device. Notification sound follows the device's local reminder flow.")
                                    .font(.subheadline)
                                    .foregroundStyle(BrandTheme.muted)
                            }
                        }
                        .tint(BrandTheme.primary)

                        Divider()

                        Toggle(isOn: $quietHoursEnabled) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Quiet hours")
                                    .font(.headline)
                                    .foregroundStyle(BrandTheme.ink)
                                Text("Pause routine reminder noise during your selected quiet window.")
                                    .font(.subheadline)
                                    .foregroundStyle(BrandTheme.muted)
                            }
                        }
                        .tint(BrandTheme.primary)

                        settingsPickerRow(title: "Quiet hours start", selection: $quietHoursStart) {
                            Text("21:00").tag("21:00")
                            Text("22:00").tag("22:00")
                            Text("23:00").tag("23:00")
                            Text("00:00").tag("00:00")
                        }

                        Divider()

                        settingsPickerRow(title: "Quiet hours end", selection: $quietHoursEnd) {
                            Text("06:00").tag("06:00")
                            Text("07:00").tag("07:00")
                            Text("08:00").tag("08:00")
                            Text("09:00").tag("09:00")
                        }

                        Divider()

                        Toggle(isOn: $weekendQuietMode) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Weekend quiet mode")
                                    .font(.headline)
                                    .foregroundStyle(BrandTheme.ink)
                                Text("Keep weekends calmer unless you manually open the app.")
                                    .font(.subheadline)
                                    .foregroundStyle(BrandTheme.muted)
                            }
                        }
                        .tint(BrandTheme.primary)

                        settingsPickerRow(title: "Max notifications per day", selection: $maxNotificationsPerDay) {
                            Text("1").tag(1)
                            Text("2").tag(2)
                            Text("3").tag(3)
                        }

                        Divider()

                        settingsPickerRow(title: "Max notifications per week", selection: $maxNotificationsPerWeek) {
                            Text("3").tag(3)
                            Text("4").tag(4)
                            Text("5").tag(5)
                            Text("6").tag(6)
                            Text("7").tag(7)
                        }

                        Divider()

                        settingsPickerRow(title: "Notification sound", selection: $soundStyle) {
                            Text("Off").tag("off")
                            Text("Miau").tag("miau")
                            Text("Playful").tag("playful")
                        }

                        Button("Test notification sound") {
                            guard soundStyle != "off" else { return }
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            AudioServicesPlaySystemSound(1104)
                        }
                        .buttonStyle(SecondaryCTAStyle())
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Device and export")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        BrandMetricTile(
                            title: "Device",
                            value: deviceLabel,
                            systemImage: "iphone"
                        )
                        BrandMetricTile(
                            title: "Version",
                            value: systemVersionLabel,
                            systemImage: "info.circle.fill"
                        )

                        BrandFeatureRow(
                            systemImage: "square.and.arrow.up",
                            title: "Export center",
                            detail: "Advanced settings keeps the readable export, JSON snapshot, diagnostics toggle, and support packet tools close at hand."
                        )

                        NavigationLink {
                            AdvancedSettingsView(viewModel: viewModel)
                        } label: {
                            settingsRouteLabel(
                                title: "Open export and diagnostics",
                                summary: "Read the ledger snapshot, copy an export, or share a support packet.",
                                systemImage: "square.and.arrow.up"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account and tools")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        NavigationLink {
                            ProfileView(viewModel: viewModel)
                        } label: {
                            settingsRouteLabel(
                                title: "Profile",
                                summary: "Identity, household details, and local account snapshot.",
                                systemImage: "person.text.rectangle"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            AdvancedSettingsView(viewModel: viewModel)
                        } label: {
                            settingsRouteLabel(
                                title: "Advanced settings",
                                summary: "Local export center, diagnostics, and support packet tools.",
                                systemImage: "slider.horizontal.3"
                            )
                        }
                        .buttonStyle(.plain)

                        Button("Sign out") {
                            viewModel.signOut()
                        }
                        .buttonStyle(SecondaryCTAStyle())
                        .foregroundStyle(.red)
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Help and trust")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        NavigationLink {
                            HelpCenterView(viewModel: viewModel)
                        } label: {
                            settingsRouteLabel(
                                title: "Help Center",
                                summary: "Guided answers, setup flow, and quick paths when you get stuck.",
                                systemImage: "questionmark.circle.fill"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            SupportCenterView(viewModel: viewModel)
                        } label: {
                            settingsRouteLabel(
                                title: "Support Center",
                                summary: "Build a local support packet and share a clean troubleshooting summary.",
                                systemImage: "lifepreserver.fill"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            LegalCenterView()
                        } label: {
                            settingsRouteLabel(
                                title: "Legal Center",
                                summary: "Privacy, terms, and public support links for this build.",
                                systemImage: "doc.text.fill"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            BrandGalleryView()
                        } label: {
                            settingsRouteLabel(
                                title: "Brand Gallery",
                                summary: "Reference the product's visual language without leaving Settings.",
                                systemImage: "swatchpalette.fill"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .overlay(alignment: .top) {
            BrandBackdropView()
        }
        .sheet(isPresented: $showingGuideReplay) {
            GuideSheet(guide: GuideLibrary.guide(.dashboard))
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    private var sessionModeLabel: String {
        switch viewModel.session {
        case .signedOut:
            return "Signed out"
        case .guest:
            return "Guest local"
        case let .signedIn(email, _):
            return email.components(separatedBy: "@").first ?? "Signed in"
        }
    }

    private var subscriptionSurface: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Subscription and services")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                Text("Free mode stays local, while restore and manage actions live on the premium surface.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    BrandMetricTile(
                        title: "Mode",
                        value: viewModel.session.isAuthenticated ? "Cloud ready" : "Local free",
                        systemImage: "lock.fill"
                    )
                    BrandMetricTile(
                        title: "Restore",
                        value: viewModel.session.isAuthenticated ? "Available" : "Sign in first",
                        systemImage: "arrow.clockwise"
                    )
                    BrandMetricTile(
                        title: "Manage",
                        value: "Premium",
                        systemImage: "slider.horizontal.3"
                    )
                    BrandMetricTile(
                        title: "Support",
                        value: "Connected",
                        systemImage: "lifepreserver.fill"
                    )
                }

                NavigationLink {
                    PremiumView(viewModel: viewModel)
                } label: {
                    settingsRouteLabel(
                        title: "Open premium surface",
                        summary: "See restore, manage subscription, and upgrade actions in one place.",
                        systemImage: "sparkles"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func previewAssetCard(title: String, source: BrandAssetSource, fallback: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            BrandAssetImage(source: source, fallbackSystemImage: fallback)
                .frame(width: 72, height: 72)
                .background(BrandTheme.surfaceTint)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
                )

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)
                .frame(width: 88, alignment: .leading)
                .lineLimit(2)
        }
    }

    private func themeDisplayName(_ value: String) -> String {
        switch value {
        case "midnight":
            return "Midnight"
        case "sunrise":
            return "Sunrise"
        default:
            return "Finance"
        }
    }

    @ViewBuilder
    private func settingsPickerRow<SelectionValue: Hashable, Content: View>(
        title: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text("Saved only on this device right now.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
            }

            Spacer(minLength: 12)

            Picker(title, selection: selection) {
                content()
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .tint(BrandTheme.primary)
        }
    }

    private func settingsRouteLabel(title: String, summary: String, systemImage: String) -> some View {
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

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(BrandTheme.muted)
                .padding(.top, 6)
        }
        .padding(.vertical, 2)
    }
}
