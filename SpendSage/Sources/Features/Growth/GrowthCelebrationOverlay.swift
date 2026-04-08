import SwiftUI
import UIKit

struct GrowthCelebrationOverlay: View {
    let celebration: GrowthCelebration
    let queuedCount: Int
    let onDismiss: () -> Void

    @State private var sharePayload: GrowthCelebrationSharePayload?
    @State private var didRequestShare = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()

            CelebrationConfettiView()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 18) {
                HStack(spacing: 10) {
                    BrandBadge(text: celebration.kind.badgeLabel, systemImage: "sparkles")

                    if queuedCount > 0 {
                        BrandBadge(
                            text: AppLocalization.localized("%d más", arguments: queuedCount),
                            systemImage: "chevron.right.circle.fill"
                        )
                    }
                }

                celebrationCard

                Text("Si quieres, compártelo en Instagram, X, WhatsApp o cualquier red desde la hoja de compartir de iOS.")
                    .font(.footnote)
                    .foregroundStyle(Color.white.opacity(0.84))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("celebration.share.hint")

                HStack(spacing: 12) {
                    Button("Compartir en redes") {
                        didRequestShare = true
                        sharePayload = GrowthCelebrationSharePayload.make(for: celebration)
                    }
                    .buttonStyle(SecondaryCTAStyle())
                    .accessibilityIdentifier("celebration.action.share")

                    Button("Cerrar") {
                        onDismiss()
                    }
                    .buttonStyle(PrimaryCTAStyle())
                    .accessibilityIdentifier("celebration.action.close")
                }

                if didRequestShare {
                    Color.clear
                        .frame(width: 1, height: 1)
                        .accessibilityElement()
                        .accessibilityIdentifier("celebration.share.presented")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 30)
        }
        .transition(.opacity.combined(with: .scale(scale: 1.03)))
        .sheet(item: $sharePayload) { payload in
            ActivityShareSheet(items: payload.items)
        }
    }

    private var celebrationCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 14) {
                    CelebrationBadgePlate(celebration: celebration)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(celebration.title)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)

                        Text(celebration.message)
                            .font(.headline)
                            .foregroundStyle(BrandTheme.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(celebration.detail)
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(BrandTheme.muted)
                            .frame(width: 34, height: 34)
                            .background(BrandTheme.surfaceTint)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 14) {
                    CelebrationMascotBadge(character: .tikki, expression: .excited)
                    CelebrationMascotBadge(character: .mei, expression: .love)
                    CelebrationMascotBadge(character: .manchas, expression: .proud)
                }
                .frame(maxWidth: .infinity)

                if celebration.rewardXP != nil || celebration.reachedLevel != nil {
                    FlowStack(spacing: 8, rowSpacing: 8) {
                        if let rewardXP = celebration.rewardXP {
                            StoryTag(text: AppLocalization.localized("+%d XP", arguments: rewardXP), systemImage: "sparkles")
                        }
                        if let reachedLevel = celebration.reachedLevel {
                            StoryTag(text: AppLocalization.localized("Nivel %d", arguments: reachedLevel), systemImage: "bolt.fill")
                        }
                    }
                }
            }
        }
        .shadow(color: BrandTheme.shadow.opacity(0.18), radius: 26, x: 0, y: 18)
    }
}

private struct CelebrationBadgePlate: View {
    let celebration: GrowthCelebration

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(BrandTheme.heroGlowGradient)

            if let image = BrandAssetCatalog.shared.image(for: BrandAssetCatalog.shared.badge(named: celebration.badgeAsset)) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(18)
            } else {
                Image(systemName: celebration.systemImage)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 102, height: 102)
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.82), lineWidth: 1.2)
        )
        .shadow(color: BrandTheme.shadow.opacity(0.18), radius: 18, x: 0, y: 12)
    }
}

private struct CelebrationMascotBadge: View {
    let character: BrandCharacterID
    let expression: BrandExpression

    var body: some View {
        VStack(spacing: 8) {
            MascotAvatarView(character: character, expression: expression, size: 66)
            Text(character.narrativeName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BrandTheme.muted)
        }
    }
}

private struct CelebrationConfettiPiece: Identifiable {
    let id = UUID()
    let x: CGFloat
    let size: CGFloat
    let rotation: Double
    let delay: Double
    let duration: Double
    let color: Color
    let symbol: String?
}

private struct CelebrationConfettiView: View {
    @State private var animate = false

