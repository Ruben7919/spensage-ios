import SwiftUI

struct BrandHeroMetric: Identifiable, Hashable {
    let title: String
    let value: String
    let systemImage: String

    var id: String {
        "\(title)-\(systemImage)-\(value)"
    }
}

struct BrandScenePanel: View {
    var sceneKey: String?
    var sceneFileName: String? = nil
    var fallbackSystemImage: String = "sparkles"
    var placeholderPrompt: String? = nil
    var placeholderCharacter: BrandCharacterID? = nil
    var height: CGFloat = 176

    private var source: BrandAssetSource? {
        if let sceneFileName {
            let source = BrandAssetCatalog.shared.guide(fileName: sceneFileName)
            return BrandAssetCatalog.shared.url(for: source) == nil ? nil : source
        }

        guard let sceneKey else { return nil }
        return BrandAssetCatalog.shared.guideIfAvailable(sceneKey)
    }

    var body: some View {
        BrandArtworkSurface {
            Group {
                if let source {
                    BrandAssetImage(source: source, fallbackSystemImage: fallbackSystemImage)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: height)
                } else if let placeholderPrompt, !placeholderPrompt.isEmpty {
                    if let placeholderCharacter {
                        BrandPromptPlaceholder(character: placeholderCharacter, prompt: placeholderPrompt)
                            .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            BrandBadge(text: "Art placeholder", systemImage: "wand.and.stars")

                            Text("Prompt for the next scene")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)

                            Text(placeholderPrompt)
                                .font(.subheadline)
                                .foregroundStyle(BrandTheme.muted)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(BrandTheme.surfaceTint)
                        Image(systemName: fallbackSystemImage)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(BrandTheme.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                }
            }
        }
    }
}

struct BrandBackdropView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(BrandTheme.accent.opacity(0.34))
                .frame(width: 270, height: 270)
                .blur(radius: 28)
                .offset(x: 132, y: -122)

            Circle()
                .fill(BrandTheme.primary.opacity(0.18))
                .frame(width: 220, height: 220)
                .blur(radius: 32)
                .offset(x: -148, y: 68)

            RoundedRectangle(cornerRadius: 78, style: .continuous)
                .fill(BrandTheme.surface.opacity(0.5))
                .frame(width: 240, height: 240)
                .rotationEffect(.degrees(14))
                .blur(radius: 16)
                .offset(x: 110, y: 226)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct BrandArtworkSurface<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(BrandTheme.guideArtworkGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(BrandTheme.line.opacity(0.72), lineWidth: 1)
            )
            .shadow(color: BrandTheme.shadow.opacity(0.1), radius: 18, x: 0, y: 10)
    }
}

struct BrandBadge: View {
    let text: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
            Text(text.appLocalized)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(BrandTheme.primary)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule(style: .continuous)
                .fill(BrandTheme.surface.opacity(0.82))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(BrandTheme.line.opacity(0.9), lineWidth: 1)
        )
        .shadow(color: BrandTheme.shadow.opacity(0.06), radius: 10, x: 0, y: 5)
    }
}

struct MascotAvatarView: View {
    let character: BrandCharacterID
    var expression: BrandExpression = .neutral
    var size: CGFloat = 76

    var body: some View {
        ZStack {
            Circle()
                .fill(BrandTheme.heroGlowGradient)

            BrandAssetImage(
                source: BrandAssetCatalog.shared.character(character, expression: expression),
                fallbackSystemImage: "face.smiling.inverse"
            )
            .aspectRatio(contentMode: .fit)
            .padding(size * 0.14)
        }
        .frame(width: size, height: size)
        .overlay(
            Circle()
                .stroke(BrandTheme.line.opacity(0.82), lineWidth: 1)
        )
        .shadow(color: BrandTheme.shadow.opacity(0.1), radius: 14, x: 0, y: 8)
    }
}

struct MascotSpeechCard: View {
    let character: BrandCharacterID
    var expression: BrandExpression = .neutral
    var title: String? = nil
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            MascotAvatarView(character: character, expression: expression)

            VStack(alignment: .leading, spacing: 8) {
                if let title {
                    Text(title.appLocalized)
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                }

                Text(message.appLocalized)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(BrandTheme.speechBubble)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(BrandTheme.line.opacity(0.72), lineWidth: 1)
            )
            .shadow(color: BrandTheme.shadow.opacity(0.08), radius: 14, x: 0, y: 8)
        }
    }
}

