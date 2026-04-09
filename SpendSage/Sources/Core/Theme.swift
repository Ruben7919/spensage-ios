import SwiftUI
import UIKit

enum AppAppearance {
    static let themeDefaultsKey = "native.settings.theme"

    static func themeSelection(for rawValue: String?) -> AppThemeSelection {
        AppThemeSelection(rawValue: (rawValue ?? AppThemeSelection.finance.rawValue).lowercased()) ?? .finance
    }

    static func colorScheme(for rawValue: String?) -> ColorScheme? {
        switch themeSelection(for: rawValue) {
        case .midnight:
            return .dark
        case .sunrise:
            return .light
        case .finance:
            return nil
        }
    }

    static func palette(for rawValue: String?) -> BrandPalette {
        switch themeSelection(for: rawValue) {
        case .midnight:
            return .midnight
        case .sunrise:
            return .sunrise
        case .finance:
            return .finance
        }
    }
}

enum AppThemeSelection: String {
    case finance
    case midnight
    case sunrise
}

struct BrandPalette {
    let background: Color
    let canvas: Color
    let guideCanvas: Color
    let surface: Color
    let surfaceTint: Color
    let line: Color
    let primary: Color
    let accent: Color
    let glow: Color
    let ink: Color
    let muted: Color
    let shadow: Color
    let speechBubble: Color
    let guideArtworkStart: Color
    let guideArtworkEnd: Color
    let heroStart: Color
    let heroMid: Color
    let heroEnd: Color
    let success: Color
    let warning: Color
    let danger: Color
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
    static var palette: BrandPalette {
        AppAppearance.palette(for: UserDefaults.standard.string(forKey: AppAppearance.themeDefaultsKey))
    }

    static var background: Color { palette.background }
    static var canvas: Color { palette.canvas }
    static var guideCanvas: Color { palette.guideCanvas }
    static var surface: Color { palette.surface }
    static var surfaceTint: Color { palette.surfaceTint }
    static var line: Color { palette.line }
    static var primary: Color { palette.primary }
    static var accent: Color { palette.accent }
    static var glow: Color { palette.glow }
    static var ink: Color { palette.ink }
    static var muted: Color { palette.muted }
    static var shadow: Color { palette.shadow }
    static var speechBubble: Color { palette.speechBubble }

