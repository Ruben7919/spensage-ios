import Foundation
import SwiftUI

struct GrowthMissionEvaluationContext {
    let transactionCount: Int
    let streakDays: Int
    let uniqueExpenseDays: Int
    let accounts: Int
    let bills: Int
    let rules: Int
    let budgetHealthy: Bool
    let seasonalTransactionCount: Int
    let seasonalUniqueDayCount: Int
}

enum GrowthMissionObjective: Hashable {
    case transactionCount(Int)
    case streakDays(Int)
    case uniqueExpenseDays(Int)
    case accounts(Int)
    case bills(Int)
    case rules(Int)
    case budgetHealthy
    case seasonalTransactionCount(Int)
    case seasonalUniqueDayCount(Int)

    func progress(in context: GrowthMissionEvaluationContext) -> (value: Int, target: Int) {
        switch self {
        case let .transactionCount(target):
            return (context.transactionCount, target)
        case let .streakDays(target):
            return (context.streakDays, target)
        case let .uniqueExpenseDays(target):
            return (context.uniqueExpenseDays, target)
        case let .accounts(target):
            return (context.accounts, target)
        case let .bills(target):
            return (context.bills, target)
        case let .rules(target):
            return (context.rules, target)
        case .budgetHealthy:
            return (context.budgetHealthy ? 1 : 0, 1)
        case let .seasonalTransactionCount(target):
            return (context.seasonalTransactionCount, target)
        case let .seasonalUniqueDayCount(target):
            return (context.seasonalUniqueDayCount, target)
        }
    }
}

struct GrowthMissionBlueprint: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let coachNote: String
    let cadenceLabel: String
    let rewardXP: Int
    let systemImage: String
    let badgeAsset: String
    let seasonID: BrandSeasonID?
    let objective: GrowthMissionObjective
    let readyThreshold: Int?
    let displayPriority: Int

    func evaluate(in context: GrowthMissionEvaluationContext) -> GrowthMission {
        let progress = objective.progress(in: context)
        let status: GrowthMission.Status

        if progress.value >= progress.target {
            status = .completed
        } else if let readyThreshold, progress.value >= readyThreshold {
            status = .ready
        } else {
            status = .pending
        }

        return GrowthMission(
            id: id,
            title: title,
            detail: detail,
            coachNote: coachNote,
            cadenceLabel: cadenceLabel,
            rewardXP: rewardXP,
            systemImage: systemImage,
            hybridBadgeAsset: badgeAsset,
            progressValue: progress.value,
            progressTarget: progress.target,
            status: status,
            seasonID: seasonID
        )
    }
}

enum GrowthMissionCatalog {
    static let coreBlueprints: [GrowthMissionBlueprint] = [
        GrowthMissionBlueprint(
            id: "ledger-momentum",
            title: "Registra cinco gastos".appLocalized,
            detail: "Crea suficiente actividad para que el coach tome mejores decisiones y arranque el progreso de logros.".appLocalized,
            coachNote: "Pequeñas tandas de registros limpios valen más que una sola sesión larga para ponerte al día.".appLocalized,
            cadenceLabel: "Diaria".appLocalized,
            rewardXP: 80,
            systemImage: "square.and.pencil.circle.fill",
            badgeAsset: "badge_quest_daily_v2.png",
            seasonID: nil,
            objective: .transactionCount(5),
            readyThreshold: 3,
            displayPriority: 0
        ),
        GrowthMissionBlueprint(
            id: "streak-keeper",
            title: "Protege una racha de tres días".appLocalized,
            detail: "Los días activos consecutivos convierten el dashboard de estático a predictivo.".appLocalized,
            coachNote: "Una racha no es más que repetición hecha visible.".appLocalized,
            cadenceLabel: "Semanal".appLocalized,
            rewardXP: 110,
            systemImage: "flame.fill",
            badgeAsset: "badge_streak_v2.png",
            seasonID: nil,
            objective: .streakDays(3),
            readyThreshold: 2,
            displayPriority: 1
        ),
        GrowthMissionBlueprint(
            id: "account-map",
            title: "Agrega dos bolsillos o cuentas".appLocalized,
            detail: "Efectivo, ahorro y tarjetas hacen que el dashboard se sienta como una cabina real.".appLocalized,
            coachNote: "Una cuenta extra suele desbloquear la lectura más clara del patrimonio.".appLocalized,
            cadenceLabel: "Semanal".appLocalized,
            rewardXP: 90,
            systemImage: "building.columns.fill",
            badgeAsset: "badge_safe_to_spend_v2.png",
            seasonID: nil,
            objective: .accounts(2),
            readyThreshold: 1,
            displayPriority: 2
        ),
        GrowthMissionBlueprint(
            id: "bill-radar",
            title: "Activa el radar de facturas".appLocalized,
            detail: "Registra al menos una factura recurrente para que el dashboard pueda avisar presión futura.".appLocalized,
            coachNote: "Los meses más tranquilos son los que dejan de recibir obligaciones como sorpresas.".appLocalized,
            cadenceLabel: "Jefe".appLocalized,
            rewardXP: 120,
            systemImage: "calendar.badge.clock",
            badgeAsset: "badge_bill_radar_v2.png",
            seasonID: nil,
            objective: .bills(1),
            readyThreshold: nil,
            displayPriority: 3
        ),
        GrowthMissionBlueprint(
            id: "rule-architect",
            title: "Crea una regla inteligente".appLocalized,
            detail: "Haz que los comercios recurrentes caigan solos en la categoría correcta.".appLocalized,
            coachNote: "Las reglas quitan fricción a cada gasto futuro.".appLocalized,
            cadenceLabel: "Jefe".appLocalized,
            rewardXP: 120,
            systemImage: "point.3.filled.connected.trianglepath.dotted",
            badgeAsset: "badge_smart_spend_v2.png",
            seasonID: nil,
            objective: .rules(1),
            readyThreshold: nil,
            displayPriority: 4
        ),
        GrowthMissionBlueprint(
            id: "budget-guardian",
            title: "Mantén el mes dentro del presupuesto".appLocalized,
            detail: "Mantente debajo del plan mensual actual hasta la siguiente revisión.".appLocalized,
            coachNote: "Si el dashboard sigue en verde, tus próximas decisiones se vuelven más fáciles.".appLocalized,
            cadenceLabel: "Mensual".appLocalized,
            rewardXP: 140,
            systemImage: "shield.lefthalf.filled",
            badgeAsset: "badge_budgeting_v2.png",
            seasonID: nil,
            objective: .budgetHealthy,
            readyThreshold: nil,
            displayPriority: 5
        )
    ]

