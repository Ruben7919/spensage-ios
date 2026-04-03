import SwiftUI

private struct GallerySwatch: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
}

struct BrandGalleryView: View {
    private let swatches: [GallerySwatch] = [
        GallerySwatch(name: "Background", color: BrandTheme.background),
        GallerySwatch(name: "Canvas", color: BrandTheme.canvas),
        GallerySwatch(name: "Primary", color: BrandTheme.primary),
        GallerySwatch(name: "Accent", color: BrandTheme.accent),
        GallerySwatch(name: "Ink", color: BrandTheme.ink),
        GallerySwatch(name: "Glow", color: BrandTheme.glow)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Brand Gallery")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)

                        Text("A live gallery of the visual building blocks used across SpendSage: palette, badges, metrics, and product storytelling surfaces.")
                            .foregroundStyle(BrandTheme.muted)
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Color system")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            ForEach(swatches) { swatch in
                                VStack(alignment: .leading, spacing: 10) {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(swatch.color)
                                        .frame(height: 92)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
                                        )
                                    Text(swatch.name)
                                        .font(.headline)
                                        .foregroundStyle(BrandTheme.ink)
                                }
                            }
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Core components")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        HStack {
                            BrandBadge(text: "Guest local mode", systemImage: "iphone.gen3")
                            Spacer()
                            BrandBadge(text: "Premium growth", systemImage: "sparkles")
                        }

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            BrandMetricTile(title: "Monthly budget", value: "$2,400", systemImage: "banknote.fill")
                            BrandMetricTile(title: "Remaining", value: "$1,128", systemImage: "leaf.fill")
                        }

                        BrandFeatureRow(
                            systemImage: "sun.max.fill",
                            title: "Finance calm",
                            detail: "Soft canvas, rounded surfaces, and precise contrast keep the app approachable for daily check-ins."
                        )
                        BrandFeatureRow(
                            systemImage: "sparkles.rectangle.stack.fill",
                            title: "Growth energy",
                            detail: "Badges, trophies, and gallery surfaces push premium and retention loops without breaking the local-first tone."
                        )
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Scene directions")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Label("Dashboard: calm overview with actionable budget framing.", systemImage: "house.fill")
                        Label("Support: trusted, practical, and clipboard-friendly.", systemImage: "lifepreserver.fill")
                        Label("Premium: celebratory growth layer on top of grounded finance basics.", systemImage: "trophy.fill")
                    }
                    .foregroundStyle(BrandTheme.ink)
                }
            }
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .navigationTitle("Brand Gallery")
        .navigationBarTitleDisplayMode(.inline)
    }
}
