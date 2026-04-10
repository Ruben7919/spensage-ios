import SwiftUI

struct YarnBallView: View {
    let color: Color
    var size: CGFloat = 24
    var showThread: Bool = true

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Ellipse()
                .fill(BrandTheme.shadow.opacity(0.14))
                .frame(width: size * 0.82, height: size * 0.22)
                .blur(radius: size * 0.12)
                .offset(y: size * 0.42)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.28),
                            color.opacity(0.98),
                            color.opacity(0.92),
                            BrandTheme.ink.opacity(0.22)
                        ],
                        center: .topLeading,
                        startRadius: size * 0.04,
                        endRadius: size * 0.78
                    )
                )
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.18), Color.clear, BrandTheme.shadow.opacity(0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.38), lineWidth: max(1, size * 0.04))
                )
                .overlay(yarnTexture.clipShape(Circle()))
                .shadow(color: BrandTheme.shadow.opacity(0.16), radius: size * 0.22, x: 0, y: size * 0.14)

            if showThread {
                threadTail
                    .offset(x: size * 0.06, y: size * 0.12)
            }
        }
        .frame(width: size, height: size * 1.18)
    }

    private var yarnTexture: some View {
        ZStack {
            strand(width: 0.86, height: 0.48, rotation: 12, x: -0.01, y: -0.11, start: 0.08, end: 0.94, color: Color.white.opacity(0.34), lineWidth: 0.08)
            strand(width: 0.92, height: 0.54, rotation: -18, x: 0.0, y: 0.05, start: 0.10, end: 0.92, color: BrandTheme.shadow.opacity(0.12), lineWidth: 0.07)
            strand(width: 0.74, height: 0.44, rotation: 64, x: -0.05, y: -0.01, start: 0.16, end: 0.90, color: Color.white.opacity(0.20), lineWidth: 0.06)
            strand(width: 0.70, height: 0.40, rotation: -66, x: 0.06, y: 0.03, start: 0.14, end: 0.88, color: BrandTheme.ink.opacity(0.08), lineWidth: 0.055)
            curveStrand(
                start: CGPoint(x: 0.08, y: 0.43),
                control1: CGPoint(x: 0.28, y: 0.18),
                control2: CGPoint(x: 0.64, y: 0.24),
                end: CGPoint(x: 0.88, y: 0.40),
                color: Color.white.opacity(0.22),
                lineWidth: size * 0.06
            )
            curveStrand(
                start: CGPoint(x: 0.18, y: 0.72),
                control1: CGPoint(x: 0.34, y: 0.52),
                control2: CGPoint(x: 0.70, y: 0.60),
                end: CGPoint(x: 0.84, y: 0.78),
                color: BrandTheme.shadow.opacity(0.08),
                lineWidth: size * 0.05
            )
            curveStrand(
                start: CGPoint(x: 0.10, y: 0.24),
                control1: CGPoint(x: 0.24, y: 0.14),
                control2: CGPoint(x: 0.68, y: 0.18),
                end: CGPoint(x: 0.88, y: 0.30),
                color: Color.white.opacity(0.16),
                lineWidth: size * 0.045
            )
            curveStrand(
                start: CGPoint(x: 0.16, y: 0.56),
                control1: CGPoint(x: 0.34, y: 0.40),
                control2: CGPoint(x: 0.66, y: 0.44),
                end: CGPoint(x: 0.84, y: 0.62),
                color: Color.white.opacity(0.15),
                lineWidth: size * 0.04
            )
            curveStrand(
                start: CGPoint(x: 0.34, y: 0.06),
                control1: CGPoint(x: 0.44, y: 0.24),
                control2: CGPoint(x: 0.48, y: 0.70),
                end: CGPoint(x: 0.42, y: 0.92),
                color: BrandTheme.shadow.opacity(0.06),
                lineWidth: size * 0.036
            )
            curveStrand(
                start: CGPoint(x: 0.64, y: 0.08),
                control1: CGPoint(x: 0.58, y: 0.30),
                control2: CGPoint(x: 0.54, y: 0.70),
                end: CGPoint(x: 0.62, y: 0.94),
                color: BrandTheme.shadow.opacity(0.05),
                lineWidth: size * 0.034
            )
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: size * 0.22, height: size * 0.22)
                .offset(x: -size * 0.14, y: -size * 0.14)
            Circle()
                .stroke(BrandTheme.shadow.opacity(0.05), lineWidth: max(1, size * 0.028))
                .padding(size * 0.16)
        }
        .padding(size * 0.08)
    }

    private var threadTail: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: size * 0.16, y: size * 0.12))
                path.addCurve(
                    to: CGPoint(x: size * 0.72, y: size * 0.78),
                    control1: CGPoint(x: size * 0.58, y: size * 0.04),
                    control2: CGPoint(x: size * 0.16, y: size * 0.90)
                )
            }
            .stroke(BrandTheme.shadow.opacity(0.16), style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round, lineJoin: .round))

            Path { path in
                path.move(to: CGPoint(x: size * 0.16, y: size * 0.10))
                path.addCurve(
                    to: CGPoint(x: size * 0.70, y: size * 0.76),
                    control1: CGPoint(x: size * 0.56, y: size * 0.03),
                    control2: CGPoint(x: size * 0.18, y: size * 0.84)
                )
            }
            .stroke(color.opacity(0.86), style: StrokeStyle(lineWidth: size * 0.09, lineCap: .round, lineJoin: .round))

            Circle()
                .fill(color.opacity(0.28))
                .frame(width: size * 0.14, height: size * 0.14)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.20), lineWidth: max(1, size * 0.02))
                )
                .offset(x: size * 0.26, y: size * 0.34)
        }
        .frame(width: size * 0.86, height: size * 0.9)
    }

    private func strand(
        width: CGFloat,
        height: CGFloat,
        rotation: Double,
        x: CGFloat,
        y: CGFloat,
        start: CGFloat,
        end: CGFloat,
        color: Color,
        lineWidth: CGFloat
    ) -> some View {
        Ellipse()
            .trim(from: start, to: end)
            .stroke(color, style: StrokeStyle(lineWidth: max(1, size * lineWidth), lineCap: .round, lineJoin: .round))
            .frame(width: size * width, height: size * height)
            .rotationEffect(.degrees(rotation))
            .offset(x: size * x, y: size * y)
    }

    private func curveStrand(
        start: CGPoint,
        control1: CGPoint,
        control2: CGPoint,
        end: CGPoint,
        color: Color,
        lineWidth: CGFloat
    ) -> some View {
        Path { path in
            path.move(to: CGPoint(x: start.x * size, y: start.y * size))
            path.addCurve(
                to: CGPoint(x: end.x * size, y: end.y * size),
                control1: CGPoint(x: control1.x * size, y: control1.y * size),
                control2: CGPoint(x: control2.x * size, y: control2.y * size)
            )
        }
        .stroke(color, style: StrokeStyle(lineWidth: max(1, lineWidth), lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

struct YarnLoadingIndicator: View {
    var size: CGFloat = 22
    var colors: [Color] = [BrandTheme.primary, BrandTheme.accent, BrandTheme.warning]
    @State private var animate = false

    var body: some View {
        HStack(spacing: size * 0.28) {
            ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                YarnBallView(color: color, size: size, showThread: index == colors.count - 1)
                    .rotationEffect(.degrees(rotation(for: index)))
                    .offset(x: horizontalOffset(for: index), y: verticalOffset(for: index))
                    .scaleEffect(scale(for: index))
                    .animation(
                        .spring(response: 0.86, dampingFraction: 0.62, blendDuration: 0.14)
                            .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.12),
                        value: animate
                    )
            }
        }
        .frame(height: size * 1.28)
        .onAppear {
            animate = true
        }
    }

    private func rotation(for index: Int) -> Double {
        if animate {
            return index == 1 ? 0 : (index == 0 ? -16 : 16)
        }
        return index == 1 ? 0 : (index == 0 ? 10 : -10)
    }

    private func verticalOffset(for index: Int) -> CGFloat {
        if animate {
            return index == 1 ? size * 0.12 : -size * 0.16
        }
        return index == 1 ? -size * 0.08 : size * 0.08
    }

    private func horizontalOffset(for index: Int) -> CGFloat {
        if animate {
            return index == 1 ? 0 : (index == 0 ? -size * 0.06 : size * 0.06)
        }
        return index == 1 ? 0 : (index == 0 ? size * 0.04 : -size * 0.04)
    }

    private func scale(for index: Int) -> CGFloat {
        if animate {
            return index == 1 ? 1.05 : 0.93
        }
        return index == 1 ? 0.94 : 1.03
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

                Text("MichiFinanzas")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(BrandTheme.ink)

                Text("Cute money clarity for everyday life".appLocalized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BrandTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                YarnLoadingIndicator(size: 30)
                    .padding(.top, 4)
            }
            .padding(.vertical, 42)
        }
    }
}
