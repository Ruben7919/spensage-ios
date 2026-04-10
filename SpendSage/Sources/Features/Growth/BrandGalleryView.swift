import SwiftUI

private struct GallerySwatch: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
}

struct BrandGalleryView: View {
    @State private var selectedGuide: GuideDefinition?

    private let swatches: [GallerySwatch] = [
        GallerySwatch(name: "Fondo", color: BrandTheme.background),
        GallerySwatch(name: "Canvas", color: BrandTheme.canvas),
        GallerySwatch(name: "Primario", color: BrandTheme.primary),
        GallerySwatch(name: "Acento", color: BrandTheme.accent),
        GallerySwatch(name: "Ink", color: BrandTheme.ink),
        GallerySwatch(name: "Glow", color: BrandTheme.glow)
    ]

    private let catalog = BrandAssetCatalog.shared
    private var manifest: BrandAssetManifest { catalog.activeManifest }
    private var activeSeason: BrandSeasonDefinition? { BrandSeasonCatalog.activeSeason() }
    private var nextSeason: (season: BrandSeasonDefinition, startDate: Date)? { BrandSeasonCatalog.nextSeason() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Sistema de marca",
                    title: "Galería de marca",
                    summary: "Una vista interna de paleta, mascotas, guías, badges e iconos para auditar que el lenguaje visual de MichiFinanzas siga consistente.",
                    systemImage: "swatchpalette.fill",
                    character: .tikki,
                    expression: .proud,
                    sceneKey: "guide_17_landing_hero_team"
                )

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Manifiesto visual")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        BrandBadge(text: "Manifest \(manifest.version.rawValue.uppercased())", systemImage: "bookmark.fill")

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            BrandMetricTile(title: "Versión", value: manifest.version.rawValue.uppercased(), systemImage: "bookmark.fill")
                            BrandMetricTile(title: "Personajes", value: "\(manifest.characters.count)", systemImage: "person.3.fill")
                            BrandMetricTile(title: "Guías", value: "\(manifest.guides.count)", systemImage: "book.pages.fill")
                            BrandMetricTile(title: "Badges", value: "\(manifest.badges.count)", systemImage: "seal.fill")
                        }

                        BrandFeatureRow(
                            systemImage: "sparkles.rectangle.stack.fill",
                            title: "Sistema auditable",
                            detail: "Expresiones, badges y escenas salen del mismo manifiesto para que el icono y los personajes se mantengan coherentes."
                        )
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Temporadas")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text("Los cambios visuales por temporada salen de un catálogo pequeño y mantenible, no de condiciones sueltas.")
                            .foregroundStyle(BrandTheme.muted)

                        ForEach(BrandSeasonCatalog.seasons, id: \.id) { season in
                            HStack(alignment: .top, spacing: 14) {
                                BrandAssetImage(
                                    source: seasonalPreviewSource(for: season),
                                    fallbackSystemImage: "sparkles"
                                )
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 92, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text(season.title.appLocalized)
                                            .font(.headline)
                                            .foregroundStyle(BrandTheme.ink)

                                        if activeSeason?.id == season.id {
                                            BrandBadge(text: "Activa".appLocalized, systemImage: "sparkles")
                                        } else if nextSeason?.season.id == season.id {
                                            BrandBadge(text: "Siguiente".appLocalized, systemImage: "calendar")
                                        }
                                    }

                                    Text(season.summary.appLocalized)
                                        .font(.subheadline)
                                        .foregroundStyle(BrandTheme.muted)
                                        .fixedSize(horizontal: false, vertical: true)

                                    HStack(spacing: 8) {
                                        BrandAssetImage(
                                            source: catalog.badge(named: season.badgeAsset),
                                            fallbackSystemImage: "seal.fill"
                                        )
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 28, height: 28)

                                        Text(seasonDateLabel(for: season))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(BrandTheme.primary)
                                    }

                                    let characterPreviews = seasonCharacterPreviewSources(for: season)
                                    if !characterPreviews.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Mascotas del evento")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(BrandTheme.muted)

                                            HStack(spacing: 8) {
                                                ForEach(Array(characterPreviews.enumerated()), id: \.offset) { _, source in
                                                    BrandAssetImage(
                                                        source: source,
                                                        fallbackSystemImage: "sparkles"
                                                    )
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 64, height: 50)
                                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                            .stroke(BrandTheme.line.opacity(0.82), lineWidth: 1)
                                                    )
                                                }
                                            }
                                        }
                                    }
                                }

                                Spacer()
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
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Pack principal")
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

                                        Text("Los mismos assets de marca que usa la app para guías, badges, personajes y escenas.")
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
                        Text("Sistema de color")
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
                                    Text(swatch.name.appLocalized)
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
                            BrandBadge(text: "Account-first", systemImage: "person.crop.circle")
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
                            detail: "Badges, trophies, mascots, and guide surfaces keep the experience lively without breaking the clear account-first product tone."
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
                                        Text(guide.title.appLocalized)
                                            .font(.headline)
                                            .foregroundStyle(BrandTheme.ink)
                                        Text((guide.slides.first?.title ?? "Open guide").appLocalized)
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
        .background(alignment: .top) {
            BrandBackdropView()
        }
        .navigationTitle("Brand Gallery")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedGuide) { guide in
            GuideSheet(guide: guide)
        }
    }

    private func seasonalPreviewSource(for season: BrandSeasonDefinition) -> BrandAssetSource? {
        let key = season.guideOverrides[season.spotlightGuideKey] ?? season.spotlightGuideKey
        return catalog.guideIfAvailable(key) ?? catalog.guideIfAvailable(season.spotlightGuideKey)
    }

    private func seasonCharacterPreviewSources(for season: BrandSeasonDefinition) -> [BrandAssetSource] {
        let keys: [String]
        switch season.id {
        case .halloween:
            keys = ["guide_27_tikki_halloween", "guide_28_mei_halloween", "guide_29_manchas_halloween"]
        case .winterHolidays:
            keys = ["guide_30_tikki_holiday", "guide_31_mei_holiday", "guide_32_manchas_holiday"]
        case .newYear:
            keys = ["guide_33_tikki_new_year", "guide_34_mei_new_year", "guide_35_manchas_new_year"]
        }

        return keys.compactMap { catalog.guideIfAvailable($0) }
    }

    private func seasonDateLabel(for season: BrandSeasonDefinition) -> String {
        if activeSeason?.id == season.id {
            return "Active on today's date".appLocalized
        }

        if let nextSeason, nextSeason.season.id == season.id {
            return AppLocalization.localized(
                "Starts %@",
                arguments: nextSeason.startDate.formatted(date: .abbreviated, time: .omitted)
            )
        }

        return "Catalog ready".appLocalized
    }
}
