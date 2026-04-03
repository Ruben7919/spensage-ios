import SwiftUI

struct PremiumView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Premium")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)
                        Text("This tab mirrors `/app/premium` from the hybrid app. RevenueCat and AdMob are still phase-3 integrations in the native repo, but the surface is now in place.")
                            .foregroundStyle(BrandTheme.muted)

                        BrandBadge(text: viewModel.session.isAuthenticated ? "Signed-in preview" : "Guest preview", systemImage: "star.fill")

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Remove ads on dashboard and expenses", systemImage: "checkmark.circle.fill")
                            Label("Unlock insights, bills, accounts, and rules", systemImage: "checkmark.circle.fill")
                            Label("Keep parity with RevenueCat + Cognito entitlements", systemImage: "checkmark.circle.fill")
                        }
                        .foregroundStyle(BrandTheme.ink)
                        .font(.subheadline)

                        Button("Open customer center later") {}
                            .buttonStyle(PrimaryCTAStyle())
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Growth surfaces")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        NavigationLink("Trophies") {
                            FeatureStubView(
                                title: "Trophies",
                                summary: "Native replacement for `/app/trophies`.",
                                readiness: "Phase 4",
                                bullets: ["Milestones", "Review loops", "Habit streaks"],
                                systemImage: "trophy.fill"
                            )
                        }

                        NavigationLink("Brand Gallery") {
                            FeatureStubView(
                                title: "Brand Gallery",
                                summary: "Native replacement for `/app/brand-gallery`.",
                                readiness: "Phase 4",
                                bullets: ["Mascot assets", "Theme gallery", "Onboarding scenes"],
                                systemImage: "photo.stack.fill"
                            )
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.large)
    }
}
