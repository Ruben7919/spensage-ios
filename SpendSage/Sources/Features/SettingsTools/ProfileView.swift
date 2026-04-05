import SwiftUI
import UIKit
import AudioToolbox

struct ProfileView: View {
    @ObservedObject var viewModel: AppViewModel

    @AppStorage("native.settings.language") private var language = "auto"
    @AppStorage(AppCurrencyFormat.defaultsKey) private var currency = AppCurrencyFormat.defaultCode
    @AppStorage("native.settings.theme") private var theme = "finance"
    @AppStorage("native.settings.sound") private var soundStyle = "playful"
    @State private var draft: ProfileRecord
    @State private var isSaving = false

    private var deviceLabel: String {
        UIDevice.current.localizedModel
    }

    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
        _draft = State(initialValue: viewModel.profile)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                snapshotCard
                identityCard
                preferencesCard
                updatesCard
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(BrandTheme.canvas)
        .overlay(alignment: .top) {
            BrandBackdropView()
        }
        .navigationTitle("Profile".appLocalized)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.profile) { _, profile in
            if !isSaving {
                draft = profile
            }
        }
    }

    private var heroCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    MascotAvatarView(
                        character: .mei,
                        expression: viewModel.session.isAuthenticated ? .proud : .thinking,
                        size: 76
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        BrandBadge(text: "Local identity", systemImage: "person.crop.circle.fill")

                                Text("Profile")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)

                        Text("Keep your identity, household label, and account context clear without turning profile into a settings dump.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                BrandScenePanel(
                    sceneKey: "guide_21_profile_identity_ludo",
                    fallbackSystemImage: "person.crop.circle.fill",
                    height: 184
                )

                CharacterCrewRail(
                    members: [
                        CharacterCrewMember(
                            title: "Tikki",
                            role: "Account guide",
                            detail: "Keeps the profile actions simple and trustworthy.",
                            character: .tikki,
                            expression: .proud
                        ),
                        CharacterCrewMember(
                            title: "Ludo",
                            role: "Identity guide",
                            detail: "Keeps names, household details, and account context readable at a glance.",
                            character: .mei,
                            expression: .proud
                        ),
                        CharacterCrewMember(
                            title: "Manchas",
                            role: "Household keeper",
                            detail: "Keeps the local profile feeling grounded.",
                            character: .manchas,
                            expression: .happy
                        )
                    ]
                )
            }
        }
    }

    private var snapshotCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    MascotAvatarView(
                        character: .manchas,
                        expression: viewModel.session.isAuthenticated ? .proud : .thinking,
                        size: 72
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        BrandBadge(
                            text: LocalLedgerExportComposer.sessionLabel(for: viewModel.session),
                            systemImage: viewModel.session.isAuthenticated ? "person.crop.circle.badge.checkmark" : "person.crop.circle.badge.xmark"
                        )

                        Text("Local account snapshot")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text("This screen stays tied to your account so profile details remain personal and ready for sync.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    BrandMetricTile(title: "Accounts", value: "\(viewModel.accounts.count)", systemImage: "wallet.pass.fill")
                    BrandMetricTile(title: "Bills", value: "\(viewModel.bills.count)", systemImage: "calendar.badge.clock")
                    BrandMetricTile(title: "Rules", value: "\(viewModel.rules.count)", systemImage: "line.3.horizontal.decrease.circle")
                    BrandMetricTile(title: "Expenses", value: "\(viewModel.dashboardState?.transactionCount ?? 0)", systemImage: "receipt")
                    BrandMetricTile(title: "Country", value: draft.countryCode, systemImage: "globe")
                    BrandMetricTile(title: "Device", value: deviceLabel, systemImage: "iphone.gen3")
                }
            }
        }
    }

    private var identityCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Identity")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                VStack(spacing: 12) {
                    FinanceField(
                        label: "Full name",
                        placeholder: "Enter your full name",
                        text: $draft.fullName,
                        keyboard: .default,
                        capitalization: .words
                    )

                    FinanceField(
                        label: "Household name",
                        placeholder: "Enter a household label",
                        text: $draft.householdName,
                        keyboard: .default,
                        capitalization: .words
                    )

                    FinanceField(
                        label: "Email",
                        placeholder: "name@domain.com",
                        text: $draft.email,
                        keyboard: .emailAddress,
                        capitalization: .never
                    )

                    Picker("Country", selection: $draft.countryCode) {
                        ForEach(["US", "EC", "ES", "MX", "GB"], id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }

                    Toggle("Send local product and launch updates", isOn: $draft.marketingOptIn)
                }

                Button(isSaving ? "Saving..." : "Save profile on this device") {
                    saveProfile()
                }
                .buttonStyle(PrimaryCTAStyle())
                .disabled(isSaving)
            }
        }
    }

    private var updatesCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("What this updates")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                BrandFeatureRow(
                    systemImage: "person.text.rectangle",
                    title: "Profile identity",
                    detail: "Your name, household label, and email flow into local exports and support packets."
                )
                BrandFeatureRow(
                    systemImage: "square.and.arrow.down.on.square",
                    title: "Local-first persistence",
                    detail: "Changes are saved with the on-device ledger using the existing profile record."
                )
                BrandFeatureRow(
                    systemImage: "sparkles.rectangle.stack",
                    title: "Settings nearby",
                    detail: "Profile now mirrors the most personal display preferences too, so identity and presentation can be reviewed together."
                )
            }
        }
    }

    private var preferencesCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Display and feedback")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                preferenceMenu(title: "Language", selection: $language) {
                    Text("Auto").tag("auto")
                    Text("English").tag("en")
                    Text("Español").tag("es")
                }

                Divider()

                preferenceMenu(title: "Currency", selection: $currency) {
                    Text("USD").tag("USD")
                    Text("EUR").tag("EUR")
                    Text("GBP").tag("GBP")
                    Text("JPY").tag("JPY")
                    Text("MXN").tag("MXN")
                }

                Divider()

                preferenceMenu(title: "Theme", selection: $theme) {
                    Text("Finance").tag("finance")
                    Text("Midnight").tag("midnight")
                    Text("Sunrise").tag("sunrise")
                }

                Divider()

                preferenceMenu(title: "Sound style", selection: $soundStyle) {
                    Text("Off").tag("off")
                    Text("Meow").tag("miau")
                    Text("Playful").tag("playful")
                }

                Button("Test sound") {
                    guard soundStyle != "off" else { return }
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    AudioServicesPlaySystemSound(1104)
                }
                .buttonStyle(SecondaryCTAStyle())
                .disabled(soundStyle == "off")
            }
        }
    }

    private func saveProfile() {
        isSaving = true
        let normalized = ProfileRecord(
            fullName: draft.fullName.trimmingCharacters(in: .whitespacesAndNewlines).ifEmpty(replacingWith: viewModel.profile.fullName),
            householdName: draft.householdName.trimmingCharacters(in: .whitespacesAndNewlines).ifEmpty(replacingWith: viewModel.profile.householdName),
            email: draft.email.trimmingCharacters(in: .whitespacesAndNewlines).ifEmpty(replacingWith: viewModel.profile.email),
            countryCode: draft.countryCode,
            marketingOptIn: draft.marketingOptIn
        )

        Task {
            await viewModel.saveProfile(normalized)
            draft = normalized
            isSaving = false
        }
    }

    @ViewBuilder
    private func preferenceMenu<SelectionValue: Hashable, Content: View>(
        title: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.appLocalized)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text("Saved locally for this device.")
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
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(BrandTheme.surfaceTint, in: Capsule())
            .overlay(
                Capsule(style: .continuous)
                    .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
            )
        }
    }
}
private extension String {
    func ifEmpty(replacingWith fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
