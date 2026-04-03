import SwiftUI
import UIKit

struct ResetPasswordView: View {
    @AppStorage("native.settings.language") private var language = "auto"
    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var notice: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                recoveryCueCard
                requestCard
                passwordCard

                if let notice {
                    statusCard(message: notice)
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
        .navigationTitle("Reset Password")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .topLeading) {
            languagePicker
                .padding(.leading, 24)
                .padding(.top, 12)
        }
    }

    private var headerCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                BrandBadge(text: "Account recovery", systemImage: "key.fill")

                Text("Reset your password")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandTheme.ink)

                Text("Request a reset code for an existing account, then choose a new password to get back in.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    BrandMetricTile(title: "Step", value: "2-stage", systemImage: "number.circle.fill")
                    BrandMetricTile(title: "Recovery", value: "Secure", systemImage: "lock.rotation")
                }
            }
        }
    }

    private var recoveryCueCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recovery cue")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text("Use this when you already have an account but need a fresh code or a new password. If you were invited instead, use Confirm Account.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    BrandBadge(text: "Recovery", systemImage: "lifepreserver.fill")
                }

                HStack(spacing: 12) {
                    BrandMetricTile(title: "Code", value: "Email", systemImage: "envelope.fill")
                    BrandMetricTile(title: "Finish", value: "New password", systemImage: "key.fill")
                }
            }
        }
    }

    private var requestCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(number: "01", title: "Request a reset code", summary: "We will send a code to the email address tied to your account.")

                authField(title: "Email", placeholder: "name@domain.com", text: $email, contentType: .emailAddress)

                Button("Send reset code") {
                    notice = "A reset code request will be sent when the account recovery flow is connected.".appLocalized
                }
                .buttonStyle(SecondaryCTAStyle())
            }
        }
    }

    private var passwordCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(number: "02", title: "Choose a new password", summary: "Paste the code you received, then pick a password you will remember.")

                authField(title: "Confirmation code", placeholder: "6-digit code", text: $code, contentType: .oneTimeCode, keyboard: .numberPad)
                authField(title: "New password", placeholder: "At least 8 characters", text: $newPassword, contentType: .newPassword, secure: true)

                Button("Save new password") {
                    notice = "Your password reset is staged. Finish this step once account recovery is enabled.".appLocalized
                }
                .buttonStyle(PrimaryCTAStyle())
            }
        }
    }

    @ViewBuilder
    private func statusCard(message: String) -> some View {
        SurfaceCard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "bell.badge.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(BrandTheme.primary)
                    .frame(width: 42, height: 42)
                    .background(BrandTheme.accent.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Status")
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

    private func sectionHeader(number: String, title: String, summary: String) -> some View {
        HStack(alignment: .top) {
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

            Text(number)
                .font(.headline.weight(.bold))
                .foregroundStyle(BrandTheme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(BrandTheme.accent.opacity(0.18), in: Capsule())
        }
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
        contentType: UITextContentType,
        keyboard: UIKeyboardType = .default,
        secure: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.appLocalized)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)

            Group {
                if secure {
                    SecureField(placeholder.appLocalized, text: text)
                } else {
                    TextField(placeholder.appLocalized, text: text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textContentType(contentType)
            .keyboardType(keyboard)
            .padding()
            .background(Color.black.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