    static let seasonalBlueprints: [BrandSeasonID: [GrowthMissionBlueprint]] = [
        .halloween: [
            GrowthMissionBlueprint(
                id: "halloween-night-watch",
                title: "Racha de guardia nocturna".appLocalized,
                detail: "Mantente activo en cuatro días distintos del evento de Halloween para que el gasto impulsivo no se cuele.".appLocalized,
                coachNote: "Pequeños chequeos ganan frente a una limpieza gigante después del apuro de dulces y disfraces.".appLocalized,
                cadenceLabel: "Evento".appLocalized,
                rewardXP: 160,
                systemImage: "moon.stars.fill",
                badgeAsset: "badge_event_halloween_v2.png",
                seasonID: .halloween,
                objective: .seasonalUniqueDayCount(4),
                readyThreshold: 3,
                displayPriority: 0
            ),
            GrowthMissionBlueprint(
                id: "halloween-loot-log",
                title: "Registra seis compras espeluznantes".appLocalized,
                detail: "Captura los extras de temporada antes de que se mezclen con el total mensual.".appLocalized,
                coachNote: "El gasto de evento solo da miedo cuando se queda invisible.".appLocalized,
                cadenceLabel: "Evento".appLocalized,
                rewardXP: 140,
                systemImage: "sparkles",
                badgeAsset: "badge_event_halloween_v2.png",
                seasonID: .halloween,
                objective: .seasonalTransactionCount(6),
                readyThreshold: 4,
                displayPriority: 1
            )
        ],
        .winterHolidays: [
            GrowthMissionBlueprint(
                id: "holiday-gift-guard",
                title: "Protege el presupuesto de regalos".appLocalized,
                detail: "Mantén el mes dentro del plan mientras el pack festivo esté activo.".appLocalized,
                coachNote: "Un límite visible hace que el gasto generoso se sienta claro y tranquilo.".appLocalized,
                cadenceLabel: "Evento".appLocalized,
                rewardXP: 180,
                systemImage: "gift.fill",
                badgeAsset: "badge_event_holiday_v2.png",
                seasonID: .winterHolidays,
                objective: .budgetHealthy,
                readyThreshold: nil,
                displayPriority: 0
            ),
            GrowthMissionBlueprint(
                id: "holiday-wrap-up",
                title: "Registra cinco momentos festivos".appLocalized,
                detail: "Sigue viajes, regalos y gastos de reuniones mientras el pack navideño esté activo.".appLocalized,
                coachNote: "Las capturas pequeñas evitan que diciembre se vuelva un total misterioso.".appLocalized,
                cadenceLabel: "Evento".appLocalized,
                rewardXP: 145,
                systemImage: "sparkles.rectangle.stack.fill",
                badgeAsset: "badge_event_holiday_v2.png",
                seasonID: .winterHolidays,
                objective: .seasonalTransactionCount(5),
                readyThreshold: 3,
                displayPriority: 1
            )
        ],
        .newYear: [
            GrowthMissionBlueprint(
                id: "new-year-fresh-ledger",
                title: "Reinicio limpio del libro".appLocalized,
                detail: "Registra tres movimientos de enero para que el año arranque con visibilidad real en vez de adivinanza.".appLocalized,
                coachNote: "El reinicio más limpio es una primera semana corta, no una hoja perfecta.".appLocalized,
                cadenceLabel: "Evento".appLocalized,
                rewardXP: 150,
                systemImage: "sparkles",
                badgeAsset: "badge_event_new_year_v2.png",
                seasonID: .newYear,
                objective: .seasonalTransactionCount(3),
                readyThreshold: 2,
                displayPriority: 0
            ),
            GrowthMissionBlueprint(
                id: "new-year-cleanup",
                title: "Reinicia con dos días activos".appLocalized,
                detail: "Dos días separados de limpieza bastan para despertar de nuevo al coach este año.".appLocalized,
                coachNote: "El impulso suele volver más rápido que la motivación cuando los dos primeros días ya son visibles.".appLocalized,
                cadenceLabel: "Evento".appLocalized,
                rewardXP: 120,
                systemImage: "sun.max.fill",
                badgeAsset: "badge_event_new_year_v2.png",
                seasonID: .newYear,
                objective: .seasonalUniqueDayCount(2),
                readyThreshold: nil,
                displayPriority: 1
            )
        ]
    ]

    static func activeBlueprints(for activeSeason: BrandSeasonDefinition?) -> [GrowthMissionBlueprint] {
        guard let activeSeason else { return [] }
        return seasonalBlueprints[activeSeason.id] ?? []
    }
}

struct GrowthMission: Identifiable, Equatable {
    enum Status: String {
        case pending = "Pending"
        case ready = "Ready"
        case completed = "Completed"

        var localizedTitle: String {
            rawValue.appLocalized
        }
    }

    let id: String
    let title: String
    let detail: String
    let coachNote: String
    let cadenceLabel: String
    let rewardXP: Int
    let systemImage: String
    let hybridBadgeAsset: String
    let progressValue: Int
    let progressTarget: Int
    let status: Status
    let seasonID: BrandSeasonID?

