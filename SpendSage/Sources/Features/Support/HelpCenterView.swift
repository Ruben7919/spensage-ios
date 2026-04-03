import SwiftUI

private struct HelpTopic: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let systemImage: String
}

struct HelpCenterView: View {
    private let topics: [HelpTopic] = [
        HelpTopic(
            title: "Guest mode stays local",
            detail: "Continue as guest to keep your ledger on this iPhone without needing backend auth or sync.",
            systemImage: "iphone.gen3"
        ),
        HelpTopic(
            title: "Add expenses fast",
            detail: "Use Dashboard or Expenses to save merchants, categories, notes, and amounts directly into the local ledger.",
            systemImage: "plus.circle.fill"
        ),
        HelpTopic(
            title: "Budget wizard",
            detail: "Define monthly income and budget to unlock the dashboard remaining-safe-budget summary.",
            systemImage: "wand.and.stars"
        ),
        HelpTopic(
            title: "Rules improve categorization",
            detail: "Merchant keyword rules are used locally to infer better categories for new expenses.",
            systemImage: "line.3.horizontal.decrease.circle.fill"
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Help Center")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)
                        Text("Practical guidance for budgeting, expense tracking, and keeping your money plan organized on this device.")
                            .foregroundStyle(BrandTheme.muted)
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick answers")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        ForEach(topics) { topic in
                            BrandFeatureRow(systemImage: topic.systemImage, title: topic.title, detail: topic.detail)
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommended flow")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Label("Start in guest mode or sign in.", systemImage: "1.circle.fill")
                        Label("Set your budget and add your first expense.", systemImage: "2.circle.fill")
                        Label("Create bills, accounts, and rules from Insights.", systemImage: "3.circle.fill")
                        Label("Use Support Center to export a local support packet if you get stuck.", systemImage: "4.circle.fill")
                    }
                    .foregroundStyle(BrandTheme.ink)
                }
            }
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.inline)
    }
}
