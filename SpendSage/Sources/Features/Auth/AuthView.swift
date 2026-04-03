import SwiftUI
import UIKit

struct AuthView: View {
    @ObservedObject var viewModel: AppViewModel
    @AppStorage("native.settings.language") private var language = "auto"
    @AppStorage("native.auth.rememberDevice") private var rememberDeviceOnSignIn = true

    enum Mode: String, CaseIterable, Identifiable {
        case signIn = "Sign in"
        case createAccount = "Create account"
        case confirmAccount = "Confirm account"
        case resetRequest = "Reset password"
        case resetConfirm = "New password"

        var id: String { rawValue }
    }

    enum Field: Hashable {
        case email
        case password
        case confirmPassword
        case code
        case newPassword
    }

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var infoMessage: String?
    @FocusState private var focusedField: Field?

    private var pendingInviteCode: String? {
        let value = UserDefaults.standard.string(forKey: "native.pendingInviteCode")?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                if pendingInviteCode != nil {
                    invitePendingCard
                }
                emailCard
                if mode == .signIn || mode == .createAccount {
                    socialCard
                }
                if mode == .confirmAccount || mode == .resetRequest || mode == .resetConfirm {
                    helpCard
                }

                if viewModel.authConfiguration.allowsGuestAccess && mode == .signIn {
                    guestCard
                }

                if let notice = viewModel.notice {
                    statusCard(title: "Status", message: notice, systemImage: "checkmark.seal.fill")
                }
            }
            .padding(24)
        }
        .background(
            ZStack {
                BrandTheme.canvas
                BrandBackdropView()
            }
            .ignoresSafeArea()
        )
        .navigationTitle(mode.rawValue.appLocalized)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .topLeading) {
            languagePicker
                .padding(.leading, 24)
                .padding(.top, 12)
        }
    }

    private var heroCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                BrandBadge(
                    text: mode == .signIn ? "Sign in path" : "Create account path",
                    systemImage: "lock.fill"
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text(modeTitle.appLocalized)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandTheme.ink)

                    Text(modeSubtitle.appLocalized)
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 12) {
                    BrandMetricTile(
                        title: "Flow",
                        value: flowLabel.appLocalized,
                        systemImage: "person.crop.circle"
                    )
                    BrandMetricTile(
                        title: "Recovery",
                        value: (mode == .resetConfirm ? "New password" : "Confirm / reset").appLocalized,
                        systemImage: "lifepreserver.fill"
                    )
                }

                HStack(spacing: 8) {
                    if viewModel.authConfiguration.allowsGuestAccess {
                        TagChip(text: "Guest available", systemImage: "iphone.gen3")
                    }
                    TagChip(text: "Apple & Google", systemImage: "person.crop.circle.badge.checkmark")
                    TagChip(text: "Sync later", systemImage: "arrow.triangle.2.circlepath")
                }
            }
        }
    }

    private var flowCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pick the right flow")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text("Keep sign in, create account, confirm, and password recovery on the same entry surface.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Text("02")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(BrandTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(BrandTheme.accent.opacity(0.18), in: Capsule())
                }

                HStack(spacing: 10) {
                    modeButton(.signIn, systemImage: "person.fill.checkmark")
                    modeButton(.createAccount, systemImage: "person.badge.plus")
                }

                HStack(spacing: 10) {
                    modeButton(.confirmAccount, systemImage: "checkmark.seal.fill")
                    modeButton(.resetRequest, systemImage: "key.fill")
                }
            }
        }
    }

    private var invitePendingCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Invite pending")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text("You already have a pending invite code. Use the invited email, then confirm the code from your inbox to finish setup.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    BrandBadge(text: "Pending", systemImage: "person.badge.clock.fill")
                }

                HStack(spacing: 12) {
                    BrandMetricTile(title: "Status", value: "Invite", systemImage: "envelope.badge.fill")
                    BrandMetricTile(title: "Next step", value: "Confirm code", systemImage: "checkmark.seal.fill")
                }
            }
        }
    }

    private var emailCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                BrandBadge(text: "SpendSage", systemImage: "sparkles")

                VStack(alignment: .leading, spacing: 10) {
                    Text(modeTitle.appLocalized)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandTheme.ink)

                    Text(modeSubtitle.appLocalized)
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 10) {
                    modeButton(.signIn, systemImage: "person.fill.checkmark")
                    modeButton(.createAccount, systemImage: "person.badge.plus")
                }

                authField(
                    title: "Email",
                    placeholder: "name@domain.com",
                    text: $email,
                    field: .email,
                    contentType: .emailAddress,
                    isSecure: false
                )

                if mode == .signIn || mode == .createAccount {
                    authField(
                        title: "Password",
                        placeholder: viewModel.authConfiguration.isHostedUIReady
                            ? "Optional for browser sign in"
                            : "Minimum 8 characters",
                        text: $password,
                        field: .password,
                        contentType: .password,
                        isSecure: true
                    )
                }

                if mode == .createAccount {
                    authField(
                        title: "Confirm password",
                        placeholder: "Re-enter password",
                        text: $confirmPassword,
                        field: .confirmPassword,
                        contentType: .newPassword,
                        isSecure: true
                    )
                }

                if mode == .confirmAccount || mode == .resetConfirm {
                    authField(
                        title: "Confirmation code",
                        placeholder: "6-digit code",
                        text: $code,
                        field: .code,
                        contentType: .oneTimeCode,
                        isSecure: false
                    )
                }

                if mode == .resetConfirm {
                    authField(
                        title: "New password",
                        placeholder: "At least 8 characters",
                        text: $newPassword,
                        field: .newPassword,
                        contentType: .newPassword,
                        isSecure: true
                    )
                }

                if mode == .signIn {
                    Toggle(isOn: $rememberDeviceOnSignIn) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Remember this device")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)
                            Text("Keep future sign-ins calmer on this phone.")
                                .font(.subheadline)
                                .foregroundStyle(BrandTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(BrandTheme.primary)
                }

                if let errorMessage {
                    Text(errorMessage.appLocalized)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color(red: 0.72, green: 0.24, blue: 0.20))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                if let infoMessage {
                    Text(infoMessage.appLocalized)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color(red: 0.16, green: 0.45, blue: 0.23))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button(submitLabel.appLocalized) {
                    Task { await submitEmailForm() }
                }
                .buttonStyle(PrimaryCTAStyle())
                .disabled(isLoading || !canSubmit)

                if mode == .confirmAccount {
                    Button("Resend code") {
                        infoMessage = "A fresh confirmation code will be sent to your email when the account service is connected.".appLocalized
                        errorMessage = nil
                    }
                    .buttonStyle(SecondaryCTAStyle())
                }

                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Working on it…")
                            .font(.footnote)
                            .foregroundStyle(BrandTheme.muted)
                    }
                } else if let hint = validationHint {
                    Text(hint.appLocalized)
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }

                HStack(spacing: 12) {
                    if mode != .signIn {
                        inlineModeLink("Back to sign in", target: .signIn)
                    }
                    if mode == .signIn {
                        inlineModeLink("Forgot password?", target: .resetRequest)
                    }
                    if mode == .signIn {
                        inlineModeLink("Need confirmation?", target: .confirmAccount)
                    }
                }
            }
        }
    }

    private var socialCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode == .signIn ? "Continue with Apple or Google" : "Create with Apple or Google")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text(viewModel.authConfiguration.hostedUIFootnote.appLocalized)
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Text("03")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(BrandTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(BrandTheme.accent.opacity(0.18), in: Capsule())
                }

                HStack(spacing: 12) {
                    Button {
                        Task { await submitSocial(.google) }
                    } label: {
                        Label("Google", systemImage: "g.circle.fill")
                    }
                    .buttonStyle(SecondaryCTAStyle())
                    .disabled(isLoading || !supportsProvider(.google))

                    Button {
                        Task { await submitSocial(.apple) }
                    } label: {
                        Label("Apple", systemImage: "applelogo")
                    }
                    .buttonStyle(SecondaryCTAStyle())
                    .disabled(isLoading || !supportsProvider(.apple))
                }

                if !viewModel.authConfiguration.isHostedUIReady {
                    Text("These buttons light up when your account provider is connected.")
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                } else {
                    Text(
                        (
                            mode == .signIn
                                ? "Continue with Apple or Google to sign in through the browser, then come straight back to the app."
                                : "Continue with Apple or Google to create the account in the browser and return here confirmed."
                        ).appLocalized
                    )
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }
            }
        }
    }

    private var helpCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Need help getting back in?")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text("Jump to the exact account route you need without leaving the same entry surface.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Text("04")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(BrandTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(BrandTheme.accent.opacity(0.18), in: Capsule())
                }

                VStack(spacing: 10) {
                    Button {
                        mode = .confirmAccount
                        infoMessage = nil
                        errorMessage = nil
                    } label: {
                        routeRow(
                            title: "Confirm account",
                            summary: "Paste the code from your email and finish setup.",
                            systemImage: "checkmark.seal.fill"
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        mode = .resetRequest
                        infoMessage = nil
                        errorMessage = nil
                    } label: {
                        routeRow(
                            title: "Reset password",
                            summary: "Request a new code and choose a fresh password.",
                            systemImage: "key.fill"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var guestCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Or keep it on this device")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text("Guest mode is the fastest way to try the app. You can sign in later when you want account-backed access.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    BrandBadge(text: "Local only", systemImage: "iphone.gen3")
                }

                Button {
                    Task { await continueAsGuest() }
                } label: {
                    Label("Continue on this device", systemImage: "arrow.right.circle.fill")
                }
                .buttonStyle(PrimaryCTAStyle())
                .disabled(isLoading)

                Text("No account is required to explore the core experience.")
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
            }
        }
    }

    private var submitLabel: String {
        switch mode {
        case .signIn:
            return viewModel.authConfiguration.isHostedUIReady ? "Continue" : "Sign in"
        case .createAccount:
            return "Create account"
        case .confirmAccount:
            return "Confirm account"
        case .resetRequest:
            return "Send reset code"
        case .resetConfirm:
            return "Save new password"
        }
    }

    private var canSubmit: Bool {
        if viewModel.authConfiguration.isHostedUIReady && (mode == .signIn || mode == .createAccount) {
            return isValidEmail(email)
        }
        switch mode {
        case .signIn:
            return isValidEmail(email)
                && password.count >= viewModel.authConfiguration.minimumPasswordLength
        case .createAccount:
            return isValidEmail(email)
                && password.count >= viewModel.authConfiguration.minimumPasswordLength
                && password == confirmPassword
        case .confirmAccount:
            return isValidEmail(email) && !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .resetRequest:
            return isValidEmail(email)
        case .resetConfirm:
            return isValidEmail(email)
                && !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && newPassword.count >= viewModel.authConfiguration.minimumPasswordLength
        }
    }

    private var validationHint: String? {
        if viewModel.authConfiguration.isHostedUIReady && (mode == .signIn || mode == .createAccount) {
            return "You will finish this step in a secure browser session.".appLocalized
        }
        if !isValidEmail(email) {
            return "Use a valid email address.".appLocalized
        }
        if mode == .resetRequest {
            return nil
        }
        if mode == .confirmAccount && code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Paste the confirmation code from your inbox.".appLocalized
        }
        if mode == .resetConfirm && code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Paste the reset code from your inbox.".appLocalized
        }
        if mode == .resetConfirm && newPassword.count < viewModel.authConfiguration.minimumPasswordLength {
            return AppLocalization.localized(
                "Password must be at least %d characters.",
                arguments: viewModel.authConfiguration.minimumPasswordLength
            )
        }
        if mode == .signIn || mode == .createAccount {
            if password.count < viewModel.authConfiguration.minimumPasswordLength {
                return AppLocalization.localized(
                    "Password must be at least %d characters.",
                    arguments: viewModel.authConfiguration.minimumPasswordLength
                )
            }
            if mode == .createAccount && password != confirmPassword {
                return "Passwords must match.".appLocalized
            }
        }
        return nil
    }

    private func supportsProvider(_ provider: SocialProvider) -> Bool {
        viewModel.authConfiguration.supportedSocialProviders.contains(provider)
    }

    private func submitEmailForm() async {
        guard canSubmit else {
            errorMessage = validationHint ?? "Check the form fields.".appLocalized
            return
        }

        isLoading = true
        errorMessage = nil
        infoMessage = nil
        defer { isLoading = false }

        do {
            switch mode {
            case .signIn:
                try await viewModel.signIn(email: email, password: password)
            case .createAccount:
                try await viewModel.createAccount(email: email, password: password)
                infoMessage = "Account created. If confirmation is required, use the code from your inbox.".appLocalized
                mode = .confirmAccount
            case .confirmAccount:
                infoMessage = "Account confirmed. You can now sign in.".appLocalized
                mode = .signIn
                code = ""
            case .resetRequest:
                infoMessage = "Reset code sent. Enter the code from your inbox and choose a new password.".appLocalized
                mode = .resetConfirm
            case .resetConfirm:
                infoMessage = "Password updated. Sign in with the new password.".appLocalized
                mode = .signIn
                code = ""
                newPassword = ""
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func submitSocial(_ provider: SocialProvider) async {
        guard supportsProvider(provider) else {
            errorMessage = AppLocalization.localized("%@ sign-in is not available yet.", arguments: provider.displayName)
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await viewModel.signInWithSocial(provider)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func continueAsGuest() async {
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        defer { isLoading = false }
        await viewModel.continueAsGuest()
    }

    private var modeTitle: String {
        switch mode {
        case .signIn:
            return "Sign in to an existing account"
        case .createAccount:
            return "Create a new account"
        case .confirmAccount:
            return "Confirm your account"
        case .resetRequest:
            return "Request a reset code"
        case .resetConfirm:
            return "Set a new password"
        }
    }

    private var modeSubtitle: String {
        switch mode {
        case .signIn:
            return "Use your email or a hosted provider to return to an existing account. Remember-device and recovery stay on the same entry surface."
        case .createAccount:
            return "Create a new account, confirm it if needed, and keep the setup ready for restore and sync later."
        case .confirmAccount:
            return "Use the email that received the code, paste it here, and finish setup without leaving the same auth surface."
        case .resetRequest:
            return "Ask for a reset code here, then continue directly into the new-password step on the same surface."
        case .resetConfirm:
            return "Paste the reset code and choose a new password so you can go straight back to sign in."
        }
    }

    private var flowLabel: String {
        switch mode {
        case .signIn:
            return "Existing account"
        case .createAccount:
            return "New account"
        case .confirmAccount:
            return "Confirmation"
        case .resetRequest, .resetConfirm:
            return "Recovery"
        }
    }

    private var primaryCardTitle: String {
        switch mode {
        case .signIn:
            return "Use your email"
        case .createAccount:
            return "Create your account"
        case .confirmAccount:
            return "Confirm your account"
        case .resetRequest:
            return "Request a reset code"
        case .resetConfirm:
            return "Choose a new password"
        }
    }

    private var primaryCardSummary: String {
        switch mode {
        case .signIn:
            return "Sign in returns to an existing account. Create account starts a new one."
        case .createAccount:
            return "Create account starts a new account. Confirmation can happen from this same auth surface."
        case .confirmAccount:
            return "Use the invited or registered email, then paste the confirmation code from your inbox."
        case .resetRequest:
            return "We will send a reset code to the email address tied to your account."
        case .resetConfirm:
            return "Paste the reset code and set the password you want to use from now on."
        }
    }

    @ViewBuilder
    private func modeButton(_ target: Mode, systemImage: String) -> some View {
        if target == mode {
            Button {
                mode = target
                errorMessage = nil
                infoMessage = nil
            } label: {
                Label {
                    Text(target.rawValue.appLocalized)
                } icon: {
                    Image(systemName: systemImage)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryCTAStyle())
        } else {
            Button {
                mode = target
                errorMessage = nil
                infoMessage = nil
            } label: {
                Label {
                    Text(target.rawValue.appLocalized)
                } icon: {
                    Image(systemName: systemImage)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryCTAStyle())
        }
    }

    @ViewBuilder
    private func inlineModeLink(_ title: String, target: Mode) -> some View {
        Button(title.appLocalized) {
            mode = target
            errorMessage = nil
            infoMessage = nil
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(BrandTheme.primary)
    }

    private var languagePicker: some View {
        Menu {
            Button("Auto") { language = "auto" }
            Button("English") { language = "en" }
            Button("Español") { language = "es" }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                Text(AppLocalization.menuLabel(for: language))
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(BrandTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(BrandTheme.surface, in: Capsule())
            .overlay(
                Capsule(style: .continuous)
                    .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: BrandTheme.shadow.opacity(0.08), radius: 10, x: 0, y: 6)
        }
    }

    @ViewBuilder
    private func authField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        contentType: UITextContentType,
        isSecure: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.appLocalized)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)

            Group {
                if isSecure {
                    SecureField(placeholder.appLocalized, text: text)
                } else {
                    TextField(placeholder.appLocalized, text: text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textContentType(contentType)
            .focused($focusedField, equals: field)
            .padding()
            .background(Color.black.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    @ViewBuilder
    private func routeRow(title: String, summary: String, systemImage: String) -> some View {
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

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(BrandTheme.muted)
                .padding(.top, 6)
        }
        .padding(14)
        .background(BrandTheme.surfaceTint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
        )
    }

    private func statusCard(title: String, message: String, systemImage: String) -> some View {
        SurfaceCard {
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
                    Text(message.appLocalized)
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".")
    }
}

private struct TagChip: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label {
            Text(text.appLocalized)
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(BrandTheme.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(BrandTheme.surfaceTint, in: Capsule())
        .overlay(
            Capsule(style: .continuous)
                .stroke(BrandTheme.line.opacity(0.85), lineWidth: 1)
        )
    }
}