    var progressRatio: Double {
        guard progressTarget > 0 else { return 0 }
        return min(1, max(0, Double(progressValue) / Double(progressTarget)))
    }

    var progressText: String {
        "\(min(progressValue, progressTarget))/\(progressTarget)"
    }

    var isSeasonal: Bool {
        seasonID != nil
    }
}

struct GrowthTrophy: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let celebration: String
    let systemImage: String
    let hybridBadgeAsset: String
    let progressValue: Int
    let progressTarget: Int
    let unlocked: Bool
    let unlockedAt: Date?

    var progressRatio: Double {
        guard progressTarget > 0 else { return 0 }
        return min(1, max(0, Double(progressValue) / Double(progressTarget)))
    }

    var progressText: String {
        if unlocked {
            return "Desbloqueado".appLocalized
        }
        return "\(min(progressValue, progressTarget))/\(progressTarget)"
    }
}

struct GrowthEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let occurredAt: Date
    let systemImage: String
}

struct GrowthLiveEvent: Equatable {
    let title: String
    let detail: String
    let badgeText: String
    let badgeAsset: String
    let sceneKey: String
    let isActive: Bool
    let dateLabel: String
}

struct DashboardSavingsStrategy: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let footnote: String
    let badgeText: String
    let badgeSystemImage: String
    let systemImage: String
}

struct DashboardGrowthSnapshot: Equatable {
    enum RiskState {
        case calm
        case watch
        case urgent

        var label: String {
            switch self {
            case .calm: return "Stable".appLocalized
            case .watch: return "Watchlist".appLocalized
            case .urgent: return "Recovery mode".appLocalized
            }
        }

        var tint: Color {
            switch self {
            case .calm: return BrandTheme.primary
            case .watch: return Color(red: 0.78, green: 0.53, blue: 0.16)
            case .urgent: return Color(red: 0.76, green: 0.28, blue: 0.23)
            }
        }

        var fill: Color {
            tint.opacity(0.16)
        }
    }

    let greetingTitle: String
    let greetingBody: String
    let heroTitle: String
    let heroBody: String
    let coachTitle: String
    let coachBody: String
    let coachAction: String
    let streakDays: Int
    let totalXP: Int
    let level: Int
    let xpToNextLevel: Int
    let levelProgress: Double
    let riskState: RiskState
    let strategies: [DashboardSavingsStrategy]
    let allMissions: [GrowthMission]
    let missions: [GrowthMission]
    let seasonalMissions: [GrowthMission]
    let trophies: [GrowthTrophy]
    let highlightedTrophies: [GrowthTrophy]
    let events: [GrowthEvent]
    let liveEvent: GrowthLiveEvent?
}

enum GrowthSnapshotBuilder {
    static let liveEventPreviewLeadDays = 21

