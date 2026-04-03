import SwiftUI

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
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Welcome to SpendSage")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandTheme.ink)

                Text(viewModel.authConfiguration.localPreviewFootnote)
                    .font(.body)
                    .foregroundStyle(BrandTheme.muted)

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
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
                            isSecure: false
                        )

                        authField(
                            title: "Password",
                            placeholder: "Minimum 8 characters",
                            text: $password,
                            field: .password,
                            isSecure: true
                        )

                        if mode == .createAccount {
                            authField(
                                title: "Confirm password",
                                placeholder: "Re-enter password",
                                text: $confirmPassword,
                                field: .confirmPassword,
                                isSecure: true
                            )
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Button(mode == .signIn ? "Sign in" : "Create account") {
                            Task { await submitEmailForm() }
                        }
                        .buttonStyle(PrimaryCTAStyle())
                        .disabled(isLoading || !canSubmit)

                        if isLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Signing you in...")
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

                VStack(alignment: .leading, spacing: 12) {
                    Text("Continue with Apple or Google")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)

                    HStack(spacing: 12) {
                        Button("Google") {
                            Task { await submitSocial(.google) }
                        }
                        .buttonStyle(SecondaryCTAStyle())
                        .disabled(isLoading || !supportsProvider(.google))

                        Button("Apple") {
                            Task { await submitSocial(.apple) }
                        }
                        .buttonStyle(SecondaryCTAStyle())
                        .disabled(isLoading || !supportsProvider(.apple))
                    }

                    Text(viewModel.authConfiguration.hostedUIFootnote)
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Account help")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        NavigationLink("Confirm account") {
                            ConfirmAccountView()
                        }

                        NavigationLink("Reset password") {
                            ResetPasswordView()
                        }
                    }
                }

                if viewModel.authConfiguration.allowsGuestAccess {
                    Button("Continue on this device") {
                        Task { await continueAsGuest() }
                    }
                    .buttonStyle(PrimaryCTAStyle())
                    .disabled(isLoading)
                }

                if let notice = viewModel.notice {
                    Text(notice)
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                        .padding(.top, 8)
                }
            }
            .padding(24)
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
            return "You will finish this step securely in the browser."
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
            .textContentType(field == .email ? .emailAddress : .password)
            .focused($focusedField, equals: field)
            .padding()
            .background(Color.black.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".")
    }
}
