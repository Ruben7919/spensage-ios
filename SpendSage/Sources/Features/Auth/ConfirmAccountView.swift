import SwiftUI
import UIKit

struct ConfirmAccountView: View {
    @AppStorage("native.settings.language") private var language = "auto"
    @State private var email = ""
    @State private var code = ""
    @State private var notice: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                inviteCueCard
                verificationCard
                actionCard

                if let notice {
                    statusCard(message: notice)
                }
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(
            ZStack {
                BrandTheme.canvas
                BrandBackdropView()
            }
            .ignoresSafeArea()
        )
        .navigationTitle("Confirm account".appLocalized)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .topLeading) {
            languagePicker
                .padding(.leading, 24)
                .padding(.top, 12)
        }
    }

    private var headerCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    MascotAvatarView(character: .mei, expression: .proud, size: 76)

                    VStack(alignment: .leading, spacing: 10) {
                        BrandBadge(text: "Security checkpoint", systemImage: "checkmark.shield.fill")

                        Text("Confirm account".appLocalized)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)

                        Text("Use the email that received the code, paste it here, and finish setup without leaving the same auth surface.".appLocalized)
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 12) {
                    BrandMetricTile(title: "Step", value: "2 of 2".appLocalized, systemImage: "number.circle.fill")
                    BrandMetricTile(title: "Delivery", value: "Email code".appLocalized, systemImage: "envelope.fill")
                }
            }
        }
    }

    private var inviteCueCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Invite or confirmation")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text("If you were invited, use the invited email. If this is a regular signup, use the email you just registered.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    BrandBadge(text: "Pending", systemImage: "person.badge.plus")
                }

                HStack(spacing: 12) {
                    BrandMetricTile(title: "Cue", value: "Invite", systemImage: "envelope.badge.fill")
                    BrandMetricTile(title: "Next", value: "Paste code", systemImage: "checkmark.seal.fill")
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
                    notice = "Confirmation is ready. This step completes invite or signup verification and returns you to sign in.".appLocalized
                }
                .buttonStyle(PrimaryCTAStyle())

                Button("Resend code") {
                    notice = "A new confirmation code will be sent to your email when the account service is available.".appLocalized
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
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.appLocalized)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)

            TextField(placeholder.appLocalized, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(contentType)
                .keyboardType(keyboard)
                .padding()
                .background(BrandTheme.surfaceTint)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
                )
        }
    }
}
