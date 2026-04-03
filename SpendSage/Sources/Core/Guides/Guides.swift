import Foundation

enum GuideID: String, CaseIterable, Hashable {
    case dashboard
    case expenses
    case scan
    case insights
    case sharing
    case budgetWizard
}

struct GuideSlide: Identifiable, Hashable {
    let imageKey: String
    let character: BrandCharacterID
    let expression: BrandExpression
    let title: String
    let body: String

    var id: String {
        "\(imageKey)-\(character.rawValue)-\(expression.rawValue)"
    }
}

struct GuideDefinition: Identifiable, Hashable {
    let id: GuideID
    let title: String
    let slides: [GuideSlide]
}

enum GuideProgressStore {
    private static let prefix = "spendsage_guide_seen_"

    static func isSeen(_ id: GuideID, defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: key(for: id))
    }

    static func markSeen(_ id: GuideID, defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: key(for: id))
    }

    static func resetAll(defaults: UserDefaults = .standard) {
        GuideID.allCases.forEach { defaults.removeObject(forKey: key(for: $0)) }
    }

    private static func key(for id: GuideID) -> String {
        prefix + id.rawValue
    }
}

enum GuideLibrary {
    static let all: [GuideID: GuideDefinition] = [
        .dashboard: GuideDefinition(
            id: .dashboard,
            title: "Dashboard guide",
            slides: [
                GuideSlide(
                    imageKey: "guide_01_dashboard_game_manchas",
                    character: .manchas,
                    expression: .happy,
                    title: "Start from the daily score",
                    body: "Lead with the overview that matters most: current budget health, momentum, and the next action you can take in seconds."
                ),
                GuideSlide(
                    imageKey: "guide_03_budgets_tikki",
                    character: .tikki,
                    expression: .proud,
                    title: "Make budgets feel winnable",
                    body: "Frame budgets as clear progress bars and guardrails, not a wall of finance terms. The calm tone should still feel gameful."
                )
            ]
        ),
        .expenses: GuideDefinition(
            id: .expenses,
            title: "Expenses guide",
            slides: [
                GuideSlide(
                    imageKey: "guide_02_log_expense_manchas",
                    character: .manchas,
                    expression: .neutral,
                    title: "Logging should be friction-light",
                    body: "The expense flow should help users capture an amount, category, and moment fast, while still keeping the surface warm and understandable."
                ),
                GuideSlide(
                    imageKey: "guide_05_scan_receipt_mei",
                    character: .mei,
                    expression: .thinking,
                    title: "Keep scan connected to value",
                    body: "Receipt capture is a speed tool. Pair it with friendly copy and visual proof that the app will still let the user review before saving."
                )
            ]
        ),
        .scan: GuideDefinition(
            id: .scan,
            title: "Receipt scan guide",
            slides: [
                GuideSlide(
                    imageKey: "guide_05_scan_receipt_mei",
                    character: .mei,
                    expression: .thinking,
                    title: "Show what the camera helps with",
                    body: "Explain scan as assisted capture, not magic. The guide should build trust first, then speed."
                ),
                GuideSlide(
                    imageKey: "guide_02_log_expense_manchas",
                    character: .manchas,
                    expression: .confused,
                    title: "Fallback to manual is still success",
                    body: "If scan is unavailable or not perfect, the user should still feel supported with manual entry and review."
                )
            ]
        ),
        .insights: GuideDefinition(
            id: .insights,
            title: "Insights guide",
            slides: [
                GuideSlide(
                    imageKey: "guide_04_ai_insights_mei",
                    character: .mei,
                    expression: .thinking,
                    title: "Insights should feel grounded",
                    body: "Recommendations must read as practical money coaching. Calm visuals keep the AI layer from feeling too abstract or risky."
                ),
                GuideSlide(
                    imageKey: "guide_03_budgets_tikki",
                    character: .tikki,
                    expression: .thinking,
                    title: "Connect insight to next move",
                    body: "Every insight should point toward a decision, a budget adjustment, or a clear follow-up instead of just reporting numbers."
                )
            ]
        ),
        .sharing: GuideDefinition(
            id: .sharing,
            title: "Sharing guide",
            slides: [
                GuideSlide(
                    imageKey: "guide_06_sharing_family_manchas",
                    character: .manchas,
                    expression: .happy,
                    title: "Shared finance needs warmth",
                    body: "Family and partner money flows should feel cooperative and reassuring, with visuals that reduce tension around permissions and visibility."
                ),
                GuideSlide(
                    imageKey: "guide_01_dashboard_game_manchas",
                    character: .tikki,
                    expression: .love,
                    title: "Celebrate alignment, not complexity",
                    body: "Use badges, mascots, and progress framing to make collaboration feel rewarding without overwhelming users with controls up front."
                )
            ]
        ),
        .budgetWizard: GuideDefinition(
            id: .budgetWizard,
            title: "Budget wizard guide",
            slides: [
                GuideSlide(
                    imageKey: "guide_03_budgets_tikki",
                    character: .tikki,
                    expression: .proud,
                    title: "Break the wizard into confident steps",
                    body: "A budget wizard should feel like coaching: each step small enough to finish, each screen clear about what happens next."
                ),
                GuideSlide(
                    imageKey: "guide_04_ai_insights_mei",
                    character: .mei,
                    expression: .thinking,
                    title: "Review before commitment",
                    body: "Close with a strong review state so the user feels informed and in control before the budget becomes their default plan."
                )
            ]
        )
    ]

    static func guide(_ id: GuideID) -> GuideDefinition {
        guard let guide = all[id] else {
            preconditionFailure("Missing guide definition for \(id.rawValue)")
        }
        return guide
    }
}
