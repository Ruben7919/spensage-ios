import SwiftUI
import UIKit

struct ConfirmAccountView: View {
    @State private var email = ""
    @State private var code = ""
    @State private var notice: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                verificationCard
                actionCard

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
        .navigationTitle("Confirm Account")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                BrandBadge(text: "Security checkpoint", systemImage: "checkmark.shield.fill")

                Text("Confirm your account")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandTheme.ink)

                Text("Enter the email used for signup and the code from your inbox to finish setup.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    BrandMetricTile(title: "Step", value: "2 of 2", systemImage: "number.circle.fill")
                    BrandMetricTile(title: "Delivery", value: "Email code", systemImage: "envelope.fill")
                }
            }
        }
    }

    private var verificationCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(number: "01", title: "Verification details", summary: "Use the same email address you entered when creating the account.")

                authField(title: "Email", placeholder: "name@domain.com", text: $email, contentType: .emailAddress)
                authField(title: "Confirmation code", placeholder: "6-digit code", text: $code, contentType: .oneTimeCode, keyboard: .numberPad)
            }
        }
    }

    private var actionCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(number: "02", title: "Finish setup", summary: "Once the code is accepted, you can return to sign in and continue with your account.")

                Button("Confirm account") {
                    notice = "Confirmation is ready. When the account service is connected, this step will complete verification and return you to sign in."
                }
                .buttonStyle(PrimaryCTAStyle())

                Button("Resend code") {
                    notice = "A new confirmation code will be sent to your email when the account service is available."
                }
                .buttonStyle(SecondaryCTAStyle())
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
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)

            TextField(placeholder, text: text)
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
