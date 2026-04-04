import SwiftUI
import UIKit

enum AppAppearance {
    static let themeDefaultsKey = "native.settings.theme"

    static func colorScheme(for rawValue: String?) -> ColorScheme? {
        switch (rawValue ?? "finance").lowercased() {
        case "midnight":
            return .dark
        case "sunrise":
            return .light
        default:
            return nil
        }
    }
}

private extension Color {
    static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark ? dark : light
            }
        )
    }
}

enum BrandTheme {
    static let background = Color.adaptive(
        light: UIColor(red: 0.95, green: 0.97, blue: 0.97, alpha: 1),
        dark: UIColor(red: 0.05, green: 0.09, blue: 0.10, alpha: 1)
    )
    static let canvas = Color.adaptive(
        light: UIColor(red: 0.92, green: 0.96, blue: 0.95, alpha: 1),
        dark: UIColor(red: 0.07, green: 0.12, blue: 0.13, alpha: 1)
    )
    static let guideCanvas = Color.adaptive(
        light: UIColor(red: 0.94, green: 0.97, blue: 0.98, alpha: 1),
        dark: UIColor(red: 0.08, green: 0.11, blue: 0.14, alpha: 1)
    )
    static let surface = Color.adaptive(
        light: .white,
        dark: UIColor(red: 0.10, green: 0.15, blue: 0.17, alpha: 1)
    )
    static let surfaceTint = Color.adaptive(
        light: UIColor(red: 0.98, green: 0.99, blue: 0.99, alpha: 1),
        dark: UIColor(red: 0.13, green: 0.19, blue: 0.21, alpha: 1)
    )
    static let line = Color.adaptive(
        light: UIColor(red: 0.82, green: 0.89, blue: 0.88, alpha: 1),
        dark: UIColor(red: 0.24, green: 0.33, blue: 0.35, alpha: 1)
    )
    static let primary = Color.adaptive(
        light: UIColor(red: 0.08, green: 0.45, blue: 0.45, alpha: 1),
        dark: UIColor(red: 0.48, green: 0.87, blue: 0.84, alpha: 1)
    )
    static let accent = Color.adaptive(
        light: UIColor(red: 0.58, green: 0.82, blue: 0.80, alpha: 1),
        dark: UIColor(red: 0.19, green: 0.37, blue: 0.39, alpha: 1)
    )
    static let glow = Color.adaptive(
        light: UIColor(red: 0.71, green: 0.91, blue: 0.88, alpha: 1),
        dark: UIColor(red: 0.25, green: 0.53, blue: 0.50, alpha: 1)
    )
    static let ink = Color.adaptive(
        light: UIColor(red: 0.10, green: 0.17, blue: 0.19, alpha: 1),
        dark: UIColor(red: 0.90, green: 0.95, blue: 0.95, alpha: 1)
    )
    static let muted = Color.adaptive(
        light: UIColor(red: 0.40, green: 0.47, blue: 0.49, alpha: 1),
        dark: UIColor(red: 0.62, green: 0.70, blue: 0.71, alpha: 1)
    )
    static let shadow = Color.adaptive(
        light: UIColor(red: 0.03, green: 0.11, blue: 0.13, alpha: 1),
        dark: UIColor.black
    )
    static let speechBubble = Color.adaptive(
        light: UIColor(red: 0.98, green: 0.99, blue: 1.0, alpha: 1),
        dark: UIColor(red: 0.12, green: 0.18, blue: 0.20, alpha: 1)
    )

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

    static let heroSurfaceGradient = LinearGradient(
        colors: [
            primary.opacity(0.96),
            Color.adaptive(
                light: UIColor(red: 0.14, green: 0.57, blue: 0.56, alpha: 1),
                dark: UIColor(red: 0.12, green: 0.26, blue: 0.28, alpha: 1)
            ),
            Color.adaptive(
                light: UIColor(red: 0.29, green: 0.66, blue: 0.63, alpha: 1),
                dark: UIColor(red: 0.09, green: 0.18, blue: 0.20, alpha: 1)
            )
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let success = Color.adaptive(
        light: UIColor(red: 0.12, green: 0.58, blue: 0.36, alpha: 1),
        dark: UIColor(red: 0.36, green: 0.78, blue: 0.58, alpha: 1)
    )
    static let warning = Color.adaptive(
        light: UIColor(red: 0.83, green: 0.56, blue: 0.16, alpha: 1),
        dark: UIColor(red: 0.94, green: 0.74, blue: 0.34, alpha: 1)
    )
    static let danger = Color.adaptive(
        light: UIColor(red: 0.79, green: 0.28, blue: 0.24, alpha: 1),
        dark: UIColor(red: 0.94, green: 0.53, blue: 0.47, alpha: 1)
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
