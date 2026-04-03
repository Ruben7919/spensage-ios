import SwiftUI

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
            Text(text)
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
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                }

                Text(message)
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
                Text(title)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text(detail)
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
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(BrandTheme.muted)

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(BrandTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