    static func build(
        session: SessionState,
        state: FinanceDashboardState?,
        ledger: LocalFinanceLedger?,
        accounts: [AccountRecord],
        bills: [BillRecord],
        rules: [RuleRecord],
        profile: ProfileRecord
    ) -> DashboardGrowthSnapshot {
        let expenses = ledger?.expenses ?? []
        let uniqueDays = uniqueExpenseDays(in: expenses)
        let streakDays = activeStreak(from: uniqueDays)
        let transactionCount = state?.transactionCount ?? expenses.count
        let activeSeason = BrandSeasonCatalog.activeSeason()
        let seasonalExpenses = expenses.filter { expense in
            guard let activeSeason else { return false }
            return BrandSeasonCatalog.contains(expense.date, in: activeSeason)
        }
        let seasonalUniqueDays = uniqueExpenseDays(in: seasonalExpenses)
        let utilization = state?.utilizationRatio ?? 0
        let isBudgetHealthy = transactionCount > 0 && utilization <= 1
        let profileCustomized = profile != .default
        let riskState: DashboardGrowthSnapshot.RiskState
        let persistedProgress = GrowthProgressStore.load()

        if transactionCount == 0 || utilization < 0.82 {
            riskState = .calm
        } else if utilization < 1 {
            riskState = .watch
        } else {
            riskState = .urgent
        }

        let allMissions = buildAllMissions(
            context: GrowthMissionEvaluationContext(
                transactionCount: transactionCount,
                streakDays: streakDays,
                uniqueExpenseDays: uniqueDays.count,
                accounts: accounts.count,
                bills: bills.count,
                rules: rules.count,
                budgetHealthy: isBudgetHealthy,
                seasonalTransactionCount: seasonalExpenses.count,
                seasonalUniqueDayCount: seasonalUniqueDays.count
            ),
            activeSeason: activeSeason
        )

        let baseXP =
            transactionCount * 24 +
            uniqueDays.count * 18 +
            accounts.count * 32 +
            bills.count * 34 +
            rules.count * 30 +
            (isBudgetHealthy ? 42 : 0) +
            (profileCustomized ? 18 : 0)
        let missionXPBonus = persistedProgress.completedMissions.values.reduce(0) { $0 + $1.rewardXP } +
            allMissions
                .filter { $0.status == .completed && persistedProgress.completedMissions[$0.id] == nil }
                .reduce(0) { $0 + $1.rewardXP }
        let totalXP = baseXP + missionXPBonus
        let level = max(1, (totalXP / 150) + 1)
        let currentThreshold = max(0, (level - 1) * 150)
        let nextThreshold = level * 150
        let xpToNextLevel = max(0, nextThreshold - totalXP)
        let levelProgressDenominator = max(1, nextThreshold - currentThreshold)
        let levelProgress = Double(totalXP - currentThreshold) / Double(levelProgressDenominator)

        let greetingTitle: String
        switch session {
        case .guest:
            greetingTitle = "Tu loop local de progreso".appLocalized
        case let .signedIn(email, provider):
            let handle = email
                .components(separatedBy: "@")
                .first?
                .replacingOccurrences(of: ".", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if provider == "Preview" || handle?.lowercased() == "preview" {
                greetingTitle = "Bienvenido de nuevo".appLocalized
            } else {
                let displayName = handle?.isEmpty == false ? handle! : email
                greetingTitle = AppLocalization.localized("Bienvenido de nuevo, %@", arguments: displayName)
            }
        case .signedOut:
            greetingTitle = "Inicio".appLocalized
        }

        let heroTitle: String
        let heroBody: String
        if transactionCount == 0 {
            heroTitle = "Empieza la primera misión".appLocalized
            heroBody = "Registra un gasto para despertar las recomendaciones del coach, el progreso de misiones y el impulso de logros.".appLocalized
        } else if riskState == .urgent {
            heroTitle = "Ajusta el mes antes de que se descontrole".appLocalized
            heroBody = "El gasto va por encima del ritmo actual del presupuesto. Enfócate en la categoría principal y asegura hoy una acción de limpieza.".appLocalized
        } else if riskState == .watch {
            heroTitle = "Todavía tienes margen para girar".appLocalized
            heroBody = "El mes se está calentando, pero una regla, una revisión de facturas o un recorte en una categoría mantiene el dashboard en control.".appLocalized
        } else {
            heroTitle = "El impulso se está acumulando".appLocalized
            heroBody = "Tu libro local ya está lo bastante limpio para que el coaching, las misiones y el progreso de logros se sientan intencionales.".appLocalized
        }

        let topCategoryName = state?.topCategory?.category.localizedTitle ?? "tu categoría principal".appLocalized
        let coachTitle: String
        let coachBody: String
        let coachAction: String
        if transactionCount == 0 {
            coachTitle = "Coach: captura la primera victoria".appLocalized
            coachBody = "El dashboard está listo, pero necesita un gasto real antes de poder acompañar patrones.".appLocalized
            coachAction = "Agrega un gasto hoy.".appLocalized
        } else if utilization >= 1 {
            coachTitle = "Coach: rescata la pista del mes".appLocalized
            coachBody = AppLocalization.localized(
                "El alivio más rápido casi siempre está escondido dentro de %@. Recorta una compra o mueve una factura antes de que cierre la semana.",
                arguments: topCategoryName.lowercased()
            )
            coachAction = "Protege caja antes de abrir una nueva categoría.".appLocalized
        } else if rules.isEmpty && transactionCount >= 3 {
            coachTitle = "Coach: automatiza el ruido repetido".appLocalized
            coachBody = "Ya tienes suficientes transacciones para una regla por comercio. Convierte la repetición en datos más limpios por categoría.".appLocalized
            coachAction = "Crea una regla para el comercio que más repites.".appLocalized
        } else if accounts.count < 2 {
            coachTitle = "Coach: amplía el mapa financiero".appLocalized
            coachBody = "El dashboard ya lee bien el gasto, pero se vuelve más inteligente cuando ahorro o efectivo también forman parte de la historia.".appLocalized
            coachAction = "Agrega un bolsillo o cuenta más.".appLocalized
        } else if bills.isEmpty {
            coachTitle = "Coach: haz visibles las obligaciones futuras".appLocalized
            coachBody = "Las facturas recurrentes siguen invisibles para el dashboard. Agrega la próxima obligación para que el coach la vea a tiempo.".appLocalized
            coachAction = "Configura tu primera factura recurrente.".appLocalized
        } else {
            coachTitle = "Coach: mantén el ritmo predecible".appLocalized
            coachBody = "Ya tienes las piezas de un loop local fuerte. Ahora la victoria es consistencia: chequeos cortos, categorías limpias y menos sorpresas.".appLocalized
            coachAction = "Protege la racha con una revisión rápida esta noche.".appLocalized
        }

        let strategies = buildStrategies(
            state: state,
            ledger: ledger,
            rules: rules
        )

        let trophies = buildTrophies(
            state: state,
            ledger: ledger,
            streakDays: streakDays,
            uniqueDayCount: uniqueDays.count,
            accounts: accounts.count,
            bills: bills.count,
            rules: rules.count,
            level: level,
            budgetHealthy: isBudgetHealthy,
            profileCustomized: profileCustomized
        )
        let syncedProgress = GrowthProgressStore.sync(trophies: trophies, missions: allMissions)
        let finalizedAllMissions = applyPersistedProgress(syncedProgress, to: allMissions)
        let finalizedTrophies = applyPersistedProgress(syncedProgress, to: trophies)
        let missions = visibleMissions(from: finalizedAllMissions, activeSeason: activeSeason)
        let events = buildEvents(
            state: state,
            ledger: ledger,
            trophies: finalizedTrophies,
            coachAction: coachAction,
            riskState: riskState,
            activeSeason: activeSeason
        )
        let liveEvent = buildLiveEvent(activeSeason: activeSeason)

        return DashboardGrowthSnapshot(
            greetingTitle: greetingTitle,
            greetingBody: session == .guest
                ? "Todo aquí se genera a partir del libro guardado en este dispositivo.".appLocalized
                : "Tu inicio mezcla salud del presupuesto, misiones, sugerencias del coach y momentum de logros.".appLocalized,
            heroTitle: heroTitle,
            heroBody: heroBody,
            coachTitle: coachTitle,
            coachBody: coachBody,
            coachAction: coachAction,
            streakDays: streakDays,
            totalXP: totalXP,
            level: level,
            xpToNextLevel: xpToNextLevel,
            levelProgress: levelProgress,
            riskState: riskState,
            strategies: strategies,
            allMissions: finalizedAllMissions,
            missions: missions,
            seasonalMissions: missions.filter(\.isSeasonal),
            trophies: finalizedTrophies,
            highlightedTrophies: Array(finalizedTrophies.filter(\.unlocked).sorted { lhs, rhs in
                (syncedProgress.trophyUnlockDates[lhs.id] ?? .distantPast) > (syncedProgress.trophyUnlockDates[rhs.id] ?? .distantPast)
            }.prefix(3)),
            events: Array(events.prefix(6)),
            liveEvent: liveEvent
        )
    }

    private static func applyPersistedProgress(_ progress: GrowthProgressState, to missions: [GrowthMission]) -> [GrowthMission] {
        missions.map { mission in
            guard progress.completedMissions[mission.id] != nil else { return mission }
            return GrowthMission(
                id: mission.id,
                title: mission.title,
                detail: mission.detail,
                coachNote: mission.coachNote,
                cadenceLabel: mission.cadenceLabel,
                rewardXP: mission.rewardXP,
                systemImage: mission.systemImage,
                hybridBadgeAsset: mission.hybridBadgeAsset,
                progressValue: mission.progressTarget,
                progressTarget: mission.progressTarget,
                status: .completed,
                seasonID: mission.seasonID
            )
        }
    }

    private static func applyPersistedProgress(_ progress: GrowthProgressState, to trophies: [GrowthTrophy]) -> [GrowthTrophy] {
        trophies.map { trophy in
            guard let unlockedAt = progress.trophyUnlockDates[trophy.id] else { return trophy }
            return GrowthTrophy(
                id: trophy.id,
                title: trophy.title,
                detail: trophy.detail,
                celebration: trophy.celebration,
                systemImage: trophy.systemImage,
                hybridBadgeAsset: trophy.hybridBadgeAsset,
                progressValue: trophy.progressValue,
                progressTarget: trophy.progressTarget,
                unlocked: true,
                unlockedAt: unlockedAt
            )
        }
    }

    private static func buildAllMissions(
        context: GrowthMissionEvaluationContext,
        activeSeason: BrandSeasonDefinition?
    ) -> [GrowthMission] {
        let coreMissions = GrowthMissionCatalog.coreBlueprints.map { $0.evaluate(in: context) }
        let seasonalMissions = GrowthMissionCatalog
            .activeBlueprints(for: activeSeason)
            .map { $0.evaluate(in: context) }

        return (seasonalMissions + coreMissions)
            .sorted { lhs, rhs in
                if lhs.isSeasonal != rhs.isSeasonal {
                    return lhs.isSeasonal && !rhs.isSeasonal
                }
                if lhs.status != rhs.status {
                    return lhs.status.sortRank < rhs.status.sortRank
                }
                let lhsPriority = missionDisplayPriority(for: lhs.id, seasonID: lhs.seasonID)
                let rhsPriority = missionDisplayPriority(for: rhs.id, seasonID: rhs.seasonID)
                if lhsPriority != rhsPriority {
                    return lhsPriority < rhsPriority
                }
                return lhs.progressRatio > rhs.progressRatio
            }
    }

    private static func visibleMissions(
        from missions: [GrowthMission],
        activeSeason: BrandSeasonDefinition?
    ) -> [GrowthMission] {
        Array(missions.prefix(activeSeason == nil ? 4 : 5))
    }

    private static func buildStrategies(
        state: FinanceDashboardState?,
        ledger: LocalFinanceLedger?,
        rules: [RuleRecord]
    ) -> [DashboardSavingsStrategy] {
        guard let state else {
            return []
        }

        let currencyCode = AppCurrencyFormat.currentCode()
        let weeklySafeToSpend = safeToSpendWeek(for: state.budgetSnapshot.remaining, daysLeft: state.remainingDaysInMonth)
        let hotspot = ledger?.discretionaryHotspots(limit: 1).first
        let topMerchant = ledger?.merchantSuggestions(limit: 1).first
        var candidates: [(priority: Int, strategy: DashboardSavingsStrategy)] = []

        if state.transactionCount == 0 {
            candidates.append(
                (
                    0,
                    DashboardSavingsStrategy(
                        id: "seed-ledger",
                        title: "Dale señal al coach con tres gastos reales".appLocalized,
                        detail: "Registra supermercado, transporte y una compra flexible para que la app empiece a detectar patrones en vez de adivinar.".appLocalized,
                        footnote: "Las primeras sugerencias de ahorro se vuelven más confiables apenas el libro local tiene algunas categorías para comparar.".appLocalized,
                        badgeText: "3 registros".appLocalized,
                        badgeSystemImage: "sparkles",
                        systemImage: "square.and.pencil.circle.fill"
                    )
                )
            )
            return candidates.map(\.strategy)
        }

        if let topCategory = state.topCategory {
            let categoryShare = share(of: topCategory.total, in: state.budgetSnapshot.monthlySpent)
            if state.utilizationRatio >= 0.82 || categoryShare >= 0.34 {
                let suggestedTrim = suggestedTrimAmount(
                    averageExpense: state.averageExpense,
                    topCategoryTotal: topCategory.total,
                    hotspotAverage: hotspot?.averageAmount
                )
                let shareLabel = percentLabel(for: categoryShare)
                let title = state.utilizationRatio >= 1
                    ? AppLocalization.localized("Recorta %@ primero", arguments: topCategory.category.localizedTitle)
                    : AppLocalization.localized("Ponle tope a %@ esta semana", arguments: topCategory.category.localizedTitle)

                candidates.append(
                    (
                        state.utilizationRatio >= 1 ? 0 : 1,
                        DashboardSavingsStrategy(
                            id: "top-category-\(topCategory.id)",
                            title: title,
                            detail: AppLocalization.localized(
                                "%@ ya representa %@ del gasto mensual. Una semana más ligera ahí protege todo el plan más rápido que recortar en todas partes.",
                                arguments: topCategory.category.localizedTitle,
                                shareLabel
                            ),
                            footnote: AppLocalization.localized(
                                "%d transacción%@ ya están concentradas en %@.",
                                arguments: topCategory.count,
                                topCategory.count == 1 ? "" : "es",
                                topCategory.category.localizedTitle.lowercased()
                            ),
                            badgeText: AppLocalization.localized("Guarda %@", arguments: suggestedTrim.formatted(.currency(code: currencyCode))),
                            badgeSystemImage: state.utilizationRatio >= 1 ? "shield.fill" : "leaf.fill",
                            systemImage: topCategory.category.symbolName
                        )
                    )
                )
            }
        }

        if let hotspot {
            candidates.append(
                (
                    state.utilizationRatio >= 1 ? 1 : 0,
                    DashboardSavingsStrategy(
                        id: "merchant-hotspot-\(hotspot.id)",
                        title: AppLocalization.localized("Pausa %@ una vez", arguments: hotspot.merchant),
                        detail: AppLocalization.localized(
                            "%@ apareció %@ por %@ este mes. Saltarte una visita compra aire de inmediato.",
                            arguments: hotspot.merchant,
                            hotspot.frequencyLabel,
                            hotspot.totalAmount.formatted(.currency(code: currencyCode))
                        ),
                        footnote: AppLocalization.localized(
                            "El ticket promedio ahí es %@, así que una sola pausa ya cambia el ritmo semanal.",
                            arguments: hotspot.averageAmount.formatted(.currency(code: currencyCode))
                        ),
                        badgeText: AppLocalization.localized("Guarda %@", arguments: hotspot.averageAmount.formatted(.currency(code: currencyCode))),
                        badgeSystemImage: "pause.circle.fill",
                        systemImage: hotspot.category.symbolName
                    )
                )
            )
        }

        if state.budgetSnapshot.remaining > 0 {
            let reserveAmount = suggestedReserveAmount(
                income: state.budgetSnapshot.monthlyIncome,
                remaining: state.budgetSnapshot.remaining
            )
            if reserveAmount >= 5 {
                let adjustedWeekly = safeToSpendWeek(
                    for: state.budgetSnapshot.remaining - reserveAmount,
                    daysLeft: state.remainingDaysInMonth
                )
                candidates.append(
                    (
                        state.utilizationRatio >= 1 ? 3 : 1,
                        DashboardSavingsStrategy(
                            id: "reserve-buffer",
                            title: "Aparta un colchón de ahorro ahora".appLocalized,
                            detail: AppLocalization.localized(
                                "Aparta %@ antes de que el resto del mes lo absorba dentro del gasto diario.",
                                arguments: reserveAmount.formatted(.currency(code: currencyCode))
                            ),
                            footnote: AppLocalization.localized(
                                "%@ todavía se mantiene seguro para los próximos 7 días después de ese movimiento.",
                                arguments: adjustedWeekly.formatted(.currency(code: currencyCode))
                            ),
                            badgeText: AppLocalization.localized("Colchón %@", arguments: reserveAmount.formatted(.currency(code: currencyCode))),
                            badgeSystemImage: "target",
                            systemImage: "banknote.fill"
                        )
                    )
                )
            }
        }

        if rules.isEmpty, let topMerchant, topMerchant.frequency >= 2 {
            candidates.append(
                (
                    2,
                    DashboardSavingsStrategy(
                        id: "merchant-rule-\(topMerchant.id)",
                        title: AppLocalization.localized("Automatiza %@", arguments: topMerchant.merchant),
                        detail: AppLocalization.localized(
                            "%@ ya aparece %@. Una regla por comercio mantiene limpia la categoría sin repetir la misma edición.",
                            arguments: topMerchant.merchant,
                            topMerchant.frequencyLabel
                        ),
                        footnote: "Las categorías más limpias hacen que el coach y las futuras sugerencias de ahorro sean más confiables cada semana.".appLocalized,
                        badgeText: "Regla en 1 toque".appLocalized,
                        badgeSystemImage: "sparkles",
                        systemImage: "point.3.connected.trianglepath.dotted"
                    )
                )
            )
        }

        if weeklySafeToSpend > 0, candidates.isEmpty {
            candidates.append(
                (
                    0,
                    DashboardSavingsStrategy(
                        id: "protect-weekly-pace",
                        title: "Protege el ritmo semanal".appLocalized,
                        detail: AppLocalization.localized(
                            "Mantente cerca de %@ durante los próximos 7 días para que el mes siga sintiéndose fácil de dirigir.",
                            arguments: weeklySafeToSpend.formatted(.currency(code: currencyCode))
                        ),
                        footnote: "Los ajustes pequeños ahora mantienen el dashboard en la zona tranquila y reducen la limpieza de fin de mes.".appLocalized,
                        badgeText: AppLocalization.localized("Gasta %@", arguments: weeklySafeToSpend.formatted(.currency(code: currencyCode))),
                        badgeSystemImage: "calendar",
                        systemImage: "gauge.with.dots.needle.bottom.50percent"
                    )
                )
            )
        }

        return candidates
            .sorted { lhs, rhs in
                if lhs.priority != rhs.priority {
                    return lhs.priority < rhs.priority
                }
                return lhs.strategy.id < rhs.strategy.id
            }
            .map(\.strategy)
            .prefix(3)
            .map { $0 }
    }

    private static func buildTrophies(
        state: FinanceDashboardState?,
        ledger: LocalFinanceLedger?,
        streakDays: Int,
        uniqueDayCount: Int,
        accounts: Int,
        bills: Int,
        rules: Int,
        level: Int,
        budgetHealthy: Bool,
        profileCustomized: Bool
    ) -> [GrowthTrophy] {
        let expenses = ledger?.expenses.sorted { $0.date < $1.date } ?? []
        let lastUpdated = ledger?.updatedAt ?? state?.lastUpdated
        let rookieDate = expenses.first?.date
        let steadyDate = nthUniqueExpenseDate(in: expenses, n: 7)

        return [
            GrowthTrophy(
                id: "rookie-ledger",
                title: "Libro novato".appLocalized,
                detail: "Ya entró el primer gasto. El dashboard por fin puede acompañarte con datos reales.".appLocalized,
                celebration: "Primer gasto guardado localmente.".appLocalized,
                systemImage: "sparkles.rectangle.stack.fill",
                hybridBadgeAsset: "badge_savings_v2.png",
                progressValue: expenses.count,
                progressTarget: 1,
                unlocked: expenses.count >= 1,
                unlockedAt: rookieDate
            ),
            GrowthTrophy(
                id: "steady-paws",
                title: "Patas constantes".appLocalized,
                detail: "Siete días activos convirtieron tu ritmo financiero en una racha visible.".appLocalized,
                celebration: "Una semana completa de días activos en el libro.".appLocalized,
                systemImage: "pawprint.fill",
                hybridBadgeAsset: "badge_streak_guardian_v2.png",
                progressValue: uniqueDayCount,
                progressTarget: 7,
                unlocked: uniqueDayCount >= 7,
                unlockedAt: steadyDate
            ),
            GrowthTrophy(
                id: "budget-boss",
                title: "Jefe del presupuesto".appLocalized,
                detail: "El mes sigue dentro del plan actual mientras la actividad crece.".appLocalized,
                celebration: "El presupuesto se mantuvo en zona segura.".appLocalized,
                systemImage: "shield.checkered",
                hybridBadgeAsset: "badge_budgeting_v2.png",
                progressValue: budgetHealthy ? 1 : 0,
                progressTarget: 1,
                unlocked: budgetHealthy && expenses.count >= 5,
                unlockedAt: budgetHealthy && expenses.count >= 5 ? lastUpdated : nil
            ),
            GrowthTrophy(
                id: "rule-architect",
                title: "Arquitecto de reglas".appLocalized,
                detail: "Una regla por comercio significa que el libro local ya empieza a organizarse solo.".appLocalized,
                celebration: "Primera regla agregada.".appLocalized,
                systemImage: "point.3.connected.trianglepath.dotted",
                hybridBadgeAsset: "badge_smart_spend_v2.png",
                progressValue: rules,
                progressTarget: 1,
                unlocked: rules >= 1,
                unlockedAt: rules >= 1 ? lastUpdated : nil
            ),
            GrowthTrophy(
                id: "bill-keeper",
                title: "Guardián de facturas".appLocalized,
                detail: "Las obligaciones recurrentes ya tienen hogar dentro del dashboard.".appLocalized,
                celebration: "Radar de facturas activado.".appLocalized,
                systemImage: "calendar.badge.clock",
                hybridBadgeAsset: "badge_goals_v2.png",
                progressValue: bills,
                progressTarget: 1,
                unlocked: bills >= 1,
                unlockedAt: bills >= 1 ? lastUpdated : nil
            ),
            GrowthTrophy(
                id: "level-five",
                title: "Nivel cinco".appLocalized,
                detail: "Tu sistema local ya tiene suficiente profundidad para sentirse como un loop de producto, no solo un libro.".appLocalized,
                celebration: "Llegaste al nivel cinco.".appLocalized,
                systemImage: "bolt.circle.fill",
                hybridBadgeAsset: "badge_level_up_v2.png",
                progressValue: level,
                progressTarget: 5,
                unlocked: level >= 5,
                unlockedAt: level >= 5 ? lastUpdated : nil
            ),
            GrowthTrophy(
                id: "identity-tuned",
                title: "Identidad afinada".appLocalized,
                detail: "El perfil del hogar ya está personalizado, así que la app se siente propia y no genérica.".appLocalized,
                celebration: "Perfil actualizado para este hogar.".appLocalized,
                systemImage: "person.crop.circle.badge.checkmark",
                hybridBadgeAsset: "badge_security_v2.png",
                progressValue: profileCustomized ? 1 : 0,
                progressTarget: 1,
                unlocked: profileCustomized,
                unlockedAt: profileCustomized ? lastUpdated : nil
            )
        ]
    }

    private static func buildEvents(
        state: FinanceDashboardState?,
        ledger: LocalFinanceLedger?,
        trophies: [GrowthTrophy],
        coachAction: String,
        riskState: DashboardGrowthSnapshot.RiskState,
        activeSeason: BrandSeasonDefinition?
    ) -> [GrowthEvent] {
        let lastUpdated = ledger?.updatedAt ?? state?.lastUpdated ?? .now
        var items: [GrowthEvent] = trophies.compactMap { trophy in
            guard trophy.unlocked, let unlockedAt = trophy.unlockedAt else { return nil }
            return GrowthEvent(
                id: "trophy-\(trophy.id)",
                title: trophy.title,
                detail: trophy.celebration,
                occurredAt: unlockedAt,
                systemImage: "trophy.fill"
            )
        }

        if let topCategory = state?.topCategory {
            items.append(
                GrowthEvent(
                    id: "category-\(topCategory.id)",
                    title: AppLocalization.localized("%@ is leading this month", arguments: topCategory.category.localizedTitle),
                    detail: AppLocalization.localized(
                        "%d gasto%@ local%@ están dando forma al plan actual.",
                        arguments: topCategory.count,
                        topCategory.count == 1 ? "" : "s",
                        topCategory.count == 1 ? "" : "es"
                    ),
                    occurredAt: lastUpdated,
                    systemImage: topCategory.category.symbolName
                )
            )
        }

        if let largestExpense = state?.largestExpense {
            items.append(
                GrowthEvent(
                    id: "largest-\(largestExpense.id)",
                    title: "Mayor movimiento reciente".appLocalized,
                    detail: AppLocalization.localized("%@ es el movimiento más grande reciente en el libro.", arguments: largestExpense.title),
                    occurredAt: largestExpense.date,
                    systemImage: "arrow.up.right.circle.fill"
                )
            )
        }

        items.append(
            GrowthEvent(
                id: "coach-action",
                title: (riskState == .urgent ? "El coach pide un rescate" : "El coach eligió el siguiente paso").appLocalized,
                detail: coachAction,
                occurredAt: lastUpdated,
                systemImage: "lightbulb.max.fill"
            )
        )

        if let activeSeason {
            items.append(
                GrowthEvent(
                    id: "season-\(activeSeason.id.rawValue)",
                    title: activeSeason.title.appLocalized,
                    detail: activeSeason.summary.appLocalized,
                    occurredAt: lastUpdated,
                    systemImage: "wand.and.stars"
                )
            )
        }

        return items.sorted { $0.occurredAt > $1.occurredAt }
    }

    static func buildLiveEvent(
        activeSeason: BrandSeasonDefinition?,
        referenceDate: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> GrowthLiveEvent? {
        if let activeSeason {
            return GrowthLiveEvent(
                title: activeSeason.title,
                detail: activeSeason.summary,
                badgeText: activeSeason.badgeText,
                badgeAsset: activeSeason.badgeAsset,
                sceneKey: activeSeason.spotlightGuideKey,
                isActive: true,
                dateLabel: "Activo ahora".appLocalized
            )
        }

        guard let nextSeason = BrandSeasonCatalog.nextSeason(after: referenceDate, calendar: calendar) else {
            return nil
        }

        let startOfReference = calendar.startOfDay(for: referenceDate)
        let startOfSeason = calendar.startOfDay(for: nextSeason.startDate)
        let daysUntilStart = calendar.dateComponents([.day], from: startOfReference, to: startOfSeason).day ?? .max

        guard daysUntilStart <= liveEventPreviewLeadDays else {
            return nil
        }

        return GrowthLiveEvent(
            title: nextSeason.season.title,
            detail: nextSeason.season.summary,
            badgeText: "Próximo evento en vivo".appLocalized,
            badgeAsset: nextSeason.season.badgeAsset,
            sceneKey: nextSeason.season.spotlightGuideKey,
            isActive: false,
            dateLabel: AppLocalization.localized(
                "Empieza %@",
                arguments: nextSeason.startDate.formatted(date: .abbreviated, time: .omitted)
            )
        )
    }

    private static func uniqueExpenseDays(in expenses: [ExpenseRecord]) -> [Date] {
        let calendar = Calendar.autoupdatingCurrent
        let grouped = Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }
        return grouped.keys.sorted()
    }

    private static func activeStreak(from uniqueDays: [Date]) -> Int {
        guard !uniqueDays.isEmpty else { return 0 }
        let calendar = Calendar.autoupdatingCurrent
        let set = Set(uniqueDays.map { calendar.startOfDay(for: $0) })
        var cursor = calendar.startOfDay(for: .now)

        if !set.contains(cursor), let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor), set.contains(yesterday) {
            cursor = yesterday
        }

        var streak = 0
        while set.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    private static func nthUniqueExpenseDate(in expenses: [ExpenseRecord], n: Int) -> Date? {
        guard n > 0 else { return nil }
        let calendar = Calendar.autoupdatingCurrent
        var seen = Set<Date>()
        var uniqueDates: [Date] = []

        for expense in expenses.sorted(by: { $0.date < $1.date }) {
            let day = calendar.startOfDay(for: expense.date)
            if seen.insert(day).inserted {
                uniqueDates.append(expense.date)
            }
            if uniqueDates.count >= n {
                return uniqueDates[n - 1]
            }
        }

        return nil
    }

    private static func safeToSpendWeek(for remaining: Decimal, daysLeft: Int) -> Decimal {
        let safeDays = max(daysLeft, 1)
        let perDay = remaining / Decimal(safeDays)
        let weekly = perDay * Decimal(7)
        return weekly > 0 ? weekly : 0
    }

    private static func share(of value: Decimal, in total: Decimal) -> Double {
        guard total > 0 else { return 0 }
        let lhs = NSDecimalNumber(decimal: value).doubleValue
        let rhs = NSDecimalNumber(decimal: total).doubleValue
        guard rhs > 0 else { return 0 }
        return lhs / rhs
    }

    private static func percentLabel(for value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private static func suggestedTrimAmount(
        averageExpense: Decimal,
        topCategoryTotal: Decimal,
        hotspotAverage: Decimal?
    ) -> Decimal {
        let hotspotValue = hotspotAverage ?? 0
        let categorySlice = topCategoryTotal * Decimal(string: "0.18")!
        let baseline = max(averageExpense, hotspotValue)
        return max(baseline, categorySlice)
    }

    private static func suggestedReserveAmount(income: Decimal, remaining: Decimal) -> Decimal {
        let incomeCap = income * Decimal(string: "0.08")!
        let remainingCap = remaining * Decimal(string: "0.25")!
        return min(incomeCap, remainingCap)
    }

    private static func missionDisplayPriority(for id: String, seasonID: BrandSeasonID?) -> Int {
        if let seasonID {
            return GrowthMissionCatalog
                .seasonalBlueprints[seasonID]?
                .first(where: { $0.id == id })?
                .displayPriority ?? .max
        }

        return GrowthMissionCatalog
            .coreBlueprints
            .first(where: { $0.id == id })?
            .displayPriority ?? .max
    }
}

private extension GrowthMission.Status {
    var sortRank: Int {
        switch self {
        case .pending: return 0
        case .ready: return 1
        case .completed: return 2
        }
    }
}
