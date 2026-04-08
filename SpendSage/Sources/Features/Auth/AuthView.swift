import SwiftUI
import UIKit

struct AuthView: View {
    @ObservedObject var viewModel: AppViewModel
    @AppStorage("native.settings.language") private var language = "auto"

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
        case code
        case newPassword
    }

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var infoMessage: String?
    @FocusState private var focusedField: Field?

    private var authStory: BrandNarrativeSpec {
        BrandStoryCatalog.spec(for: .auth)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    languagePicker
                }

                if viewModel.pendingInviteCode != nil {
                    invitePendingCard
                }

                authCard

                if let notice = viewModel.notice {
                    statusCard(title: "Status", message: notice, systemImage: "checkmark.seal.fill")
                }
            }
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(
            ZStack {
                BrandTheme.canvas
                BrandBackdropView()
            }
            .ignoresSafeArea()
        )
        .toolbar(.hidden, for: .navigationBar)
    }

    private var authCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                header

                authTrustStrip

                authField(
                    title: "Email",
                    placeholder: "name@domain.com",
                    text: $email,
                    field: .email,
                    contentType: .emailAddress,
                    isSecure: false
                )

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

                if let errorMessage {
                    statusBanner(
                        title: "Status",
                        message: errorMessage,
                        systemImage: "exclamationmark.triangle.fill",
                        tint: .red
                    )
                }

                if let infoMessage {
                    statusBanner(
                        title: "Status",
                        message: infoMessage,
                        systemImage: "checkmark.seal.fill",
                        tint: BrandTheme.primary
                    )
                }

                Button(submitLabel.appLocalized) {
                    Task { await submitEmailForm() }
                }
                .buttonStyle(PrimaryCTAStyle())
                .disabled(isLoading || !canSubmit)

                if mode == .confirmAccount {
                    Button("Resend code".appLocalized) {
                        infoMessage = "A new confirmation code will be sent when the account service is connected.".appLocalized
                        errorMessage = nil
                    }
                    .buttonStyle(SecondaryCTAStyle())
                }

                if mode == .signIn || mode == .createAccount {
                    dividerLabel("Or continue with")

                    VStack(spacing: 12) {
                        socialButton(provider: .apple, title: "Continue with Apple", systemImage: "applelogo")
                        socialButton(provider: .google, title: "Continue with Google", systemImage: "g.circle.fill")
                    }

                    Text(
                        viewModel.authConfiguration.isHostedUIReady
                            ? "Apple and Google open the secure cloud login and bring you back into the app."
                            : "Apple and Google will activate as soon as the account provider is connected."
                    )
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
                }

                if isLoading {
                    HStack(spacing: 10) {
                        YarnLoadingIndicator(size: 18)
                        Text("Working on it…")
                            .font(.footnote)
                            .foregroundStyle(BrandTheme.muted)
                    }
                } else if let hint = validationHint {
                    Text(hint.appLocalized)
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }

                footerLinks
            }
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(BrandTheme.heroGlowGradient)
                    .frame(width: 116, height: 116)
                    .blur(radius: 10)

                MascotAvatarView(character: authStory.character, expression: authStory.expression, size: 92)
            }

            VStack(alignment: .center, spacing: 10) {
                BrandBadge(
                    text: mode == .signIn ? "Cuenta segura" : "Inicio simple",
                    systemImage: "sparkles"
                )

                Text("SpendSage")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BrandTheme.primary)
                    .textCase(.uppercase)

                Text(modeTitle.appLocalized)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(BrandTheme.ink)
                    .multilineTextAlignment(.center)

                Text(modeSubtitle.appLocalized)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var authTrustStrip: some View {
        FlowStack(spacing: 10, rowSpacing: 10) {
            StoryTag(text: "Cloud login", systemImage: "lock.shield")
            StoryTag(text: "Apple y Google", systemImage: "person.crop.circle.badge.checkmark")
            StoryTag(text: "Vuelve a tu plan", systemImage: "arrow.clockwise")
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var invitePendingCard: some View {
        SurfaceCard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "person.badge.clock.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(BrandTheme.primary)
                    .frame(width: 42, height: 42)
                    .background(BrandTheme.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Invite pending")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Text("Use the invited email and confirm the code from your inbox.")
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var footerLinks: some View {
        FlowStack(spacing: 14, rowSpacing: 10) {
            switch mode {
            case .signIn:
                inlineModeLink("Create account", target: .createAccount)
                inlineModeLink("Forgot password?", target: .resetRequest)

            case .createAccount:
                inlineModeLink("Back to sign in", target: .signIn)
                inlineModeLink("Confirm account", target: .confirmAccount)

            case .confirmAccount:
                inlineModeLink("Back to sign in", target: .signIn)
                inlineModeLink("Forgot password?", target: .resetRequest)

            case .resetRequest:
                inlineModeLink("Back to sign in", target: .signIn)
                inlineModeLink("Confirm account", target: .confirmAccount)

            case .resetConfirm:
                inlineModeLink("Back to sign in", target: .signIn)
                inlineModeLink("Request another code", target: .resetRequest)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func socialButton(provider: SocialProvider, title: String, systemImage: String) -> some View {
        Button {
            Task { await submitSocial(provider) }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(BrandTheme.surface)
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(BrandTheme.ink)
                }
                .frame(width: 28, height: 28)

                Text(title.appLocalized)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 4)
        }
        .buttonStyle(SecondaryCTAStyle())
        .disabled(isLoading || !supportsProvider(provider))
    }

    private func dividerLabel(_ title: String) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(BrandTheme.line.opacity(0.8))
                .frame(height: 1)

            Text(title.appLocalized)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)

            Rectangle()
                .fill(BrandTheme.line.opacity(0.8))
                .frame(height: 1)
        }
    }

    private var submitLabel: String {
        switch mode {
        case .signIn:
            return "Continue"
        case .createAccount:
            return "Create account"
        case .confirmAccount:
            return "Confirm"
        case .resetRequest:
            return "Send code"
        case .resetConfirm:
            return "Save password"
        }
    }

    private var canSubmit: Bool {
        switch mode {
        case .signIn, .createAccount, .resetRequest:
            return isValidEmail(email)
        case .confirmAccount:
            return isValidEmail(email) && !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .resetConfirm:
            return isValidEmail(email)
                && !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && newPassword.count >= viewModel.authConfiguration.minimumPasswordLength
        }
    }

    private var validationHint: String? {
        if !isValidEmail(email) {
            return "Use a valid email address."
        }
        switch mode {
        case .signIn, .createAccount:
            return "You will finish this step in a secure browser session."
        case .confirmAccount:
            return code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "Paste the confirmation code from your inbox."
                : nil
        case .resetRequest:
            return nil
        case .resetConfirm:
            if code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "Paste the reset code from your inbox."
            }
            if newPassword.count < viewModel.authConfiguration.minimumPasswordLength {
                return AppLocalization.localized(
                    "Password must be at least %d characters.",
                    arguments: viewModel.authConfiguration.minimumPasswordLength
                )
            }
            return nil
        }
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
                try await viewModel.signIn(email: email, password: "")
            case .createAccount:
                try await viewModel.createAccount(email: email, password: "")
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

    private var modeTitle: String {
        switch mode {
        case .signIn:
            return "Sign in"
        case .createAccount:
            return "Create your account"
        case .confirmAccount:
            return "Confirm your email"
        case .resetRequest:
            return "Reset your password"
        case .resetConfirm:
            return "Choose a new password"
        }
    }

    private var modeSubtitle: String {
        switch mode {
        case .signIn:
            return "Keep your plan, progress, and history synced with one account."
        case .createAccount:
            return "Start with your email and finish in one secure step."
        case .confirmAccount:
            return "Paste the code from your inbox and finish setup."
        case .resetRequest:
            return "Request a code and keep recovery simple."
        case .resetConfirm:
            return "Choose a new password and return to sign in."
        }
    }

    @ViewBuilder
    private func inlineModeLink(_ title: String, target: Mode) -> some View {
        Button(title.appLocalized) {
            mode = target
            errorMessage = nil
            infoMessage = nil
            if target != .resetConfirm {
                code = ""
            }
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(BrandTheme.primary)
    }

    private var languagePicker: some View {
        Menu {
            Button("Auto".appLocalized) { language = "auto" }
            Button("English".appLocalized) { language = "en" }
            Button("Español".appLocalized) { language = "es" }
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
            .background(BrandTheme.surfaceTint)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
            )
        }
    }

    private func statusBanner(title: String, message: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title.appLocalized)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(BrandTheme.ink)
                Text(message.appLocalized)
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(BrandTheme.surfaceTint)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func statusCard(title: String, message: String, systemImage: String) -> some View {
        statusBanner(title: title, message: message, systemImage: systemImage, tint: BrandTheme.primary)
    }

    private func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".")
    }
}
