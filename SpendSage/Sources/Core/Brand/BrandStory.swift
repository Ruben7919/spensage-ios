import SwiftUI

enum AppSurfaceID: String, CaseIterable, Hashable {
    case onboarding
    case auth
    case dashboard
    case addExpense
    case expenses
    case insights
    case premium
    case settings
    case profile
    case support
    case help
    case legal
    case accounts
    case bills
    case rules
    case csvImport
    case receiptScan
    case budgetWizard
    case advancedSettings
    case brandGallery
}

struct BrandNarrativeSpec: Hashable {
    let character: BrandCharacterID
    let expression: BrandExpression
    let badgeText: String
    let roleTitle: String
    let roleSummary: String
    let sceneSource: BrandAssetSource?
    let scenePrompt: String?
}

@MainActor
enum BrandStoryCatalog {
    static func spec(for surface: AppSurfaceID) -> BrandNarrativeSpec {
        switch surface {
        case .onboarding:
            return BrandNarrativeSpec(
                character: .manchas,
                expression: .excited,
                badgeText: "First win in under a minute",
                roleTitle: "Manchas starts the game loop",
                roleSummary: "Use one friendly first win, then reveal the deeper tools only after the user feels in control.",
                sceneSource: guide(fileName: "guide_17_landing_hero_team_v2.png"),
                scenePrompt: nil
            )
        case .auth:
            return BrandNarrativeSpec(
                character: .mei,
                expression: .proud,
                badgeText: "Account checkpoint",
                roleTitle: "Ludo keeps sign-in calm",
                roleSummary: "Security should feel guided, short, and obvious, not like a setup wizard.",
                sceneSource: guide(fileName: "guide_18_landing_trust_shield_mei_v2.png"),
                scenePrompt: nil
            )
        case .dashboard:
            return BrandNarrativeSpec(
                character: .manchas,
                expression: .happy,
                badgeText: "Daily money loop",
                roleTitle: "Manchas leads daily momentum",
                roleSummary: "The home screen should answer three questions fast: how much is safe, what matters today, and what small win comes next.",
                sceneSource: guide(key: "guide_01_dashboard_game_manchas"),
                scenePrompt: nil
            )
        case .addExpense:
            return BrandNarrativeSpec(
                character: .manchas,
                expression: .excited,
                badgeText: "Quick capture",
                roleTitle: "Manchas keeps logging lightweight",
                roleSummary: "Expense entry should feel like a single move, not an accounting form.",
                sceneSource: guide(key: "guide_02_log_expense_manchas"),
                scenePrompt: nil
            )
        case .expenses:
            return BrandNarrativeSpec(
                character: .manchas,
                expression: .thinking,
                badgeText: "Clean local ledger",
                roleTitle: "Manchas organizes the month",
                roleSummary: "Show quick capture first, then summary, then detail. The user should never feel buried in tables.",
                sceneSource: guide(key: "guide_02_log_expense_manchas"),
                scenePrompt: nil
            )
        case .insights:
            return BrandNarrativeSpec(
                character: .mei,
                expression: .thinking,
                badgeText: "Simple insights",
                roleTitle: "Ludo translates the numbers",
                roleSummary: "Insights should explain what changed and what to do next without making the user read a report.",
                sceneSource: guide(key: "guide_04_ai_insights_mei"),
                scenePrompt: nil
            )
        case .premium:
            return BrandNarrativeSpec(
                character: .tikki,
                expression: .proud,
                badgeText: "Upgrade when it helps",
                roleTitle: "Tikki frames value without pressure",
                roleSummary: "Premium should feel trustworthy and useful, not noisy or aggressive.",
                sceneSource: guide(fileName: "guide_19_pricing_cards_tikki_v2.png"),
                scenePrompt: nil
            )
        case .settings:
            return BrandNarrativeSpec(
                character: .tikki,
                expression: .happy,
                badgeText: "Your control center",
                roleTitle: "Tikki keeps settings approachable",
                roleSummary: "Group the controls by real-life intent: app feel, reminders, and account or help paths.",
                sceneSource: guide(fileName: "guide_16_family_mission_board_team_v2.png"),
                scenePrompt: nil
            )
        case .profile:
            return BrandNarrativeSpec(
                character: .mei,
                expression: .proud,
                badgeText: "Local identity",
                roleTitle: "Ludo keeps your identity export-ready",
                roleSummary: "Profile should feel personal and trustworthy, with the local-storage boundary always obvious.",
                sceneSource: guide(key: "guide_21_profile_identity_ludo"),
                scenePrompt: nil
            )
        case .support:
            return BrandNarrativeSpec(
                character: .manchas,
                expression: .warning,
                badgeText: "Support-ready packet",
                roleTitle: "Manchas helps package the issue",
                roleSummary: "Support should reduce stress: explain the packet, show recent context, then offer one clean share path.",
                sceneSource: guide(fileName: "guide_18_landing_trust_shield_mei_v2.png"),
                scenePrompt: nil
            )
        case .help:
            return BrandNarrativeSpec(
                character: .mei,
                expression: .happy,
                badgeText: "Guided help",
                roleTitle: "Ludo answers the common questions",
                roleSummary: "Help should feel like a quick coach, not a policy archive.",
                sceneSource: guide(key: "guide_22_help_center_ludo"),
                scenePrompt: nil
            )
        case .legal:
            return BrandNarrativeSpec(
                character: .tikki,
                expression: .neutral,
                badgeText: "Trust center",
                roleTitle: "Tikki guards the trust layer",
                roleSummary: "Legal pages should feel calm and transparent, with privacy and support links immediately visible.",
                sceneSource: guide(fileName: "guide_18_landing_trust_shield_mei_v2.png"),
                scenePrompt: nil
            )
        case .accounts:
            return BrandNarrativeSpec(
                character: .tikki,
                expression: .proud,
                badgeText: "Local-first accounts",
                roleTitle: "Tikki maps the money buckets",
                roleSummary: "Accounts should explain cash position quickly and avoid spreadsheet energy.",
                sceneSource: guide(fileName: "guide_15_emergency_fund_shield_mei_v2.png"),
                scenePrompt: nil
            )
        case .bills:
            return BrandNarrativeSpec(
                character: .tikki,
                expression: .warning,
                badgeText: "Bill radar",
                roleTitle: "Tikki watches due dates",
                roleSummary: "Bills should surface the next risk clearly so the user can act without scanning the whole page.",
                sceneSource: guide(fileName: "guide_14_bill_radar_tikki_v2.png"),
                scenePrompt: nil
            )
        case .rules:
            return BrandNarrativeSpec(
                character: .mei,
                expression: .thinking,
                badgeText: "Auto-categorization",
                roleTitle: "Ludo keeps repeated merchants tidy",
                roleSummary: "Rules should feel like a small automation layer, not a power-user DSL.",
                sceneSource: guide(key: "guide_23_rules_automation_ludo"),
                scenePrompt: nil
            )
        case .csvImport:
            return BrandNarrativeSpec(
                character: .mei,
                expression: .excited,
                badgeText: "Paste and import",
                roleTitle: "Ludo cleans the import path",
                roleSummary: "Import should reassure the user that the preview is safe before anything lands in the ledger.",
                sceneSource: guide(key: "guide_05_scan_receipt_mei"),
                scenePrompt: nil
            )
        case .receiptScan:
            return BrandNarrativeSpec(
                character: .mei,
                expression: .excited,
                badgeText: "Capture flow",
                roleTitle: "Ludo reviews the receipt draft",
                roleSummary: "Scanning should feel guided and forgiving, with one image and one clean draft at a time.",
                sceneSource: guide(key: "guide_05_scan_receipt_mei"),
                scenePrompt: nil
            )
        case .budgetWizard:
            return BrandNarrativeSpec(
                character: .tikki,
                expression: .proud,
                badgeText: "3-step setup",
                roleTitle: "Tikki keeps the budget clear",
                roleSummary: "Budgeting should feel like a short mission with one outcome: a realistic safe-to-spend number.",
                sceneSource: guide(fileName: "guide_11_budget_wizard_steps_mei_v2.png"),
                scenePrompt: nil
            )
        case .advancedSettings:
            return BrandNarrativeSpec(
                character: .manchas,
                expression: .thinking,
                badgeText: "Control center",
                roleTitle: "Manchas exposes the advanced tools carefully",
                roleSummary: "Advanced settings should stay available but visually separate from the everyday app controls.",
                sceneSource: guide(key: "guide_24_advanced_tools_manchas"),
                scenePrompt: nil
            )
        case .brandGallery:
            return BrandNarrativeSpec(
                character: .tikki,
                expression: .proud,
                badgeText: "Brand system",
                roleTitle: "The team keeps the product language consistent",
                roleSummary: "Brand assets, badges, and scenes should feel like one coherent game universe.",
                sceneSource: guide(fileName: "guide_17_landing_hero_team_v2.png"),
                scenePrompt: nil
            )
        }
    }

    private static func guide(key: String) -> BrandAssetSource? {
        BrandAssetCatalog.shared.guideIfAvailable(key)
    }

    private static func guide(fileName: String) -> BrandAssetSource? {
        let source = BrandAssetCatalog.shared.guide(fileName: fileName)
        return BrandAssetCatalog.shared.url(for: source) == nil ? nil : source
    }
}
