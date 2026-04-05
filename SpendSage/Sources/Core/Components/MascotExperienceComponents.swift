import SwiftUI

struct MascotHeroStat: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let value: String
    let systemImage: String
}

struct MascotRosterEntry: Identifiable, Hashable {
    let id = UUID()
    let character: BrandCharacterID
    let expression: BrandExpression
    let role: String
    let summary: String
}

extension BrandCharacterID {
    var displayName: String {
        switch self {
        case .tikki:
            return "Tikki".appLocalized
        case .mei:
            return "Ludo".appLocalized
        case .manchas:
            return "Manchas".appLocalized
        }
    }
}

struct MascotScenePanel: View {
    let character: BrandCharacterID
    var expression: BrandExpression = .neutral
    var sceneKey: String? = nil
    var placeholderPrompt: String? = nil
    var minHeight: CGFloat = 200

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(BrandTheme.guideArtworkGradient)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(BrandTheme.heroGlowGradient.opacity(0.75))

            if let sceneKey, let scene = BrandAssetCatalog.shared.guide(sceneKey) {
                BrandAssetImage(source: scene, fallbackSystemImage: "sparkles")
                    .aspectRatio(contentMode: .fit)
                    .padding(18)
            } else if let placeholderPrompt {
                VStack(alignment: .leading, spacing: 12) {
                    BrandBadge(text: "Placeholder scene", systemImage: "photo.badge.plus")

                    Text("Prompt".appLocalized)
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)

                    Text(placeholderPrompt)
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                HStack {
                    Spacer(minLength: 0)
                    MascotAvatarView(character: character, expression: expression, size: 108)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 24)
            }

            HStack(spacing: 10) {
                MascotAvatarView(character: character, expression: expression, size: 58)

                VStack(alignment: .leading, spacing: 2) {
                    Text(character.displayName)
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Text("In-app guide".appLocalized)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.muted)
                }
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, minHeight: minHeight)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(BrandTheme.line.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: BrandTheme.shadow.opacity(0.08), radius: 18, x: 0, y: 10)
    }
}

struct MascotTagChip: View {
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
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(BrandTheme.accent.opacity(0.14))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(BrandTheme.line.opacity(0.82), lineWidth: 1)
        )
    }
}

struct MascotHeroCard<Actions: View>: View {
    let eyebrow: String
    let title: String
    let summary: String
    let character: BrandCharacterID
    var expression: BrandExpression = .neutral
    var sceneKey: String? = nil
    var placeholderPrompt: String? = nil
    var stats: [MascotHeroStat] = []
    var tags: [(text: String, systemImage: String)] = []
    @ViewBuilder var actions: Actions

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        BrandBadge(text: eyebrow, systemImage: "sparkles")

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

                MascotScenePanel(
                    character: character,
                    expression: expression,
                    sceneKey: sceneKey,
                    placeholderPrompt: placeholderPrompt
                )

                if !stats.isEmpty {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(stats) { stat in
                            BrandMetricTile(
                                title: stat.title,
                                value: stat.value,
                                systemImage: stat.systemImage
                            )
                        }
                    }
                }

                if !tags.isEmpty {
                    FlowStack(spacing: 8, rowSpacing: 8) {
                        ForEach(Array(tags.enumerated()), id: \.offset) { _, tag in
                            MascotTagChip(text: tag.text, systemImage: tag.systemImage)
                        }
                    }
                }

                actions
            }
        }
    }
}

struct GuidedSectionCard<Content: View>: View {
    let title: String
    let summary: String
    let character: BrandCharacterID
    var expression: BrandExpression = .neutral
    var systemImage: String = "sparkles"
    @ViewBuilder var content: Content

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    MascotAvatarView(character: character, expression: expression, size: 60)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(title.appLocalized)
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text(summary.appLocalized)
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    BrandBadge(text: character.displayName, systemImage: systemImage)
                }

                content
            }
        }
    }
}

struct CollapsibleSurfaceCard<Content: View>: View {
    let title: String
    let summary: String
    let systemImage: String
    @Binding var isExpanded: Bool
    @ViewBuilder var content: Content

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
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
                            Text(summary.appLocalized)
                                .font(.subheadline)
                                .foregroundStyle(BrandTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(BrandTheme.muted)
                            .padding(.top, 6)
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    content
                }
            }
        }
    }
}

struct MascotRosterCard: View {
    let title: String
    let summary: String
    let entries: [MascotRosterEntry]

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(title.appLocalized)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                Text(summary.appLocalized)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                    ForEach(entries) { entry in
                        HStack(alignment: .top, spacing: 12) {
                            MascotAvatarView(
                                character: entry.character,
                                expression: entry.expression,
                                size: 58
                            )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.character.displayName)
                                    .font(.headline)
                                    .foregroundStyle(BrandTheme.ink)
                                Text(entry.role.appLocalized)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(BrandTheme.primary)
                                Text(entry.summary.appLocalized)
                                    .font(.subheadline)
                                    .foregroundStyle(BrandTheme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }
}

struct CharacterCrewMember: Identifiable {
    let id = UUID()
    let title: String
    let role: String
    let detail: String
    let character: BrandCharacterID
    let expression: BrandExpression
}

struct CharacterCrewRail: View {
    let members: [CharacterCrewMember]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 190, maximum: 240), spacing: 12)],
            spacing: 12
        ) {
            ForEach(members) { member in
                CharacterCrewCard(member: member)
            }
        }
    }
}

private struct CharacterCrewCard: View {
    let member: CharacterCrewMember

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(BrandTheme.surfaceTint)

                MascotAvatarView(character: member.character, expression: member.expression, size: 64)
                    .padding(10)
            }
            .frame(maxWidth: .infinity, minHeight: 144, maxHeight: 144)

            VStack(alignment: .leading, spacing: 4) {
                Text(member.title.appLocalized)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text(member.role.appLocalized)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(BrandTheme.primary)
                Text(member.detail.appLocalized)
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(BrandTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: BrandTheme.shadow.opacity(0.08), radius: 14, x: 0, y: 8)
    }
}
