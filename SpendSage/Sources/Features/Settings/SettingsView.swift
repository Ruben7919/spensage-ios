import SwiftUI
import UIKit
import AudioToolbox

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel

    @AppStorage("native.settings.language") private var language = "auto"
    @AppStorage(AppCurrencyFormat.defaultsKey) private var currency = AppCurrencyFormat.defaultCode
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
            return "Meow".appLocalized
        case "off":
            return "Off".appLocalized
        default:
            return "Playful".appLocalized
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Account settings",
                    title: "Settings",
                    summary: "Tune your account experience, keep support nearby, and make the app feel calmer without digging through dense menus.",
                    systemImage: "gearshape.fill",
                    character: .tikki,
                    expression: .proud,
                    sceneKey: "guide_25_splash_team"
                )

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account snapshot")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                            BrandMetricTile(title: "Mode", value: sessionModeLabel, systemImage: "person.crop.circle")
                            BrandMetricTile(title: "Language", value: AppLocalization.menuLabel(for: language), systemImage: "globe")
                            BrandMetricTile(title: "Currency", value: currency, systemImage: "dollarsign.circle.fill")
                            BrandMetricTile(title: "Theme", value: themeDisplayName(theme), systemImage: "paintpalette.fill")
                            BrandMetricTile(title: "Sound", value: soundDisplayName(soundStyle), systemImage: "speaker.wave.2.fill")
                            BrandMetricTile(title: "Device", value: deviceLabel, systemImage: "iphone.gen3")
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
                                    summary: "Exports, diagnostics, and device-level control tools live here.",
                                    systemImage: "switch.2"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                subscriptionSurface

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Your crew")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text("Tikki, Ludo, and Manchas give each part of the app a role so the product feels guided instead of mechanical.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        BrandArtworkSurface {
                            ViewThatFits(in: .horizontal) {
                                HStack(alignment: .center, spacing: 16) {
                                    crewRoleList

                                    BrandAssetImage(
                                        source: BrandAssetCatalog.shared.guide("guide_16_family_mission_board_team"),
                                        fallbackSystemImage: "person.3.fill"
                                    )
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 128, height: 128)
                                }

                                VStack(alignment: .leading, spacing: 16) {
                                    BrandAssetImage(
                                        source: BrandAssetCatalog.shared.guide("guide_16_family_mission_board_team"),
                                        fallbackSystemImage: "person.3.fill"
                                    )
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 156)

                                    crewRoleList
                                }
                            }
                        }

                        MascotSpeechCard(
                            character: .tikki,
                            expression: .proud,
                            title: "Crew update",
                            message: "Keep settings lean. Change only what affects your day-to-day flow, and let the rest stay out of the way."
                        )

                        Button("Replay guides") {
                            GuideProgressStore.resetAll()
                            showingGuideReplay = true
                        }
                        .buttonStyle(SecondaryCTAStyle())
                    }
                }

                appBasicsCard
                remindersCard
                quietHoursCard
                soundCard

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Device and export")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        BrandMetricTile(title: "Device", value: deviceLabel, systemImage: "iphone")
                        BrandMetricTile(title: "Version", value: systemVersionLabel, systemImage: "info.circle.fill")

                        NavigationLink {
                            AdvancedSettingsView(viewModel: viewModel)
                        } label: {
                            settingsRouteLabel(
                                title: "Open export and diagnostics",
                                summary: "Read the local ledger snapshot, copy an export, or share a support packet.",
                                systemImage: "square.and.arrow.up"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account and support")
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
                            HelpCenterView(viewModel: viewModel)
                        } label: {
                            settingsRouteLabel(
                                title: "Help Center",
                                summary: "Guided answers and quick paths when you get stuck.",
                                systemImage: "questionmark.circle.fill"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            SupportCenterView(viewModel: viewModel)
                        } label: {
                            settingsRouteLabel(
                                title: "Support Center",
                                summary: "Build a local packet and share a cleaner troubleshooting summary.",
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
                                summary: "Reference the visual language without leaving Settings.",
                                systemImage: "swatchpalette.fill"
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(BrandTheme.canvas)
        .overlay(alignment: .top) {
            BrandBackdropView()
        }
        .sheet(isPresented: $showingGuideReplay) {
            GuideSheet(guide: GuideLibrary.guide(.dashboard))
        }
        .navigationTitle("Settings".appLocalized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sessionModeLabel: String {
        switch viewModel.session {
        case .signedOut:
            return "Signed out".appLocalized
        case .guest:
            return "Preview guest".appLocalized
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

                Text("Your account keeps plan status, restore, and billing actions in one connected place.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                BrandFeatureRow(
                    systemImage: viewModel.session.isAuthenticated ? "lock.fill" : "person.crop.circle.badge.exclamationmark",
                    title: viewModel.session.isAuthenticated ? "Account ready" : "Sign in for billing",
                    detail: viewModel.session.isAuthenticated
                        ? "Restore, manage, and future billing actions stay tied to this account."
                        : "Plans are visible now, but restore and billing stay connected only after sign-in."
                )

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

    private var crewRoleList: some View {
        VStack(alignment: .leading, spacing: 12) {
            crewRoleRow(
                character: .tikki,
                expression: .proud,
                name: "Tikki",
                role: "Planning, goals, and control"
            )
            crewRoleRow(
                character: .mei,
                expression: .thinking,
                name: "Ludo",
                role: "Insights, reports, and next actions"
            )
            crewRoleRow(
                character: .manchas,
                expression: .happy,
                name: "Manchas",
                role: "Daily check-ins and expense capture"
            )
        }
    }

    private var appBasicsCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                settingsSectionHeader(
                    title: "App basics",
                    summary: "Language, currency, and theme stay together so the everyday feel is easy to tune.",
                    character: .tikki,
                    expression: .happy
                )

                settingsPickerRow(title: "Language", selection: $language) {
                    Text("Auto").tag("auto")
                    Text("English").tag("en")
                    Text("Español").tag("es")
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
            }
        }
    }

    private var remindersCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                settingsSectionHeader(
                    title: "Reminders",
                    summary: "Keep nudges lightweight so the app stays helpful instead of noisy.",
                    character: .manchas,
                    expression: .happy
                )

                Toggle(isOn: $remindersEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily reminders")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text("Keep lightweight nudges enabled while you stay on-device.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                    }
                }
                .tint(BrandTheme.primary)

                Divider()

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
            }
        }
    }

    private var quietHoursCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                settingsSectionHeader(
                    title: "Quiet hours",
                    summary: "Use one calm window instead of micromanaging every reminder.",
                    character: .mei,
                    expression: .thinking
                )

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

                Divider()

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
            }
        }
    }

    private var soundCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                settingsSectionHeader(
                    title: "Sound",
                    summary: "Choose one feedback style and test it quickly.",
                    character: .manchas,
                    expression: .excited
                )

                settingsPickerRow(title: "Notification sound", selection: $soundStyle) {
                    Text("Off").tag("off")
                    Text("Meow").tag("miau")
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
    }

    private func crewRoleRow(
        character: BrandCharacterID,
        expression: BrandExpression,
        name: String,
        role: String
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            MascotAvatarView(character: character, expression: expression, size: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text(name.appLocalized)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text(role.appLocalized)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
        }
    }

    private func settingsSectionHeader(
        title: String,
        summary: String,
        character: BrandCharacterID,
        expression: BrandExpression
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            MascotAvatarView(character: character, expression: expression, size: 54)

            VStack(alignment: .leading, spacing: 4) {
                Text(title.appLocalized)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text(summary.appLocalized)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            Spacer(minLength: 0)
        }
    }

    private func themeDisplayName(_ value: String) -> String {
        switch value {
        case "midnight":
            return "Midnight".appLocalized
        case "sunrise":
            return "Sunrise".appLocalized
        default:
            return "Finance".appLocalized
        }
    }

    @ViewBuilder
    private func settingsPickerRow<SelectionValue: Hashable, Content: View>(
        title: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 12) {
                pickerCopy(title: title)

                Spacer(minLength: 12)

                pickerControl(title: title, selection: selection) {
                    content()
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                pickerCopy(title: title)

                pickerControl(title: title, selection: selection) {
                    content()
                }
            }
        }
    }

    private func settingsRouteLabel(title: String, summary: String, systemImage: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 14) {
                routeIcon(systemImage: systemImage)
                routeCopy(title: title, summary: summary)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(BrandTheme.muted)
                    .padding(.top, 6)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 14) {
                    routeIcon(systemImage: systemImage)
                    routeCopy(title: title, summary: summary)
                }

                HStack {
                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(BrandTheme.muted)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func pickerCopy(title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.appLocalized)
                .font(.headline)
                .foregroundStyle(BrandTheme.ink)
            Text("Saved only on this device right now.")
                .font(.subheadline)
                .foregroundStyle(BrandTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .layoutPriority(1)
    }

    private func pickerControl<SelectionValue: Hashable, Content: View>(
        title: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Picker(title, selection: selection) {
            content()
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .tint(BrandTheme.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(BrandTheme.surfaceTint, in: Capsule())
        .overlay(
            Capsule(style: .continuous)
                .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
        )
    }

    private func routeIcon(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(BrandTheme.primary)
            .frame(width: 42, height: 42)
            .background(BrandTheme.accent.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func routeCopy(title: String, summary: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.appLocalized)
                .font(.headline)
                .foregroundStyle(BrandTheme.ink)
            Text(summary.appLocalized)
                .font(.subheadline)
                .foregroundStyle(BrandTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .layoutPriority(1)
    }
}
