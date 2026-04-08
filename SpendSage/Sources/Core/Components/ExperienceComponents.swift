import SwiftUI

struct ExperienceHeroMetric: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let value: String
    let systemImage: String
}

struct ExperienceHeroCard: View {
    let eyebrow: String
    let eyebrowSystemImage: String
    let title: String
    let summary: String
    let character: BrandCharacterID
    let expression: BrandExpression
    var sceneKey: String? = nil
    var sceneTitle: String? = nil
    var sceneSummary: String? = nil
    var placeholderPrompt: String? = nil
    var metrics: [ExperienceHeroMetric] = []

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        BrandBadge(text: eyebrow, systemImage: eyebrowSystemImage)

                        Text(title.appLocalized)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(summary.appLocalized)
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    MascotAvatarView(character: character, expression: expression, size: 76)
                }

                if !metrics.isEmpty {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        ForEach(metrics) { metric in
                            BrandMetricTile(
                                title: metric.title,
                                value: metric.value,
                                systemImage: metric.systemImage
                            )
                        }
                    }
                }

                ExperienceSceneCard(
                    character: character,
                    expression: expression,
                    sceneKey: sceneKey,
                    title: sceneTitle,
                    summary: sceneSummary,
                    placeholderPrompt: placeholderPrompt
                )
            }
        }
    }
}

struct ExperienceSceneCard: View {
    let character: BrandCharacterID
    let expression: BrandExpression
    var sceneKey: String? = nil
    var title: String? = nil
    var summary: String? = nil
    var placeholderPrompt: String? = nil

    private var sceneSource: BrandAssetSource? {
        guard let sceneKey else { return nil }
        return BrandAssetCatalog.shared.guide(sceneKey)
    }

    var body: some View {
        Group {
            if sceneSource != nil || placeholderPrompt != nil || title != nil || summary != nil {
                VStack(alignment: .leading, spacing: 12) {
                    if let title {
                        Text(title.appLocalized)
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                    }

                    if let summary {
                        Text(summary.appLocalized)
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    BrandArtworkSurface {
                        if let sceneSource {
                            BrandAssetImage(source: sceneSource, fallbackSystemImage: "sparkles")
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 164)
                        } else {
                            ExperiencePlaceholderArtCard(
                                character: character,
                                expression: expression,
                                prompt: placeholderPrompt ?? "Illustrate a calm B2C mobile finance scene with the mascot helping the user make one next decision."
                            )
                        }
                    }
                }
            }
        }
    }
}

struct ExperiencePlaceholderArtCard: View {
    let character: BrandCharacterID
    let expression: BrandExpression
    let prompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                MascotAvatarView(character: character, expression: expression, size: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Placeholder art")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Text("Use this prompt to generate the missing scene and drop it into the character assets folder.")
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(prompt)
                .font(.footnote)
                .foregroundStyle(BrandTheme.ink)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(BrandTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ExperienceSectionCard<Content: View>: View {
    let title: String
    let summary: String
    var badgeText: String? = nil
    var badgeSystemImage: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title.appLocalized)
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text(summary.appLocalized)
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    if let badgeText, let badgeSystemImage {
                        BrandBadge(text: badgeText, systemImage: badgeSystemImage)
                    }
                }

                content
            }
        }
    }
}

struct ExperienceDisclosureCard<Content: View>: View {
    let title: String
    let summary: String
    let character: BrandCharacterID
    let expression: BrandExpression
    let accessibilityIdentifier: String?
    @State private var isExpanded: Bool
    @ViewBuilder var content: Content

    init(
        title: String,
        summary: String,
        character: BrandCharacterID,
        expression: BrandExpression = .thinking,
        initiallyExpanded: Bool = false,
        accessibilityIdentifier: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.summary = summary
        self.character = character
        self.expression = expression
        self.accessibilityIdentifier = accessibilityIdentifier
        _isExpanded = State(initialValue: initiallyExpanded)
        self.content = content()
    }

    var body: some View {
        SurfaceCard {
            if let accessibilityIdentifier {
                disclosureGroup
                    .accessibilityIdentifier(accessibilityIdentifier)
            } else {
                disclosureGroup
            }
        }
    }

    private var disclosureGroup: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 16) {
                Divider()
                content
            }
            .padding(.top, 8)
        } label: {
            HStack(alignment: .top, spacing: 14) {
                MascotAvatarView(character: character, expression: expression, size: 54)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title.appLocalized)
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Text(summary.appLocalized)
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .contentShape(Rectangle())
        }
        .tint(BrandTheme.primary)
    }
}
