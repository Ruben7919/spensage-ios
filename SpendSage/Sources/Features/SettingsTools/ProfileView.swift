import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var draft: ProfileRecord
    @State private var isSaving = false

    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
        _draft = State(initialValue: viewModel.profile)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Profile")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)

                        Text("Manage the identity and household details stored with your local finance ledger.")
                            .foregroundStyle(BrandTheme.muted)

                        BrandBadge(
                            text: LocalLedgerExportComposer.sessionLabel(for: viewModel.session),
                            systemImage: viewModel.session.isAuthenticated ? "person.crop.circle.badge.checkmark" : "person.crop.circle.badge.xmark"
                        )
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Local account snapshot")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            BrandMetricTile(title: "Accounts", value: "\(viewModel.accounts.count)", systemImage: "wallet.pass.fill")
                            BrandMetricTile(title: "Bills", value: "\(viewModel.bills.count)", systemImage: "calendar.badge.clock")
                            BrandMetricTile(title: "Rules", value: "\(viewModel.rules.count)", systemImage: "line.3.horizontal.decrease.circle")
                            BrandMetricTile(title: "Expenses", value: "\(viewModel.dashboardState?.transactionCount ?? 0)", systemImage: "receipt")
                        }
                    }
                }

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
                    }
                }
            }
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.profile) { _, profile in
            if !isSaving {
                draft = profile
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
}

private extension String {
    func ifEmpty(replacingWith fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
