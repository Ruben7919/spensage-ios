import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel

    @AppStorage("native.settings.language") private var language = "en"
    @AppStorage("native.settings.currency") private var currency = "USD"
    @AppStorage("native.settings.theme") private var theme = "finance"
    @AppStorage("native.settings.reminders") private var remindersEnabled = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Local-first settings",
                    title: "Settings",
                    summary: "Tune the app, open the budget wizard, and keep support, legal, and advanced tools close in one place.",
                    systemImage: "gearshape.fill"
                )

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Session and shortcuts")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        HStack(spacing: 12) {
                            BrandMetricTile(
                                title: "Mode",
                                value: sessionModeLabel,
                                systemImage: "person.crop.circle"
                            )
                            BrandMetricTile(
                                title: "Theme",
                                value: themeDisplayName(theme),
                                systemImage: "paintpalette.fill"
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
                                    summary: "Inspect exports, support packets, and local debug controls.",
                                    systemImage: "switch.2"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Preferences")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        settingsPickerRow(title: "Language", selection: $language) {
                            Text("English").tag("en")
                            Text("Español").tag("es")
                        }

                        Divider()

                        settingsPickerRow(title: "Currency", selection: $currency) {
                            Text("USD").tag("USD")
                            Text("EUR").tag("EUR")
                            Text("GBP").tag("GBP")
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
                                Text("Keep lightweight nudges enabled while you stay in local-first mode.")
                                    .font(.subheadline)
                                    .foregroundStyle(BrandTheme.muted)
                            }
                        }
                        .tint(BrandTheme.primary)
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
                                summary: "Local export center, diagnostics, and support-ready state.",
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
                                summary: "Build a local support packet and share a clean troubleshooting handoff.",
                                systemImage: "lifepreserver.fill"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            LegalCenterView()
                        } label: {
                            settingsRouteLabel(
                                title: "Legal Center",
                                summary: "Privacy, terms, and public support links for the current build.",
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
