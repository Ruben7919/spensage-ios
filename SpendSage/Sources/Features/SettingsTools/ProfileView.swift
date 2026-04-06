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
                identityCard
                routesCard
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(BrandTheme.canvas)
        .overlay(alignment: .top) {
            BrandBackdropView()
        }
        .navigationTitle("Perfil")
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
                BrandCardHeader(
                    badgeText: "Identidad local",
                    badgeSystemImage: "person.crop.circle.fill",
                    title: "Perfil",
                    summary: "Mantén tu identidad clara aquí. Los detalles de cuenta y las preferencias viven en rutas separadas para no convertir perfil en un panel pesado.",
                    titleSize: 32
                ) {
                    MascotAvatarView(
                        character: .mei,
                        expression: viewModel.session.isAuthenticated ? .proud : .thinking,
                        size: 76
                    )
                }

                FlowStack(spacing: 8, rowSpacing: 8) {
                    StoryTag(text: "Cuenta local", systemImage: "lock.fill")
                    StoryTag(text: "Preferencias separadas", systemImage: "slider.horizontal.3")
                    StoryTag(text: "Edición rápida", systemImage: "square.and.pencil")
                }
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

                        Text("Resumen local de la cuenta")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text("Esta pantalla se mantiene atada a tu cuenta para que los datos del perfil sigan siendo personales y listos para futuras funciones de cuenta.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    BrandMetricTile(title: "Cuentas", value: "\(viewModel.accounts.count)", systemImage: "wallet.pass.fill")
                    BrandMetricTile(title: "Facturas", value: "\(viewModel.bills.count)", systemImage: "calendar.badge.clock")
                    BrandMetricTile(title: "Reglas", value: "\(viewModel.rules.count)", systemImage: "line.3.horizontal.decrease.circle")
                    BrandMetricTile(title: "Gastos", value: "\(viewModel.dashboardState?.transactionCount ?? 0)", systemImage: "receipt")
                    BrandMetricTile(title: "País", value: draft.countryCode, systemImage: "globe")
                    BrandMetricTile(title: "Dispositivo", value: deviceLabel, systemImage: "iphone.gen3")
                }
            }
        }
    }

    private var identityCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Identidad")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                VStack(spacing: 12) {
                    FinanceField(
                        label: "Nombre completo",
                        placeholder: "Escribe tu nombre completo",
                        text: $draft.fullName,
                        keyboard: .default,
                        capitalization: .words
                    )

                    FinanceField(
                        label: "Nombre del hogar",
                        placeholder: "Escribe un nombre para el hogar",
                        text: $draft.householdName,
                        keyboard: .default,
                        capitalization: .words
                    )

                    FinanceField(
                        label: "Correo",
                        placeholder: "name@domain.com",
                        text: $draft.email,
                        keyboard: .emailAddress,
                        capitalization: .never
                    )

                    Picker("País", selection: $draft.countryCode) {
                        ForEach(["US", "EC", "ES", "MX", "GB"], id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }

                    Toggle("Recibir novedades del producto", isOn: $draft.marketingOptIn)
                }

                Button(isSaving ? "Guardando..." : "Guardar perfil en este dispositivo") {
                    saveProfile()
                }
                .buttonStyle(PrimaryCTAStyle())
                .disabled(isSaving)
            }
        }
    }

    private var routesCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Más opciones")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                NavigationLink {
                    ProfilePreferencesDetailView(
                        language: $language,
                        currency: $currency,
                        theme: $theme,
                        soundStyle: $soundStyle
                    )
                } label: {
                    profileRouteRow(
                        title: "Preferencias",
                        summary: "Idioma, moneda, tema y sonido.",
                        systemImage: "paintpalette.fill"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    ProfileAccountDetailsView(
                        viewModel: viewModel,
                        draft: draft,
                        deviceLabel: deviceLabel
                    )
                } label: {
                    profileRouteRow(
                        title: "Detalle de cuenta",
                        summary: "Resumen local, país, dispositivo y efecto de tus cambios.",
                        systemImage: "person.text.rectangle"
                    )
                }
                .buttonStyle(.plain)
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
                Text("Guardado localmente en este dispositivo.")
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

    private func profileRouteRow(title: String, summary: String, systemImage: String) -> some View {
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
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(BrandTheme.muted)
                .padding(.top, 6)
        }
    }
}

