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
                    FeatureStubView(
                        title: "Profile",
                        summary: "Manage your personal details, household setup, and account status.",
                        readiness: "Available soon",
                        bullets: ["Identity", "Household state", "Access status"],
                        systemImage: "person.crop.circle.fill"
                    )
                }

                NavigationLink("Advanced settings") {
                    FeatureStubView(
                        title: "Advanced Settings",
                        summary: "Fine-tune diagnostics, exports, and advanced app controls.",
                        readiness: "Available soon",
                        bullets: ["Diagnostics", "Data export", "Developer toggles"],
                        systemImage: "switch.2"
                    )
                }

                Button("Sign out") {
                    viewModel.signOut()
                }
                .foregroundStyle(.red)
            }

            Section("Support") {
                NavigationLink("Help Center") {
                    FeatureStubView(
                        title: "Help Center",
                        summary: "Browse quick answers and practical guidance for common tasks.",
                        readiness: "Available soon",
                        bullets: ["FAQ", "Guided walkthroughs", "Feature explanations"],
                        systemImage: "questionmark.circle.fill"
                    )
                }

                NavigationLink("Support Center") {
                    FeatureStubView(
                        title: "Support Center",
                        summary: "Reach support, follow up on requests, and manage help tickets.",
                        readiness: "Available soon",
                        bullets: ["Ticket creation", "Status tracking", "Account deletion handoff"],
                        systemImage: "bubble.left.and.bubble.right.fill"
                    )
                }

                NavigationLink("Legal Center") {
                    FeatureStubView(
                        title: "Legal Center",
                        summary: "Review terms, privacy information, and support contact details.",
                        readiness: "Available soon",
                        bullets: ["Terms", "Privacy", "Support contact"],
                        systemImage: "doc.text.fill"
                    )
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(BrandTheme.canvas)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}
