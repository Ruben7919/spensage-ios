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
                        summary: "Native replacement for `/app/profile`.",
                        readiness: "Phase 3",
                        bullets: ["Identity", "Household state", "Access status"],
                        systemImage: "person.crop.circle.fill"
                    )
                }

                NavigationLink("Advanced settings") {
                    FeatureStubView(
                        title: "Advanced Settings",
                        summary: "Native replacement for `/app/settings/advanced`.",
                        readiness: "Phase 4",
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
                        summary: "Native replacement for `/app/help`.",
                        readiness: "Phase 3",
                        bullets: ["FAQ", "Guided walkthroughs", "Feature explanations"],
                        systemImage: "questionmark.circle.fill"
                    )
                }

                NavigationLink("Support Center") {
                    FeatureStubView(
                        title: "Support Center",
                        summary: "Native replacement for `/app/support`.",
                        readiness: "Phase 3",
                        bullets: ["Ticket creation", "Status tracking", "Account deletion handoff"],
                        systemImage: "bubble.left.and.bubble.right.fill"
                    )
                }

                NavigationLink("Legal Center") {
                    FeatureStubView(
                        title: "Legal Center",
                        summary: "Native replacement for `/app/legal`.",
                        readiness: "Phase 3",
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
