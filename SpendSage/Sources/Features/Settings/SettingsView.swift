import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel

    @AppStorage("native.settings.language") private var language = "auto"
    @AppStorage(AppCurrencyFormat.defaultsKey) private var currency = AppCurrencyFormat.defaultCode
    @AppStorage("native.settings.theme") private var theme = "finance"
    @Environment(\.shellBottomInset) private var shellBottomInset
    @AppStorage("native.settings.localDebugOverlay") private var debugOverlayEnabled = false
    @AppStorage(AuthSessionPreferences.rememberDeviceKey) private var rememberDeviceEnabled = true
    @AppStorage(AuthSessionPreferences.biometricUnlockKey) private var biometricUnlockEnabled = true
    @State private var showingGuideReplay = false

    private var biometricLabel: String {
        viewModel.biometricKind.displayName
    }

    private var sessionModeLabel: String {
        switch viewModel.session {
        case .signedOut:
            return "Sesión cerrada"
        case .guest:
            return "Vista previa"
        case let .signedIn(email, provider):
            if provider == "Preview" {
                return "Cuenta"
            }
            return email.components(separatedBy: "@").first ?? "Sesión iniciada"
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                overviewCard
                personalizeCard
                accountAndHelpCard
                moreCard
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, shellBottomInset > 0 ? 12 : 40)
        }
        .accessibilityIdentifier("settings.screen")
        .background(FinanceScreenBackground())
        .sheet(isPresented: $showingGuideReplay) {
            GuideSheet(guide: GuideLibrary.guide(.dashboard))
        }
        .onChange(of: rememberDeviceEnabled) { _, newValue in
            viewModel.updateRememberDevicePreference(enabled: newValue)
            if !newValue {
                biometricUnlockEnabled = false
            }
        }
        .onChange(of: biometricUnlockEnabled) { _, newValue in
            viewModel.updateBiometricUnlockPreference(enabled: newValue)
        }
        .navigationTitle("Ajustes")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var overviewCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSummaryHeader(
                    badge: "Configuración simple",
                    title: "Ajustes",
                    summary: "Mantén esta área corta. Abre una sección solo cuando quieras cambiar cómo se ve, suena o te recuerda algo la app.",
                    character: .tikki,
                    expression: .proud
                )

                FlowStack(spacing: 8, rowSpacing: 8) {
                    BrandBadge(
                        text: rememberDeviceEnabled ? "Inicio rápido" : "Ingreso manual",
                        systemImage: "iphone.gen3"
                    )
                    BrandBadge(
                        text: viewModel.biometricKind == .none
                            ? "Seguridad local"
                            : (biometricUnlockEnabled ? biometricLabel : "Biometría lista"),
                        systemImage: viewModel.biometricKind == .none
                            ? "lock.shield"
                            : viewModel.biometricKind.systemImage
                    )
                    BrandBadge(
                        text: settingsThemeDisplayName(theme),
                        systemImage: "paintpalette.fill"
                    )
                }

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(title: "Modo", value: sessionModeLabel, systemImage: "person.crop.circle")
                    BrandMetricTile(title: "Idioma", value: AppLocalization.menuLabel(for: language), systemImage: "globe")
                    BrandMetricTile(title: "Moneda", value: currency, systemImage: "dollarsign.circle.fill")
                    BrandMetricTile(title: "Tema", value: settingsThemeDisplayName(theme), systemImage: "paintpalette.fill")
                }
            }
        }
    }

    private var personalizeCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Configuración de la app")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                Text("Separa lo básico de los recordatorios para que la pantalla principal se sienta más liviana y fácil de revisar.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                NavigationLink {
                    SettingsPreferencesView()
                } label: {
                    SettingsNavigationRow(
                        title: "Apariencia y región",
                        summary: "Idioma, moneda y tema viven aquí.",
                        systemImage: "paintpalette.fill"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.link.preferences")

                NavigationLink {
                    SettingsNotificationsView(viewModel: viewModel)
                } label: {
                    SettingsNavigationRow(
                        title: "Notificaciones y calma",
                        summary: "Recordatorios, horas de silencio y sonido quedan juntos.",
                        systemImage: "bell.badge.fill"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.link.notifications")

                Button("Abrir asistente de presupuesto") {
                    viewModel.presentBudgetWizard()
                }
                .buttonStyle(PrimaryCTAStyle())
                .accessibilityIdentifier("settings.action.budgetWizard")
            }
        }
    }

    private var accountAndHelpCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Cuenta y ayuda")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                SettingsToggleRow(
                    title: "Recordar este dispositivo",
                    summary: "Mantiene tu cuenta lista para volver a entrar sin repetir Apple, Google o email cada vez.",
                    isOn: $rememberDeviceEnabled
                )

                if viewModel.biometricKind != .none {
                    Divider()

                    SettingsToggleRow(
                        title: "Abrir con \(biometricLabel)",
                        summary: "Usa la biometría del iPhone para abrir la cuenta guardada al volver a la app.",
                        isOn: $biometricUnlockEnabled
                    )
                    .disabled(!rememberDeviceEnabled)
                    .opacity(rememberDeviceEnabled ? 1 : 0.45)
                }

                Divider()

                NavigationLink {
                    ProfileView(viewModel: viewModel)
                } label: {
                    SettingsNavigationRow(
                        title: "Perfil",
                        summary: "Identidad, nombre del hogar y contexto local de la cuenta.",
                        systemImage: "person.text.rectangle"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.link.profile")

                NavigationLink {
                    PremiumView(viewModel: viewModel)
                } label: {
                    SettingsNavigationRow(
                        title: "Planes",
                        summary: "Revisa la base gratis, premium y familia.",
                        systemImage: "sparkles"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.link.plans")

                NavigationLink {
                    SharedSpacesView(viewModel: viewModel)
                } label: {
                    SettingsNavigationRow(
                        title: "Spaces y familia",
                        summary: "Selecciona espacios, invita miembros y administra el plan compartido.",
                        systemImage: "person.3.fill"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.link.spaces")

                NavigationLink {
                    HelpCenterView(viewModel: viewModel)
                } label: {
                    SettingsNavigationRow(
                        title: "Centro de ayuda",
                        summary: "Respuestas guiadas para las dudas más comunes.",
                        systemImage: "questionmark.circle.fill"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.link.help")

                NavigationLink {
                    SupportCenterView(viewModel: viewModel)
                } label: {
                    SettingsNavigationRow(
                        title: "Centro de soporte",
                        summary: "Prepara un paquete local más limpio cuando necesites soporte.",
                        systemImage: "lifepreserver.fill"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.link.support")

                NavigationLink {
                    LegalCenterView()
                } label: {
                    SettingsNavigationRow(
                        title: "Centro legal",
                        summary: "Privacidad, términos y enlaces públicos de confianza.",
                        systemImage: "doc.text.fill"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.link.legal")
            }
        }
    }

    private var moreCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Más")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                NavigationLink {
                    AdvancedSettingsView(viewModel: viewModel)
                } label: {
                    SettingsNavigationRow(
                        title: "Exportación y soporte avanzado",
                        summary: "Exporta datos, revisa diagnósticos y prepara soporte cuando haga falta.",
                        systemImage: "switch.2"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.link.advanced")

                if debugOverlayEnabled {
                    NavigationLink {
                        BrandGalleryView()
                    } label: {
                        SettingsNavigationRow(
                            title: "Galería de marca",
                            summary: "Revisa la librería de personajes y temporadas solo en modo interno.",
                            systemImage: "swatchpalette.fill"
                        )
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 12) {
                    Button("Volver a mostrar guías") {
                        GuideProgressStore.resetAll()
                        showingGuideReplay = true
                    }
                    .buttonStyle(SecondaryCTAStyle())

                    Button("Cerrar sesión") {
                        Task { await viewModel.signOut() }
                    }
                    .buttonStyle(SecondaryCTAStyle())
                    .foregroundStyle(.red)
                }
            }
        }
    }
}

private struct SettingsPreferencesView: View {
    @AppStorage("native.settings.language") private var language = "auto"
    @AppStorage(AppCurrencyFormat.defaultsKey) private var currency = AppCurrencyFormat.defaultCode
    @AppStorage("native.settings.theme") private var theme = "finance"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                SurfaceCard {
                    SettingsSummaryHeader(
                        badge: "Apariencia",
                        title: "Apariencia y región",
                        summary: "Mantén la configuración visual y regional en un solo lugar para que sea fácil de cambiar y fácil de revisar.",
                        character: .tikki,
                        expression: .happy
                    )
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Básicos")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        SettingsChoiceRow(title: "Idioma", summary: "Por ahora se guarda solo en este dispositivo.", selection: $language) {
                            Text("Auto".appLocalized).tag("auto")
                            Text("English".appLocalized).tag("en")
                            Text("Español".appLocalized).tag("es")
                        }

                        Divider()

                        SettingsChoiceRow(title: "Moneda", summary: "Se usa en dashboard, gastos y exportaciones de este dispositivo.", selection: $currency) {
                            Text("USD").tag("USD")
                            Text("EUR").tag("EUR")
                            Text("GBP").tag("GBP")
                            Text("JPY").tag("JPY")
                            Text("MXN").tag("MXN")
                        }

                        Divider()

                        SettingsChoiceRow(title: "Tema", summary: "Elige el look general sin cambiar el flujo del producto.", selection: $theme) {
                            Text("Finance".appLocalized).tag("finance")
                            Text("Midnight".appLocalized).tag("midnight")
                            Text("Sunrise".appLocalized).tag("sunrise")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(BrandTheme.canvas)
        .background(alignment: .top) {
            BrandBackdropView()
        }
        .navigationTitle("Apariencia y región")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SettingsNotificationsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.openURL) private var openURL
    @AppStorage("native.settings.calendarBillSyncEnabled") private var calendarBillSyncEnabled = false
    @AppStorage("native.settings.reminders") private var remindersEnabled = true
    @AppStorage("native.settings.sound") private var soundStyle = "playful"
    @AppStorage("native.settings.quietHoursEnabled") private var quietHoursEnabled = true
    @AppStorage("native.settings.quietHoursStart") private var quietHoursStart = "22:00"
    @AppStorage("native.settings.quietHoursEnd") private var quietHoursEnd = "07:00"
    @AppStorage("native.settings.weekendQuietMode") private var weekendQuietMode = true
    @AppStorage("native.settings.maxNotificationsPerDay") private var maxNotificationsPerDay = 2
    @AppStorage("native.settings.maxNotificationsPerWeek") private var maxNotificationsPerWeek = 5

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                SurfaceCard {
                    SettingsSummaryHeader(
                        badge: "Recordatorios tranquilos",
                        title: "Notificaciones y calma",
                        summary: "Mantén los recordatorios útiles y ligeros. Si una opción no afecta tu día a día, déjala como está.",
                        character: .manchas,
                        expression: .happy
                    )
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Push de este iPhone")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        BrandFeatureRow(
                            systemImage: viewModel.pushRegistrationStatus.backendEnabled ? "checkmark.icloud.fill" : "icloud.slash.fill",
                            title: "Backend",
                            detail: viewModel.pushRegistrationStatus.backendEnabled
                                ? "El backend permite registro push para esta app."
                                : "Dev aún no tiene APNs/SNS activos para esta app."
                        )

                        BrandFeatureRow(
                            systemImage: viewModel.pushRegistrationStatus.authorization.systemImage,
                            title: "Permiso del iPhone",
                            detail: viewModel.pushRegistrationStatus.authorization.summary
                        )

                        BrandFeatureRow(
                            systemImage: viewModel.pushRegistrationStatus.cachedTokenSuffix == nil ? "iphone.slash" : "iphone.radiowaves.left.and.right",
                            title: "Token APNs",
                            detail: viewModel.pushRegistrationStatus.cachedTokenSuffix.map { "Registrado localmente \($0)" }
                                ?? "Todavía no hay token APNs guardado en este iPhone."
                        )

                        if let lastUploadedAt = viewModel.pushRegistrationStatus.lastUploadedAt {
                            BrandFeatureRow(
                                systemImage: "checkmark.seal.fill",
                                title: "Última vinculación cloud",
                                detail: "Subido el \(lastUploadedAt.formatted(date: .abbreviated, time: .shortened))"
                            )
                        }

                        if let lastError = viewModel.pushRegistrationStatus.lastError, !lastError.isEmpty {
                            BrandFeatureRow(
                                systemImage: "exclamationmark.triangle.fill",
                                title: "Último error",
                                detail: lastError
                            )
                        }

                        Button(viewModel.pushRegistrationStatus.cachedTokenSuffix == nil ? "Activar push en este iPhone" : "Revalidar push en este iPhone") {
                            Task { await viewModel.registerPushNotifications() }
                        }
                        .buttonStyle(PrimaryCTAStyle())
                        .disabled(
                            !viewModel.session.isAuthenticated
                                || !viewModel.pushRegistrationStatus.backendEnabled
                                || viewModel.pushRegistrationStatus.isRegistering
                        )

                        Button("Enviar push de prueba") {
                            Task { await viewModel.sendTestPushNotification() }
                        }
                        .buttonStyle(SecondaryCTAStyle())
                        .disabled(
                            !viewModel.session.isAuthenticated
                                || !viewModel.pushRegistrationStatus.backendEnabled
                                || viewModel.pushRegistrationStatus.cachedTokenSuffix == nil
                                || viewModel.pushRegistrationStatus.isSendingTestPush
                        )

                        if viewModel.pushRegistrationStatus.authorization == .denied {
                            Button("Abrir ajustes del sistema") {
                                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                                openURL(url)
                            }
                            .buttonStyle(SecondaryCTAStyle())
                        }

                        if !viewModel.session.isAuthenticated {
                            Text("La cuenta es obligatoria para registrar este iPhone contra `/devices/register`.")
                                .font(.footnote)
                                .foregroundStyle(BrandTheme.muted)
                        } else {
                            Text("Si no usaste la app o no cruzaste alertas de presupuesto, es normal no recibir pushes todavía. Usa el push de prueba para validar entrega.")
                                .font(.footnote)
                                .foregroundStyle(BrandTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Calendario y ubicación")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        SettingsToggleRow(
                            title: "Sincronizar facturas con Calendario",
                            summary: "Crea recordatorios opcionales para tus facturas recurrentes usando el calendario del iPhone.",
                            isOn: $calendarBillSyncEnabled
                        )

                        Divider()

                        BrandFeatureRow(
                            systemImage: viewModel.calendarSyncStatus.authorization.systemImage,
                            title: "Permiso de Calendario",
                            detail: viewModel.calendarSyncStatus.authorization.summary
                        )

                        if let lastSyncedAt = viewModel.calendarSyncStatus.lastSyncedAt {
                            BrandFeatureRow(
                                systemImage: "checkmark.seal.fill",
                                title: "Última sincronización",
                                detail: "Se actualizaron \(viewModel.calendarSyncStatus.syncedBillCount ?? 0) facturas el \(lastSyncedAt.formatted(date: .abbreviated, time: .shortened))."
                            )
                        }

                        Button("Sincronizar facturas ahora") {
                            Task { await viewModel.syncBillsToCalendar() }
                        }
                        .buttonStyle(PrimaryCTAStyle())
                        .disabled(viewModel.calendarSyncStatus.isSyncing)

                        Divider()

                        BrandFeatureRow(
                            systemImage: viewModel.expenseLocationStatus.systemImage,
                            title: "Permiso de ubicación",
                            detail: viewModel.expenseLocationStatus.summary
                        )

                        Button("Permitir ubicación para etiquetar gastos") {
                            Task { await viewModel.requestExpenseLocationPermission() }
                        }
                        .buttonStyle(SecondaryCTAStyle())

                        if viewModel.calendarSyncStatus.authorization == .denied || viewModel.expenseLocationStatus == .denied {
                            Button("Abrir ajustes del sistema") {
                                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                                openURL(url)
                            }
                            .buttonStyle(SecondaryCTAStyle())
                        }

                        Text("SpendSage no usa ubicación en background. La ubicación solo se consulta cuando tú eliges etiquetar un gasto y el calendario solo se toca para recordatorios de facturas.")
                            .font(.footnote)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recordatorios")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        SettingsToggleRow(
                            title: "Recordatorios diarios",
                            summary: "Activa o apaga recordatorios de rutina para este dispositivo.",
                            isOn: $remindersEnabled
                        )

                        Divider()

                        SettingsChoiceRow(
                            title: "Máximo de notificaciones por día",
                            summary: "Define un límite diario ligero para que la app siga siendo útil.",
                            selection: $maxNotificationsPerDay
                        ) {
                            Text("1").tag(1)
                            Text("2").tag(2)
                            Text("3").tag(3)
                        }

                        Divider()

                        SettingsChoiceRow(
                            title: "Máximo de notificaciones por semana",
                            summary: "Limita cuántas veces la app te recuerda algo a lo largo de la semana.",
                            selection: $maxNotificationsPerWeek
                        ) {
                            Text("3").tag(3)
                            Text("4").tag(4)
                            Text("5").tag(5)
                            Text("6").tag(6)
                            Text("7").tag(7)
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Horas de silencio")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        SettingsToggleRow(
                            title: "Horas de silencio",
                            summary: "Pausa el ruido de recordatorios durante la franja que elijas.",
                            isOn: $quietHoursEnabled
                        )

                        Divider()

                        SettingsChoiceRow(
                            title: "Inicio del silencio",
                            summary: "Elige cuándo comienza la ventana tranquila.",
                            selection: $quietHoursStart
                        ) {
                            Text("21:00").tag("21:00")
                            Text("22:00").tag("22:00")
                            Text("23:00").tag("23:00")
                            Text("00:00").tag("00:00")
                        }

                        Divider()

                        SettingsChoiceRow(
                            title: "Fin del silencio",
                            summary: "Elige cuándo pueden volver los recordatorios.",
                            selection: $quietHoursEnd
                        ) {
                            Text("06:00").tag("06:00")
                            Text("07:00").tag("07:00")
                            Text("08:00").tag("08:00")
                            Text("09:00").tag("09:00")
                        }

                        Divider()

                        SettingsToggleRow(
                            title: "Silencio en fin de semana",
                            summary: "Mantén los fines de semana más tranquilos salvo que abras la app tú mismo.",
                            isOn: $weekendQuietMode
                        )
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sonido")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        SettingsChoiceRow(
                            title: "Sonido de notificación",
                            summary: "Elige un estilo de respuesta y pruébalo aquí.",
                            selection: $soundStyle
                        ) {
                            Text("Silencio").tag("off")
                            Text("Miau").tag("miau")
                            Text("Juguetón").tag("playful")
                        }

                        Button("Probar sonido de notificación") {
                            NotificationSoundPreviewService.shared.play(
                                style: AppNotificationSoundStyle(rawPreference: soundStyle)
                            )
                        }
                        .buttonStyle(SecondaryCTAStyle())
                        .disabled(AppNotificationSoundStyle(rawPreference: soundStyle) == .off)

                        BrandFeatureRow(
                            systemImage: "speaker.wave.2.fill",
                            title: "Sonido actual",
                            detail: AppNotificationSoundStyle(rawPreference: soundStyle).displayName
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(BrandTheme.canvas)
        .background(alignment: .top) {
            BrandBackdropView()
        }
        .task {
            await viewModel.refreshPushRegistrationState()
        }
        .navigationTitle("Notificaciones y calma")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension PushAuthorizationState {
    var summary: String {
        switch self {
        case .authorized:
            return "Las notificaciones están permitidas para este iPhone."
        case .provisional:
            return "Las notificaciones están permitidas provisionalmente."
        case .ephemeral:
            return "La autorización push es temporal."
        case .denied:
            return "Las notificaciones están bloqueadas en Ajustes del sistema."
        case .notDetermined:
            return "Todavía no se ha pedido permiso push en este iPhone."
        }
    }

    var systemImage: String {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return "bell.badge.fill"
        case .denied:
            return "bell.slash.fill"
        case .notDetermined:
            return "bell"
        }
    }
}

private struct SettingsSummaryHeader: View {
    let badge: String
    let title: String
    let summary: String
    let character: BrandCharacterID
    let expression: BrandExpression

    var body: some View {
        BrandCardHeader(
            badgeText: badge,
            badgeSystemImage: "sparkles",
            title: title,
            summary: summary
        ) {
            MascotAvatarView(character: character, expression: expression, size: 68)
        }
    }
}

private struct SettingsNavigationRow: View {
    let title: String
    let summary: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(BrandTheme.primary)
                .frame(width: 42, height: 42)
                .background(BrandTheme.accent.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

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

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(BrandTheme.muted)
                .padding(.top, 6)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

private struct SettingsChoiceRow<SelectionValue: Hashable, Content: View>: View {
    let title: String
    let summary: String
    @Binding var selection: SelectionValue
    let content: Content

    init(
        title: String,
        summary: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.summary = summary
        _selection = selection
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.appLocalized)
                .font(.headline)
                .foregroundStyle(BrandTheme.ink)

            Text(summary.appLocalized)
                .font(.subheadline)
                .foregroundStyle(BrandTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            Picker(title, selection: $selection) {
                content
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

private struct SettingsToggleRow: View {
    let title: String
    let summary: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.appLocalized)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                Text(summary.appLocalized)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(BrandTheme.primary)
    }
}

private func settingsThemeDisplayName(_ value: String) -> String {
    switch value {
    case "midnight":
        return "Medianoche"
    case "sunrise":
        return "Amanecer"
    default:
        return "Finanzas"
    }
}

private func settingsSoundDisplayName(_ value: String) -> String {
    AppNotificationSoundStyle(rawPreference: value).displayName
}

struct SettingsPreferencesDebugView: View {
    var body: some View {
        NavigationStack {
            SettingsPreferencesView()
        }
    }
}

struct SettingsNotificationsDebugView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        NavigationStack {
            SettingsNotificationsView(viewModel: viewModel)
        }
    }
}
