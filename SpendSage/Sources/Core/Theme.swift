import SwiftUI

enum BrandTheme {
    static let background = Color(red: 0.95, green: 0.97, blue: 0.97)
    static let canvas = Color(red: 0.92, green: 0.96, blue: 0.95)
    static let guideCanvas = Color(red: 0.94, green: 0.97, blue: 0.98)
    static let surface = Color.white
    static let surfaceTint = Color(red: 0.98, green: 0.99, blue: 0.99)
    static let line = Color(red: 0.82, green: 0.89, blue: 0.88)
    static let primary = Color(red: 0.08, green: 0.45, blue: 0.45)
    static let accent = Color(red: 0.58, green: 0.82, blue: 0.80)
    static let glow = Color(red: 0.71, green: 0.91, blue: 0.88)
    static let ink = Color(red: 0.10, green: 0.17, blue: 0.19)
    static let muted = Color(red: 0.40, green: 0.47, blue: 0.49)
    static let shadow = Color(red: 0.03, green: 0.11, blue: 0.13)
    static let speechBubble = Color(red: 0.98, green: 0.99, blue: 1.0)

    static let guideArtworkGradient = LinearGradient(
        colors: [
            Color(red: 0.98, green: 0.99, blue: 1.0),
            Color(red: 0.93, green: 0.96, blue: 0.99)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let heroGlowGradient = LinearGradient(
        colors: [
            accent.opacity(0.22),
            glow.opacity(0.18),
            primary.opacity(0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct PrimaryCTAStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(BrandTheme.primary.opacity(configuration.isPressed ? 0.86 : 1))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .shadow(color: BrandTheme.shadow.opacity(configuration.isPressed ? 0.08 : 0.16), radius: 14, x: 0, y: 8)
    }
}

struct SecondaryCTAStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(BrandTheme.surfaceTint.opacity(configuration.isPressed ? 0.92 : 1))
            .foregroundStyle(BrandTheme.ink)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(BrandTheme.line.opacity(0.85), lineWidth: 1.2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
    }
}

struct SurfaceCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(BrandTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(BrandTheme.line.opacity(0.7), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: BrandTheme.shadow.opacity(0.08), radius: 20, x: 0, y: 10)
    }
}
