import SwiftUI

struct ConfirmAccountView: View {
    @State private var email = ""
    @State private var code = ""
    @State private var notice: String?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Confirm your account")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(BrandTheme.ink)
                    Text("Enter the verification code from your email to finish setting up your account.")
                        .foregroundStyle(BrandTheme.muted)
                }
                .padding(.vertical, 6)
                .listRowBackground(Color.clear)
            }

            Section("Verification") {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.emailAddress)

                TextField("Confirmation code", text: $code)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section {
                Button("Confirm account") {
                    notice = "Your account confirmation request is ready. If this account exists, you can continue signing in after verification."
                }

                Button("Resend code") {
                    notice = "A new confirmation code will be sent to your email when account verification is connected."
                }
                .foregroundStyle(BrandTheme.primary)
            }

            if let notice {
                Section("Status") {
                    Text(notice)
                        .foregroundStyle(BrandTheme.muted)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(BrandTheme.canvas)
        .navigationTitle("Confirm Account")
        .navigationBarTitleDisplayMode(.inline)
    }
}