    static var guideArtworkGradient: LinearGradient {
        LinearGradient(
            colors: [palette.guideArtworkStart, palette.guideArtworkEnd],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var heroGlowGradient: LinearGradient {
        LinearGradient(
            colors: [
                accent.opacity(0.22),
                glow.opacity(0.18),
                primary.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var heroSurfaceGradient: LinearGradient {
        LinearGradient(
            colors: [palette.heroStart, palette.heroMid, palette.heroEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var success: Color { palette.success }
    static var warning: Color { palette.warning }
    static var danger: Color { palette.danger }
}

private extension BrandPalette {
    static let finance = BrandPalette(
        background: Color.adaptive(
            light: UIColor(red: 0.95, green: 0.97, blue: 0.97, alpha: 1),
            dark: UIColor(red: 0.05, green: 0.09, blue: 0.10, alpha: 1)
        ),
        canvas: Color.adaptive(
            light: UIColor(red: 0.92, green: 0.96, blue: 0.95, alpha: 1),
            dark: UIColor(red: 0.07, green: 0.12, blue: 0.13, alpha: 1)
        ),
        guideCanvas: Color.adaptive(
            light: UIColor(red: 0.94, green: 0.97, blue: 0.98, alpha: 1),
            dark: UIColor(red: 0.08, green: 0.11, blue: 0.14, alpha: 1)
        ),
        surface: Color.adaptive(
            light: .white,
            dark: UIColor(red: 0.10, green: 0.15, blue: 0.17, alpha: 1)
        ),
        surfaceTint: Color.adaptive(
            light: UIColor(red: 0.98, green: 0.99, blue: 0.99, alpha: 1),
            dark: UIColor(red: 0.13, green: 0.19, blue: 0.21, alpha: 1)
        ),
        line: Color.adaptive(
            light: UIColor(red: 0.82, green: 0.89, blue: 0.88, alpha: 1),
            dark: UIColor(red: 0.24, green: 0.33, blue: 0.35, alpha: 1)
        ),
        primary: Color.adaptive(
            light: UIColor(red: 0.08, green: 0.45, blue: 0.45, alpha: 1),
            dark: UIColor(red: 0.48, green: 0.87, blue: 0.84, alpha: 1)
        ),
        accent: Color.adaptive(
            light: UIColor(red: 0.58, green: 0.82, blue: 0.80, alpha: 1),
            dark: UIColor(red: 0.19, green: 0.37, blue: 0.39, alpha: 1)
        ),
        glow: Color.adaptive(
            light: UIColor(red: 0.71, green: 0.91, blue: 0.88, alpha: 1),
            dark: UIColor(red: 0.25, green: 0.53, blue: 0.50, alpha: 1)
        ),
        ink: Color.adaptive(
            light: UIColor(red: 0.10, green: 0.17, blue: 0.19, alpha: 1),
            dark: UIColor(red: 0.90, green: 0.95, blue: 0.95, alpha: 1)
        ),
        muted: Color.adaptive(
            light: UIColor(red: 0.40, green: 0.47, blue: 0.49, alpha: 1),
            dark: UIColor(red: 0.62, green: 0.70, blue: 0.71, alpha: 1)
        ),
        shadow: Color.adaptive(
            light: UIColor(red: 0.03, green: 0.11, blue: 0.13, alpha: 1),
            dark: UIColor.black
        ),
        speechBubble: Color.adaptive(
            light: UIColor(red: 0.98, green: 0.99, blue: 1.0, alpha: 1),
            dark: UIColor(red: 0.12, green: 0.18, blue: 0.20, alpha: 1)
        ),
        guideArtworkStart: Color.adaptive(
            light: UIColor(red: 0.98, green: 0.99, blue: 1.0, alpha: 1),
            dark: UIColor(red: 0.11, green: 0.16, blue: 0.21, alpha: 1)
        ),
        guideArtworkEnd: Color.adaptive(
            light: UIColor(red: 0.93, green: 0.96, blue: 0.99, alpha: 1),
            dark: UIColor(red: 0.08, green: 0.12, blue: 0.17, alpha: 1)
        ),
        heroStart: Color.adaptive(
            light: UIColor(red: 0.08, green: 0.45, blue: 0.45, alpha: 0.96),
            dark: UIColor(red: 0.48, green: 0.87, blue: 0.84, alpha: 0.92)
        ),
        heroMid: Color.adaptive(
            light: UIColor(red: 0.14, green: 0.57, blue: 0.56, alpha: 1),
            dark: UIColor(red: 0.12, green: 0.26, blue: 0.28, alpha: 1)
        ),
        heroEnd: Color.adaptive(
            light: UIColor(red: 0.29, green: 0.66, blue: 0.63, alpha: 1),
            dark: UIColor(red: 0.09, green: 0.18, blue: 0.20, alpha: 1)
        ),
        success: Color.adaptive(
            light: UIColor(red: 0.12, green: 0.58, blue: 0.36, alpha: 1),
            dark: UIColor(red: 0.36, green: 0.78, blue: 0.58, alpha: 1)
        ),
        warning: Color.adaptive(
            light: UIColor(red: 0.83, green: 0.56, blue: 0.16, alpha: 1),
            dark: UIColor(red: 0.94, green: 0.74, blue: 0.34, alpha: 1)
        ),
        danger: Color.adaptive(
            light: UIColor(red: 0.79, green: 0.28, blue: 0.24, alpha: 1),
            dark: UIColor(red: 0.94, green: 0.53, blue: 0.47, alpha: 1)
        )
    )

    static let midnight = BrandPalette(
        background: Color(red: 0.04, green: 0.06, blue: 0.09),
        canvas: Color(red: 0.06, green: 0.09, blue: 0.12),
        guideCanvas: Color(red: 0.08, green: 0.11, blue: 0.15),
        surface: Color(red: 0.09, green: 0.13, blue: 0.17),
        surfaceTint: Color(red: 0.11, green: 0.16, blue: 0.21),
        line: Color(red: 0.22, green: 0.30, blue: 0.35),
        primary: Color(red: 0.44, green: 0.79, blue: 0.98),
        accent: Color(red: 0.24, green: 0.44, blue: 0.56),
        glow: Color(red: 0.32, green: 0.66, blue: 0.78),
        ink: Color(red: 0.92, green: 0.96, blue: 0.99),
        muted: Color(red: 0.64, green: 0.71, blue: 0.76),
        shadow: Color.black,
        speechBubble: Color(red: 0.10, green: 0.15, blue: 0.20),
        guideArtworkStart: Color(red: 0.10, green: 0.16, blue: 0.22),
        guideArtworkEnd: Color(red: 0.07, green: 0.11, blue: 0.16),
        heroStart: Color(red: 0.10, green: 0.36, blue: 0.52),
        heroMid: Color(red: 0.12, green: 0.25, blue: 0.37),
        heroEnd: Color(red: 0.09, green: 0.16, blue: 0.24),
        success: Color(red: 0.40, green: 0.79, blue: 0.62),
        warning: Color(red: 0.96, green: 0.74, blue: 0.40),
        danger: Color(red: 0.96, green: 0.54, blue: 0.49)
    )

    static let sunrise = BrandPalette(
        background: Color(red: 0.99, green: 0.95, blue: 0.92),
        canvas: Color(red: 1.00, green: 0.97, blue: 0.94),
        guideCanvas: Color(red: 1.00, green: 0.98, blue: 0.96),
        surface: Color.white,
        surfaceTint: Color(red: 1.00, green: 0.98, blue: 0.97),
        line: Color(red: 0.93, green: 0.85, blue: 0.80),
        primary: Color(red: 0.85, green: 0.43, blue: 0.33),
        accent: Color(red: 0.98, green: 0.78, blue: 0.60),
        glow: Color(red: 0.99, green: 0.87, blue: 0.72),
        ink: Color(red: 0.22, green: 0.17, blue: 0.16),
        muted: Color(red: 0.51, green: 0.42, blue: 0.39),
        shadow: Color(red: 0.20, green: 0.12, blue: 0.10),
        speechBubble: Color(red: 1.00, green: 0.99, blue: 0.98),
        guideArtworkStart: Color(red: 1.00, green: 0.97, blue: 0.95),
        guideArtworkEnd: Color(red: 0.99, green: 0.93, blue: 0.88),
        heroStart: Color(red: 0.92, green: 0.50, blue: 0.36),
        heroMid: Color(red: 0.96, green: 0.65, blue: 0.43),
        heroEnd: Color(red: 0.99, green: 0.79, blue: 0.58),
        success: Color(red: 0.22, green: 0.63, blue: 0.39),
        warning: Color(red: 0.90, green: 0.58, blue: 0.18),
        danger: Color(red: 0.84, green: 0.34, blue: 0.29)
    )
}

struct PrimaryCTAStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .background(
                LinearGradient(
                    colors: [
                        BrandTheme.primary.opacity(configuration.isPressed ? 0.9 : 1),
                        BrandTheme.glow.opacity(configuration.isPressed ? 0.78 : 0.88)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundStyle(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(configuration.isPressed ? 0.08 : 0.22), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .shadow(color: BrandTheme.primary.opacity(configuration.isPressed ? 0.12 : 0.22), radius: 18, x: 0, y: 10)
            .shadow(color: BrandTheme.shadow.opacity(configuration.isPressed ? 0.06 : 0.14), radius: 14, x: 0, y: 8)
    }
}

struct SecondaryCTAStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .background(
                LinearGradient(
                    colors: [
                        BrandTheme.surface.opacity(configuration.isPressed ? 0.9 : 0.98),
                        BrandTheme.surfaceTint.opacity(configuration.isPressed ? 0.88 : 0.96)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .foregroundStyle(BrandTheme.ink)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(BrandTheme.line.opacity(0.85), lineWidth: 1.2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: BrandTheme.shadow.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

struct AccessibilityProbe: View {
    let identifier: String

    var body: some View {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            Text(identifier)
                .font(.system(size: 1))
                .foregroundStyle(Color.white.opacity(0.01))
                .frame(width: 2, height: 2, alignment: .topLeading)
                .padding(.leading, 2)
                .padding(.top, 2)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .accessibilityIdentifier(identifier)
        }
    }
}

struct SurfaceCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                BrandTheme.surface,
                                BrandTheme.surfaceTint.opacity(0.78)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(1)
                    .allowsHitTesting(false)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(BrandTheme.line.opacity(0.7), lineWidth: 1)
                    .allowsHitTesting(false)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: BrandTheme.shadow.opacity(0.1), radius: 22, x: 0, y: 12)
    }
}
