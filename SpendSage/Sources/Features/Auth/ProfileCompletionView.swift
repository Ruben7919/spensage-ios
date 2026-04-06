import SwiftUI

struct ProfileCompletionView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var fullName: String
    @State private var countryCode: String
    @State private var isSaving = false

    private let email: String

    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
        let setup = viewModel.pendingProfileSetup
        _fullName = State(initialValue: setup?.suggestedFullName ?? "")
        _countryCode = State(initialValue: setup?.countryCode ?? "US")
        email = setup?.email ?? viewModel.session.emailAddress ?? ""
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Un paso rápido",
                    title: "Completa tu cuenta",
                    summary: "Antes de entrar, confirma cómo te llamamos y tu país. Con eso la experiencia ya se siente personal sin pedirte de más.",
                    systemImage: "person.crop.circle.badge.checkmark",
                    character: .mei,
                    expression: .proud,
                    sceneKey: "guide_21_profile_identity_ludo"
                )

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Esta cuenta ya quedó conectada. Solo falta guardarla con tus datos básicos.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Correo")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BrandTheme.muted)

                            Text(email)
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(BrandTheme.surfaceTint)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }

                        FinanceField(
                            label: "Tu nombre",
                            placeholder: "Ruben",
                            text: $fullName,
                            keyboard: .default,
                            capitalization: .words
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("País")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BrandTheme.muted)

                            Picker("País", selection: $countryCode) {
                                ForEach(["US", "EC", "ES", "MX", "GB"], id: \.self) { code in
                                    Text(code).tag(code)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        Button(isSaving ? "Guardando..." : "Guardar y continuar") {
                            save()
                        }
                        .buttonStyle(PrimaryCTAStyle())
                        .disabled(isSaving || fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .padding(24)
        }
        .background(FinanceScreenBackground())
        .navigationTitle("Bienvenido")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cerrar sesión") {
                    viewModel.signOut()
                }
                .font(.subheadline.weight(.semibold))
            }
        }
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true

        Task {
            await viewModel.completeWelcomeProfile(
                fullName: fullName,
                countryCode: countryCode
            )
            isSaving = false
        }
    }
}
