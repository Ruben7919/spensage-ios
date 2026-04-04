import SwiftUI

struct YarnBallView: View {
    let color: Color
    var size: CGFloat = 24
    var showThread: Bool = true

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.98), color.opacity(0.86), BrandTheme.ink.opacity(0.18)],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: size * 0.7
                    )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.32), lineWidth: 1)
                )
                .overlay(yarnLines)
                .shadow(color: BrandTheme.shadow.opacity(0.12), radius: 8, x: 0, y: 4)

            if showThread {
                threadTail
                    .offset(x: size * 0.08, y: size * 0.14)
            }
        }
        .frame(width: size, height: size)
    }

    private var yarnLines: some View {
        ZStack {
            Ellipse()
                .stroke(Color.white.opacity(0.26), lineWidth: 1)
                .scaleEffect(x: 0.76, y: 0.36)
                .rotationEffect(.degrees(18))
            Ellipse()
                .stroke(Color.white.opacity(0.20), lineWidth: 1)
                .scaleEffect(x: 0.82, y: 0.42)
                .rotationEffect(.degrees(-24))
            Ellipse()
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
                .scaleEffect(x: 0.62, y: 0.25)
                .rotationEffect(.degrees(68))
        }
        .padding(size * 0.16)
    }

    private var threadTail: some View {
        Path { path in
            path.move(to: CGPoint(x: size * 0.14, y: size * 0.1))
            path.addCurve(
                to: CGPoint(x: size * 0.7, y: size * 0.76),
                control1: CGPoint(x: size * 0.5, y: size * 0.06),
                control2: CGPoint(x: size * 0.18, y: size * 0.82)
            )
        }
        .stroke(color.opacity(0.78), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        .frame(width: size * 0.72, height: size * 0.72)
    }
}

struct YarnLoadingIndicator: View {
    var size: CGFloat = 22
    var colors: [Color] = [BrandTheme.primary, BrandTheme.accent, BrandTheme.warning]
    @State private var animate = false

    var body: some View {
        HStack(spacing: size * 0.34) {
            ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                YarnBallView(color: color, size: size, showThread: index == colors.count - 1)
                    .rotationEffect(.degrees(animate ? (index.isMultiple(of: 2) ? 10 : -10) : (index.isMultiple(of: 2) ? -8 : 8)))
                    .offset(y: animate ? (index == 1 ? size * 0.18 : -size * 0.16) : (index == 1 ? -size * 0.1 : size * 0.12))
                    .scaleEffect(animate ? (index == 1 ? 1.02 : 0.96) : (index == 1 ? 0.96 : 1.02))
                    .animation(
                        .easeInOut(duration: 0.76)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.12),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct MascotLoadingCard: View {
    let badgeText: String
    let title: String
    let summary: String
    let character: BrandCharacterID
    var expression: BrandExpression = .excited

    var body: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    MascotAvatarView(character: character, expression: expression, size: 68)

                    VStack(alignment: .leading, spacing: 6) {
                        BrandBadge(text: badgeText, systemImage: "sparkles")

                        Text(title.appLocalized)
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text(summary.appLocalized)
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 12) {
                    YarnLoadingIndicator(size: 24)

                    Text("Loading".appLocalized)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.muted)
                }
            }
        }
    }
}

struct LaunchExperienceView: View {
    var body: some View {
        ZStack {
            BrandTheme.guideCanvas
                .ignoresSafeArea()

            LinearGradient(
                colors: [Color.white.opacity(0.14), Color.clear, BrandTheme.accent.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                BrandArtworkSurface {
                    BrandAssetImage(
                        source: BrandAssetCatalog.shared.guide("guide_26_loading_yarn_team"),
                        fallbackSystemImage: "sparkles"
                    )
                    .scaledToFit()
                    .frame(maxWidth: 308)
                }
                .padding(.horizontal, 28)

                Text("SpendSage")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(BrandTheme.ink)

                Text("Cute money clarity for everyday life".appLocalized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BrandTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                YarnLoadingIndicator(size: 26)
                    .padding(.top, 4)
            }
            .padding(.vertical, 42)
        }
    }
}