private struct ProfilePreferencesDetailView: View {
    @Binding var language: String
    @Binding var currency: String
    @Binding var theme: String
    @Binding var soundStyle: String

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Preferencias")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)

                        Text("Cambia presentación y sonido aquí sin recargar la pantalla principal de perfil.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Pantalla y feedback")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        profilePreferenceMenu(title: "Idioma", selection: $language) {
                            Text("Auto").tag("auto")
                            Text("English").tag("en")
                            Text("Español").tag("es")
                        }

                        Divider()

                        profilePreferenceMenu(title: "Moneda", selection: $currency) {
                            Text("USD").tag("USD")
                            Text("EUR").tag("EUR")
                            Text("GBP").tag("GBP")
                            Text("JPY").tag("JPY")
                            Text("MXN").tag("MXN")
                        }

                        Divider()

                        profilePreferenceMenu(title: "Tema", selection: $theme) {
                            Text("Finance").tag("finance")
                            Text("Midnight").tag("midnight")
                            Text("Sunrise").tag("sunrise")
                        }

                        Divider()

                        profilePreferenceMenu(title: "Sonido", selection: $soundStyle) {
                            Text("Off").tag("off")
                            Text("Meow").tag("miau")
                            Text("Playful").tag("playful")
                        }

                        Button("Probar sonido") {
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .overlay(alignment: .top) {
            BrandBackdropView()
        }
        .navigationTitle("Preferencias")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProfileAccountDetailsView: View {
    @ObservedObject var viewModel: AppViewModel
    let draft: ProfileRecord
    let deviceLabel: String

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Detalle de cuenta")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)

                        Text("Aquí vive el contexto local de la cuenta. Separamos esta información para que perfil principal siga enfocado en identidad.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Resumen local")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            BrandMetricTile(title: "Cuentas", value: "\(viewModel.accounts.count)", systemImage: "wallet.pass.fill")
                            BrandMetricTile(title: "Facturas", value: "\(viewModel.bills.count)", systemImage: "calendar.badge.clock")
                            BrandMetricTile(title: "Reglas", value: "\(viewModel.rules.count)", systemImage: "line.3.horizontal.decrease.circle")
                            BrandMetricTile(title: "Gastos", value: "\(viewModel.dashboardState?.transactionCount ?? 0)", systemImage: "receipt")
                            BrandMetricTile(title: "País", value: draft.countryCode, systemImage: "globe")
                            BrandMetricTile(title: "Dispositivo", value: deviceLabel, systemImage: "iphone.gen3")
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Efecto de tus cambios")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        BrandFeatureRow(
                            systemImage: "person.text.rectangle",
                            title: "Identidad de perfil",
                            detail: "Tu nombre, nombre del hogar y correo entran en exportaciones locales y paquetes de soporte."
                        )
                        BrandFeatureRow(
                            systemImage: "square.and.arrow.down.on.square",
                            title: "Persistencia local",
                            detail: "Los cambios se guardan con el libro financiero local de esta cuenta."
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .overlay(alignment: .top) {
            BrandBackdropView()
        }
        .navigationTitle("Detalle de cuenta")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private func profilePreferenceMenu<SelectionValue: Hashable, Content: View>(
    title: String,
    selection: Binding<SelectionValue>,
    @ViewBuilder content: () -> Content
) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        Text(title.appLocalized)
            .font(.headline)
            .foregroundStyle(BrandTheme.ink)

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
private extension String {
    func ifEmpty(replacingWith fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
