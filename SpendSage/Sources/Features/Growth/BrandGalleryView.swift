import SwiftUI

private struct GallerySwatch: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
}

struct BrandGalleryView: View {
    @State private var selectedGuide: GuideDefinition?

    private let swatches: [GallerySwatch] = [
        GallerySwatch(name: "Background", color: BrandTheme.background),
        GallerySwatch(name: "Canvas", color: BrandTheme.canvas),
        GallerySwatch(name: "Primary", color: BrandTheme.primary),
        GallerySwatch(name: "Accent", color: BrandTheme.accent),
        GallerySwatch(name: "Ink", color: BrandTheme.ink),
        GallerySwatch(name: "Glow", color: BrandTheme.glow)
    ]

    private let catalog = BrandAssetCatalog.shared
    private var manifest: BrandAssetManifest { catalog.activeManifest }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Brand system",
                    title: "Brand Gallery",
                    summary: "A live gallery of the visual building blocks used across SpendSage: palette, mascots, guides, badges, and product storytelling surfaces. The manifest framing keeps the icon, expression, badge, and guide system easy to audit.",
                    systemImage: "swatchpalette.fill"
                )

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Manifest framing")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        BrandBadge(text: "Manifest \(manifest.version.rawValue.uppercased())", systemImage: "bookmark.fill")

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            BrandMetricTile(title: "Version", value: manifest.version.rawValue.uppercased(), systemImage: "bookmark.fill")
                            BrandMetricTile(title: "Characters", value: "\(manifest.characters.count)", systemImage: "person.3.fill")
                            BrandMetricTile(title: "Guides", value: "\(manifest.guides.count)", systemImage: "book.pages.fill")
                            BrandMetricTile(title: "Badges", value: "\(manifest.badges.count)", systemImage: "seal.fill")
                        }

                        BrandFeatureRow(
                            systemImage: "sparkles.rectangle.stack.fill",
                            title: "Guide-ready system",
                            detail: "Mascot expressions, badge art, and guide scenes all come from the same manifest, so the product language stays consistent."
                        )
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Brand pack")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        BrandArtworkSurface {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(alignment: .center, spacing: 14) {
                                    BrandAssetImage(source: catalog.logo(.mark), fallbackSystemImage: "seal.fill")
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 72, height: 72)

                                    BrandAssetImage(source: catalog.logo(.appIcon), fallbackSystemImage: "app.fill")
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 72, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                                    VStack(alignment: .leading, spacing: 10) {
                                        BrandAssetImage(source: catalog.logo(.wordmark), fallbackSystemImage: "textformat")
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 28)

                                        Text("The same bundled brand assets used across guides, badges, mascots, and product storytelling.")
                                            .font(.subheadline)
                                            .foregroundStyle(BrandTheme.muted)
                                    }
                                }

                                HStack(spacing: 12) {
                                    MascotAvatarView(character: .manchas, expression: .happy, size: 74)
                                    MascotAvatarView(character: .mei, expression: .thinking, size: 74)
                                    MascotAvatarView(character: .tikki, expression: .proud, size: 74)
                                }
                            }
                        }
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
                            detail: "Badges, trophies, mascots, and guide surfaces keep the experience lively without breaking the local-first tone."
                        )
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Guide previews")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text("Preview the interactive guides exactly as they appear across the app, with the same artwork, badge language, and pacing.")
                            .foregroundStyle(BrandTheme.muted)

                        ForEach(GuideID.allCases, id: \.self) { guideID in
                            let guide = GuideLibrary.guide(guideID)
                            Button {
                                selectedGuide = guide
                            } label: {
                                HStack(spacing: 14) {
                                    BrandAssetImage(
                                        source: BrandAssetCatalog.shared.guide(guide.slides.first?.imageKey ?? ""),
                                        fallbackSystemImage: "book.pages.fill"
                                    )
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(guide.title)
                                            .font(.headline)
                                            .foregroundStyle(BrandTheme.ink)
                                        Text(guide.slides.first?.title ?? "Open guide")
                                            .font(.subheadline)
                                            .foregroundStyle(BrandTheme.muted)
                                            .lineLimit(2)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(BrandTheme.primary)
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(BrandTheme.surfaceTint)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(BrandTheme.line.opacity(0.82), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Badges and accessories")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 12)], spacing: 12) {
                            ForEach(Array(catalog.allBadgeAssets().prefix(8)), id: \.id) { asset in
                                BrandArtworkSurface {
                                    BrandAssetImage(source: asset, fallbackSystemImage: "seal.fill")
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 54)
                                }
                            }

                            ForEach(Array(catalog.allAccessoryAssets().prefix(6)), id: \.id) { asset in
                                BrandArtworkSurface {
                                    BrandAssetImage(source: asset, fallbackSystemImage: "wand.and.stars")
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 54)
                                }
                            }
                        }
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
                        Label("Manifest: icons, expressions, badges, and guide assets stay easy to audit.", systemImage: "doc.text.magnifyingglass")
                    }
                    .foregroundStyle(BrandTheme.ink)
                }
            }
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .overlay(alignment: .top) {
            BrandBackdropView()
        }
        .navigationTitle("Brand Gallery")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedGuide) { guide in
            GuideSheet(guide: guide)
        }
    }
}
