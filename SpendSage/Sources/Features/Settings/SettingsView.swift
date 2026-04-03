import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel

    @AppStorage("native.settings.language") private var language = "en"
    @AppStorage("native.settings.currency") private var currency = "USD"
    @AppStorage("native.settings.theme") private var theme = "finance"
    @AppStorage("native.settings.reminders") private var remindersEnabled = true

    var body: some View {
        List {
            Section("Preferences") {
                Picker("Language", selection: $language) {
                    Text("English").tag("en")
                    Text("Español").tag("es")
                }

                Picker("Currency", selection: $currency) {
                    Text("USD").tag("USD")
                    Text("EUR").tag("EUR")
                    Text("GBP").tag("GBP")
                }

                Picker("Theme", selection: $theme) {
                    Text("Finance").tag("finance")
                    Text("Midnight").tag("midnight")
                    Text("Sunrise").tag("sunrise")
                }

                Toggle("Daily reminders", isOn: $remindersEnabled)
            }

            Section("Account and app") {
                NavigationLink("Profile") {
                    ProfileView(viewModel: viewModel)
                }

                NavigationLink("Advanced settings") {
                    AdvancedSettingsView(viewModel: viewModel)
                }

                Button("Sign out") {
                    viewModel.signOut()
                }
                .foregroundStyle(.red)
            }

            Section("Support") {
                NavigationLink("Help Center") {
                    HelpCenterView()
                }

                NavigationLink("Support Center") {
                    SupportCenterView(viewModel: viewModel)
                }

                NavigationLink("Legal Center") {
                    LegalCenterView()
                }

                NavigationLink("Brand Gallery") {
                    BrandGalleryView()
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(BrandTheme.canvas)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}