    private let pieces: [CelebrationConfettiPiece] = [
        CelebrationConfettiPiece(x: 0.08, size: 16, rotation: 120, delay: 0.0, duration: 2.8, color: BrandTheme.primary, symbol: "sparkle"),
        CelebrationConfettiPiece(x: 0.15, size: 12, rotation: 220, delay: 0.18, duration: 2.6, color: BrandTheme.accent, symbol: nil),
        CelebrationConfettiPiece(x: 0.26, size: 14, rotation: 180, delay: 0.32, duration: 3.0, color: BrandTheme.warning, symbol: nil),
        CelebrationConfettiPiece(x: 0.34, size: 18, rotation: 260, delay: 0.08, duration: 2.7, color: BrandTheme.primary, symbol: "star.fill"),
        CelebrationConfettiPiece(x: 0.46, size: 12, rotation: 210, delay: 0.4, duration: 2.5, color: BrandTheme.accent, symbol: nil),
        CelebrationConfettiPiece(x: 0.55, size: 16, rotation: 190, delay: 0.12, duration: 3.1, color: BrandTheme.warning, symbol: "sparkle"),
        CelebrationConfettiPiece(x: 0.66, size: 13, rotation: 240, delay: 0.2, duration: 2.9, color: BrandTheme.primary, symbol: nil),
        CelebrationConfettiPiece(x: 0.74, size: 18, rotation: 280, delay: 0.36, duration: 2.7, color: BrandTheme.accent, symbol: "star.fill"),
        CelebrationConfettiPiece(x: 0.84, size: 12, rotation: 200, delay: 0.1, duration: 2.8, color: BrandTheme.warning, symbol: nil),
        CelebrationConfettiPiece(x: 0.92, size: 15, rotation: 250, delay: 0.24, duration: 3.0, color: BrandTheme.primary, symbol: "sparkle")
    ]

    var body: some View {
        GeometryReader { geometry in
            ForEach(pieces) { piece in
                confettiView(for: piece)
                    .position(
                        x: geometry.size.width * piece.x,
                        y: animate ? geometry.size.height + 40 : -60
                    )
                    .rotationEffect(.degrees(animate ? piece.rotation : 0))
                    .opacity(0.92)
                    .animation(
                        .linear(duration: piece.duration)
                            .repeatForever(autoreverses: false)
                            .delay(piece.delay),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }

    @ViewBuilder
    private func confettiView(for piece: CelebrationConfettiPiece) -> some View {
        if let symbol = piece.symbol {
            Image(systemName: symbol)
                .font(.system(size: piece.size, weight: .bold))
                .foregroundStyle(piece.color)
        } else {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(piece.color)
                .frame(width: piece.size * 0.62, height: piece.size)
        }
    }
}

private struct GrowthCelebrationSharePayload: Identifiable {
    let id = UUID()
    let items: [Any]

    @MainActor
    static func make(for celebration: GrowthCelebration) -> GrowthCelebrationSharePayload {
        let card = GrowthCelebrationShareCard(celebration: celebration)
            .frame(width: 1080, height: 1350)
            .background(BrandTheme.canvas)

        let renderer = ImageRenderer(content: card)
        renderer.scale = 2

        if let image = renderer.uiImage {
            return GrowthCelebrationSharePayload(items: [celebration.shareText, image])
        }

        return GrowthCelebrationSharePayload(items: [celebration.shareText])
    }
}

private struct GrowthCelebrationShareCard: View {
    let celebration: GrowthCelebration

    var body: some View {
        ZStack {
            BrandTheme.canvas

            BrandBackdropView()

            VStack(alignment: .leading, spacing: 32) {
                HStack {
                    BrandBadge(text: celebration.kind.badgeLabel, systemImage: "sparkles")
                    Spacer()
                    Text("SpendSage")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(BrandTheme.ink)
                }

                HStack(alignment: .top, spacing: 24) {
                    CelebrationBadgePlate(celebration: celebration)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(celebration.title)
                            .font(.system(size: 82, weight: .black, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)
                            .minimumScaleFactor(0.7)

                        Text(celebration.message)
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.primary)

                        Text(celebration.detail)
                            .font(.system(size: 30, weight: .medium, design: .rounded))
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 26) {
                    CelebrationMascotBadge(character: .tikki, expression: .excited)
                    CelebrationMascotBadge(character: .mei, expression: .love)
                    CelebrationMascotBadge(character: .manchas, expression: .proud)
                }
                .padding(.top, 8)

                Spacer()

                HStack {
                    Text("Ahorro cute y claro")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandTheme.primary)
                    Spacer()
                    if let reachedLevel = celebration.reachedLevel {
                        StoryTag(text: AppLocalization.localized("Nivel %d", arguments: reachedLevel), systemImage: "bolt.fill")
                    } else if let rewardXP = celebration.rewardXP {
                        StoryTag(text: AppLocalization.localized("+%d XP", arguments: rewardXP), systemImage: "sparkles")
                    }
                }
            }
            .padding(72)
        }
    }
}

private struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.view.isAccessibilityElement = true
        controller.view.accessibilityIdentifier = "celebration.share.presented"
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        uiViewController.view.isAccessibilityElement = true
        uiViewController.view.accessibilityIdentifier = "celebration.share.presented"
    }
}
