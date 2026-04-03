import SwiftUI

struct ResetPasswordView: View {
    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var notice: String?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Reset your password")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(BrandTheme.ink)
                    Text("Request a code, then choose a new password to restore access to your account.")
                        .foregroundStyle(BrandTheme.muted)
                }
                .padding(.vertical, 6)
                .listRowBackground(Color.clear)
            }

            Section("Reset request") {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.emailAddress)

                Button("Send reset code") {
                    notice = "A reset code request will be sent when your account recovery flow is connected."
                }
                .foregroundStyle(BrandTheme.primary)
            }

            Section("Choose a new password") {
                TextField("Confirmation code", text: $code)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("New password", text: $newPassword)
                    .textContentType(.newPassword)

                Button("Save new password") {
                    notice = "Your password reset request is ready. Finish this step after account recovery is connected."
                }
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
        .navigationTitle("Reset Password")
        .navigationBarTitleDisplayMode(.inline)
    }
}