struct BrandFeatureRow: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(BrandTheme.accent.opacity(0.18))
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(BrandTheme.primary)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(title.appLocalized)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text(detail.appLocalized)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

struct BrandMetricTile: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                Text(title.appLocalized)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .foregroundStyle(BrandTheme.muted)

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(BrandTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 88, alignment: .topLeading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BrandTheme.surfaceTint)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(BrandTheme.line.opacity(0.85), lineWidth: 1)
        )
    }
}

struct StoryTag: View {
    let text: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.bold))
            }

            Text(text.appLocalized)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(BrandTheme.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(BrandTheme.accent.opacity(0.18))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(BrandTheme.line.opacity(0.82), lineWidth: 1)
        )
    }
}

struct CompactSectionHeader: View {
    let title: String
    let detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.appLocalized)
                .font(.title3.weight(.bold))
                .foregroundStyle(BrandTheme.ink)

            if let detail, !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(detail.appLocalized)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct QuickActionTile: View {
    let title: String
    let detail: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(BrandTheme.heroGlowGradient)
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(BrandTheme.primary)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text(title.appLocalized)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                Text(detail.appLocalized)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(BrandTheme.muted)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(BrandTheme.surfaceTint)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(BrandTheme.line.opacity(0.82), lineWidth: 1)
        )
    }
}

struct BrandPromptPlaceholder: View {
    let character: BrandCharacterID
    let prompt: String

    var body: some View {
        BrandArtworkSurface {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    MascotAvatarView(character: character, expression: .thinking, size: 58)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Artwork prompt pending".appLocalized)
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text(AppLocalization.localized("%@ still needs a dedicated scene for this surface.", arguments: character.narrativeName))
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text(prompt)
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct BrandStoryCard: View {
    let surface: AppSurfaceID
    let title: String
    let message: String
    var highlights: [String] = []

    private var spec: BrandNarrativeSpec {
        BrandStoryCatalog.spec(for: surface)
    }

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        BrandBadge(text: spec.badgeText, systemImage: "sparkles")

                        Text(title.appLocalized)
                            .font(.system(size: 31, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(message.appLocalized)
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    MascotAvatarView(character: spec.character, expression: spec.expression, size: 74)
                }

                if let sceneSource = spec.sceneSource {
                    BrandArtworkSurface {
                        BrandAssetImage(source: sceneSource, fallbackSystemImage: "photo")
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 150, maxHeight: 220)
                    }
                } else if let prompt = spec.scenePrompt {
                    BrandPromptPlaceholder(character: spec.character, prompt: prompt)
                }

                VStack(alignment: .leading, spacing: 8) {
                    StoryTag(
                        text: "\(spec.character.narrativeName) · \(spec.roleTitle.appLocalized)",
                        systemImage: "person.fill"
                    )

                    Text(spec.roleSummary.appLocalized)
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !highlights.isEmpty {
                    FlowStack(spacing: 10, rowSpacing: 10) {
                        ForEach(highlights, id: \.self) { item in
                            StoryTag(text: item)
                        }
                    }
                }
            }
        }
    }
}

struct JourneyHeroCard<ActionContent: View>: View {
    let eyebrow: String
    let title: String
    let summary: String
    let character: BrandCharacterID
    var expression: BrandExpression = .neutral
    var sceneKey: String? = nil
    var scenePrompt: String? = nil
    var metrics: [BrandHeroMetric] = []
    @ViewBuilder var actions: ActionContent

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        BrandBadge(text: eyebrow, systemImage: "sparkles")

                        Text(title.appLocalized)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(summary.appLocalized)
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    MascotAvatarView(character: character, expression: expression, size: 92)
                }

                if !metrics.isEmpty {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(metrics) { metric in
                            BrandMetricTile(title: metric.title, value: metric.value, systemImage: metric.systemImage)
                        }
                    }
                }

                if sceneKey != nil || scenePrompt != nil {
                    BrandScenePanel(
                        sceneKey: sceneKey,
                        fallbackSystemImage: "sparkles",
                        placeholderPrompt: scenePrompt,
                        placeholderCharacter: character,
                        height: 186
                    )
                }

                VStack(spacing: 12) {
                    actions
                }
            }
        }
    }
}
