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
        if shouldForceHideGuides {
            return true
        }
        return defaults.bool(forKey: key(for: id))
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

    private static var shouldForceHideGuides: Bool {
        let value = ProcessInfo.processInfo.environment["SPENDSAGE_DEBUG_HIDE_GUIDES"]?.lowercased()
        return value == "1" || value == "true" || value == "yes" || value == "hide"
    }
}

enum GuideLibrary {
    static let all: [GuideID: GuideDefinition] = [
        .dashboard: GuideDefinition(
            id: .dashboard,
            title: "Guía de inicio",
            slides: [
                GuideSlide(
                    imageKey: "guide_01_dashboard_game_manchas",
                    character: .manchas,
                    expression: .happy,
                    title: "Empieza por el estado del día",
                    body: "Arranca con lo que más importa: salud actual del presupuesto, ritmo y el siguiente paso que puedes tomar en segundos."
                ),
                GuideSlide(
                    imageKey: "guide_03_budgets_tikki",
                    character: .tikki,
                    expression: .proud,
                    title: "Haz que el presupuesto se sienta ganable",
                    body: "Presenta el presupuesto como barras claras de progreso y límites sanos, no como una pared de términos financieros. El tono debe seguir siendo tranquilo y con aire de juego."
                )
            ]
        ),
        .expenses: GuideDefinition(
            id: .expenses,
            title: "Guía de gastos",
            slides: [
                GuideSlide(
                    imageKey: "guide_02_log_expense_manchas",
                    character: .manchas,
                    expression: .neutral,
                    title: "Registrar debe sentirse liviano",
                    body: "El flujo de gastos debe ayudar a capturar monto, categoría y momento rápido, sin dejar de sentirse cálido y fácil de entender."
                ),
                GuideSlide(
                    imageKey: "guide_05_scan_receipt_mei",
                    character: .mei,
                    expression: .thinking,
                    title: "Mantén el escaneo conectado al valor",
                    body: "Capturar recibos es una herramienta de velocidad. Acompáñala con copy amable y prueba visual de que la app siempre deja revisar antes de guardar."
                )
            ]
        ),
        .scan: GuideDefinition(
            id: .scan,
            title: "Guía de escaneo",
            slides: [
                GuideSlide(
                    imageKey: "guide_05_scan_receipt_mei",
                    character: .mei,
                    expression: .thinking,
                    title: "Muestra en qué ayuda la cámara",
                    body: "Explica el escaneo como captura asistida, no como magia. La guía debe construir confianza primero y velocidad después."
                ),
                GuideSlide(
                    imageKey: "guide_02_log_expense_manchas",
                    character: .manchas,
                    expression: .confused,
                    title: "Volver a manual también es éxito",
                    body: "Si el escaneo no está disponible o no sale perfecto, el usuario debe seguir sintiéndose acompañado con entrada manual y revisión."
                )
            ]
        ),
        .insights: GuideDefinition(
            id: .insights,
            title: "Guía de análisis",
            slides: [
                GuideSlide(
                    imageKey: "guide_04_ai_insights_mei",
                    character: .mei,
                    expression: .thinking,
                    title: "El análisis debe sentirse aterrizado",
                    body: "Las recomendaciones deben leerse como coaching financiero práctico. Los visuales tranquilos evitan que la capa de IA se sienta abstracta o riesgosa."
                ),
                GuideSlide(
                    imageKey: "guide_03_budgets_tikki",
                    character: .tikki,
                    expression: .thinking,
                    title: "Conecta el análisis con la siguiente acción",
                    body: "Cada insight debe apuntar a una decisión, un ajuste de presupuesto o un siguiente paso claro, no solo a reportar números."
                )
            ]
        ),
        .sharing: GuideDefinition(
            id: .sharing,
            title: "Guía de compartir",
            slides: [
                GuideSlide(
                    imageKey: "guide_06_sharing_family_manchas",
                    character: .manchas,
                    expression: .happy,
                    title: "Las finanzas compartidas necesitan calidez",
                    body: "Los flujos de dinero en familia o pareja deben sentirse cooperativos y tranquilos, con visuales que reduzcan tensión sobre permisos y visibilidad."
                ),
                GuideSlide(
                    imageKey: "guide_01_dashboard_game_manchas",
                    character: .tikki,
                    expression: .love,
                    title: "Celebra el alineamiento, no la complejidad",
                    body: "Usa badges, personajes y progreso para que colaborar se sienta gratificante sin abrumar al usuario con controles desde el inicio."
                )
            ]
        ),
        .budgetWizard: GuideDefinition(
            id: .budgetWizard,
            title: "Guía del asistente",
            slides: [
                GuideSlide(
                    imageKey: "guide_03_budgets_tikki",
                    character: .tikki,
                    expression: .proud,
                    title: "Divide el asistente en pasos seguros",
                    body: "Un asistente de presupuesto debe sentirse como coaching: cada paso lo bastante pequeño para terminarse y cada pantalla clara sobre qué sigue."
                ),
                GuideSlide(
                    imageKey: "guide_04_ai_insights_mei",
                    character: .mei,
                    expression: .thinking,
                    title: "Revisa antes de confirmar",
                    body: "Cierra con un buen estado de revisión para que el usuario se sienta informado y en control antes de que el presupuesto quede como plan por defecto."
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
