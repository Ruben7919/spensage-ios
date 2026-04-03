import SwiftUI
import UIKit
import AudioToolbox

struct ProfileView: View {
    @ObservedObject var viewModel: AppViewModel

    @AppStorage("native.settings.language") private var language = "auto"
    @AppStorage("native.settings.currency") private var currency = "USD"
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
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .overlay(alignment: .top) {
            BrandBackdropView()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.profile) { _, profile in
            if !isSaving {
                draft = profile
            }
        }
    }

    private var heroCard: some View {
        FinanceToolsHeaderCard(
            eyebrow: "Local identity",
            title: "Profile",
            summary: "Manage the identity and household details stored with your local finance ledger. These details flow into exports, support packets, and the local account snapshot.",
            systemImage: "person.crop.circle.fill"
        )
    }

    private var snapshotCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    MascotAvatarView(
                        character: .mei,
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

                        Text("This screen stays local-first until you connect a cloud account.")
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
                    TextField("Full name", text: $draft.fullName)
                        .textInputAutocapitalization(.words)
                        .textContentType(.name)

                    TextField("Household name", text: $draft.householdName)
                        .textInputAutocapitalization(.words)

                    TextField("Email", text: $draft.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

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
                    Text("日本語").tag("ja")
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
                    Text("Miau").tag("miau")
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
                Text(title)
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
        }
    }
}

private extension String {
    func ifEmpty(replacingWith fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
