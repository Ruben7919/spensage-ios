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
                        Text("Upgrade for an ad-free experience and more advanced planning tools.")
                            .foregroundStyle(BrandTheme.muted)

                        BrandBadge(text: viewModel.session.isAuthenticated ? "Signed in" : "On this device", systemImage: "star.fill")

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Remove ads on dashboard and expenses", systemImage: "checkmark.circle.fill")
                            Label("Unlock insights, bills, accounts, and rules", systemImage: "checkmark.circle.fill")
                            Label("Keep your access in sync across devices", systemImage: "checkmark.circle.fill")
                        }
                        .foregroundStyle(BrandTheme.ink)
                        .font(.subheadline)

                        Button("Explore premium options") {}
                            .buttonStyle(PrimaryCTAStyle())
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Growth surfaces")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        NavigationLink("Trophy History") {
                            TrophyHistoryView(viewModel: viewModel)
                        }

                        NavigationLink("Brand Gallery") {
                            BrandGalleryView()
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
