import SwiftUI
import UIKit

struct AuthView: View {
    @ObservedObject var viewModel: AppViewModel

    enum Mode: String, CaseIterable, Identifiable {
        case signIn = "Sign in"
        case createAccount = "Create account"

        var id: String { rawValue }
    }

    enum Field: Hashable {
        case email
        case password
        case confirmPassword
    }

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                emailCard
                socialCard
                helpCard

                if viewModel.authConfiguration.allowsGuestAccess {
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
        .navigationTitle("Sign in")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                BrandBadge(
                    text: viewModel.authConfiguration.isHostedUIReady ? "Secure account start" : "Local-first start",
                    systemImage: "lock.fill"
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Choose how you want to begin")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandTheme.ink)

                    Text(viewModel.authConfiguration.isHostedUIReady
                         ? "Use email, Apple, or Google to keep your access portable. You can still keep the app local until you are ready to sync."
                         : viewModel.authConfiguration.localPreviewFootnote)
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 12) {
                    BrandMetricTile(
                        title: "Mode",
                        value: viewModel.authConfiguration.isHostedUIReady ? "Account + local" : "Local first",
                        systemImage: "person.crop.circle"
                    )
                    BrandMetricTile(
                        title: "Recovery",
                        value: "Confirm / reset",
                        systemImage: "lifepreserver.fill"
                    )
                }

                HStack(spacing: 8) {
                    TagChip(text: "Guest available", systemImage: "iphone.gen3")
                    TagChip(text: "Apple & Google", systemImage: "person.crop.circle.badge.checkmark")
                    TagChip(text: "Sync later", systemImage: "arrow.triangle.2.circlepath")
                }
            }
        }
    }

    private var emailCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode == .signIn ? "Use your email" : "Create your account")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text(viewModel.authConfiguration.isHostedUIReady
                             ? "We will finish in a secure browser session after this screen."
                             : "Keep this flow simple. You can stay local today and add cloud access later.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Text("01")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(BrandTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(BrandTheme.accent.opacity(0.18), in: Capsule())
                }

                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                authField(
                    title: "Email",
                    placeholder: "name@domain.com",
                    text: $email,
                    field: .email,
                    contentType: .emailAddress,
                    isSecure: false
                )

                authField(
                    title: viewModel.authConfiguration.isHostedUIReady ? "Password" : "Password",
                    placeholder: viewModel.authConfiguration.isHostedUIReady
                        ? "Optional for browser sign in"
                        : "Minimum 8 characters",
                    text: $password,
                    field: .password,
                    contentType: .password,
                    isSecure: true
                )

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

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color(red: 0.72, green: 0.24, blue: 0.20))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button(submitLabel) {
                    Task { await submitEmailForm() }
                }
                .buttonStyle(PrimaryCTAStyle())
                .disabled(isLoading || !canSubmit)

                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Working on it…")
                            .font(.footnote)
                            .foregroundStyle(BrandTheme.muted)
                    }
                } else if let hint = validationHint {
                    Text(hint)
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }
            }
        }
    }

    private var socialCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Continue with Apple or Google")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text(viewModel.authConfiguration.hostedUIFootnote)
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
                        Text("Use the account recovery tools if you need a verification code or a fresh password.")
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

                VStack(spacing: 10) {
                    NavigationLink {
                        ConfirmAccountView()
                    } label: {
                        routeRow(
                            title: "Confirm account",
                            summary: "Paste the code from your email and finish setup.",
                            systemImage: "checkmark.seal.fill"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ResetPasswordView()
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
        switch (viewModel.authConfiguration.isHostedUIReady, mode) {
        case (true, .signIn):
            return "Continue"
        case (true, .createAccount):
            return "Create account"
        case (false, .signIn):
            return "Sign in"
        case (false, .createAccount):
            return "Create account"
        }
    }

    private var canSubmit: Bool {
        if viewModel.authConfiguration.isHostedUIReady {
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
        }
    }

    private var validationHint: String? {
        if viewModel.authConfiguration.isHostedUIReady {
            return "You will finish this step in a secure browser session."
        }
        if !isValidEmail(email) {
            return "Use a valid email address."
        }
        if password.count < viewModel.authConfiguration.minimumPasswordLength {
            return "Password must be at least \(viewModel.authConfiguration.minimumPasswordLength) characters."
        }
        if mode == .createAccount && password != confirmPassword {
            return "Passwords must match."
        }
        return nil
    }

    private func supportsProvider(_ provider: SocialProvider) -> Bool {
        viewModel.authConfiguration.supportedSocialProviders.contains(provider)
    }

    private func submitEmailForm() async {
        guard canSubmit else {
            errorMessage = validationHint ?? "Check the form fields."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            switch mode {
            case .signIn:
                try await viewModel.signIn(email: email, password: password)
            case .createAccount:
                try await viewModel.createAccount(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func submitSocial(_ provider: SocialProvider) async {
        guard supportsProvider(provider) else {
            errorMessage = "\(provider.rawValue) sign-in is not available yet."
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
        defer { isLoading = false }
        await viewModel.continueAsGuest()
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
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)

            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
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
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Text(message)
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
            Text(text)
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
