import SwiftUI
import UIKit

struct ResetPasswordView: View {
    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var notice: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
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
    }

    private var headerCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                BrandBadge(text: "Account recovery", systemImage: "key.fill")

                Text("Reset your password")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandTheme.ink)

                Text("Request a code, then choose a new password to get back into your account.")
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

    private var requestCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(number: "01", title: "Request a reset code", summary: "We will send a code to the email address tied to your account.")

                authField(title: "Email", placeholder: "name@domain.com", text: $email, contentType: .emailAddress)

                Button("Send reset code") {
                    notice = "A reset code request will be sent when the account recovery flow is connected."
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
                    notice = "Your password reset is staged. Finish this step once account recovery is enabled."
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
                    Text(message)
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
                Text(title)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text(summary)
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
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)

            Group {
                if secure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
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
