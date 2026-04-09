import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: AppViewModel
    @AppStorage(AppCurrencyFormat.defaultsKey) private var currencyCode = AppCurrencyFormat.defaultCode
    @Environment(\.shellBottomInset) private var shellBottomInset
    var onOpenGuide: (() -> Void)? = nil

    @State private var isPresentingGuide = false
    @State private var hasPresentedInitialGuide = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                if let state = viewModel.dashboardState {
                    let growth = growthSnapshot(for: state)
                    heroCard(growth: growth, state: state)
                    missionSummaryCard(growth: growth)
                    todayCard(for: state, growth: growth)
                    paceCard(for: state, growth: growth)
                    strategyCard(growth: growth)
                    recentSpendCard(for: state)

                    ExperienceDisclosureCard(
                        title: "Vista avanzada",
                        summary: "Las facturas y la lectura más profunda del dinero viven aquí, mientras el loop principal queda visible arriba.",
                        character: .tikki,
                        expression: .thinking
                    ) {
                        if !viewModel.bills.isEmpty {
                            billsSection
                        }

                        if !state.categoryBreakdown.isEmpty {
                            categorySection(for: state)
                        }
                    }
                } else {
                    loadingHeroCard
                    loadingCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, shellBottomInset + 18)
        }
        .accessibilityIdentifier("dashboard.screen")
        .overlay(alignment: .topLeading) {
            AccessibilityProbe(identifier: "dashboard.screen")
        }
        .background(FinanceScreenBackground())
        .navigationTitle("Inicio")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.dashboardState == nil {
                await viewModel.refreshDashboard()
            }
        }
        .onAppear {
            guard !hasPresentedInitialGuide else { return }
            hasPresentedInitialGuide = true
            if onOpenGuide == nil, !GuideProgressStore.isSeen(.dashboard), viewModel.debugRoute == nil {
                isPresentingGuide = true
            }
        }
        .sheet(isPresented: $isPresentingGuide) {
            GuideSheet(guide: GuideLibrary.guide(.dashboard))
        }
    }

    private func growthSnapshot(for state: FinanceDashboardState) -> DashboardGrowthSnapshot {
        viewModel.growthSnapshot ?? GrowthSnapshotBuilder.build(
            session: viewModel.session,
            state: state,
            ledger: viewModel.ledger,
            accounts: viewModel.accounts,
            bills: viewModel.bills,
            rules: viewModel.rules,
            profile: viewModel.profile,
            cloudStatus: viewModel.growthCloudStatus
        )
    }

    private func heroCard(growth: DashboardGrowthSnapshot, state: FinanceDashboardState) -> some View {
        JourneyHeroCard(
            eyebrow: "Ciclo diario del dinero",
            title: growth.greetingTitle,
            summary: "Empieza con un número claro, un siguiente paso y la parte del mes que necesita atención ahora.",
            character: .manchas,
            expression: dashboardExpression(growth: growth),
            sceneKey: "guide_01_dashboard_game_manchas",
            scenePrompt: nil,
            metrics: [
                BrandHeroMetric(
                    title: "Esta semana",
                    value: safeToSpendWeek(for: state).formatted(.currency(code: currencyCode)),
                    systemImage: "banknote.fill"
                ),
                BrandHeroMetric(
                    title: "Racha",
                    value: "\(growth.streakDays)d",
                    systemImage: "flame.fill"
                ),
                BrandHeroMetric(
                    title: "Días restantes",
                    value: "\(state.remainingDaysInMonth)",
                    systemImage: "calendar"
                )
            ]
        ) {
            Button("Agregar gasto") {
                viewModel.presentAddExpense()
            }
            .buttonStyle(PrimaryCTAStyle())
            .accessibilityIdentifier("dashboard.action.addExpense")

            Button("Asistente de presupuesto") {
                viewModel.presentBudgetWizard()
            }
            .buttonStyle(SecondaryCTAStyle())
            .accessibilityIdentifier("dashboard.action.budgetWizard")

            guideButton
        }
    }

    private var loadingHeroCard: some View {
        JourneyHeroCard(
            eyebrow: "Ciclo diario del dinero",
            title: "Cargando inicio",
            summary: "Estamos reuniendo tus gastos, la guía del coach y las señales que alimentan el dashboard.",
            character: .manchas,
            expression: .thinking,
            sceneKey: "guide_01_dashboard_game_manchas",
            scenePrompt: nil
        ) {
            guideButton
        }
    }

    private var guideButton: some View {
        Group {
            if let onOpenGuide {
                Button {
                    onOpenGuide()
                } label: {
                    Label("Abrir guía de inicio", systemImage: "questionmark.circle")
                }
                .buttonStyle(SecondaryCTAStyle())
            } else {
                Button {
                    isPresentingGuide = true
                } label: {
                    Label("Abrir guía de inicio", systemImage: "questionmark.circle")
                }
                .buttonStyle(SecondaryCTAStyle())
            }
        }
    }

    private func todayCard(for state: FinanceDashboardState, growth: DashboardGrowthSnapshot) -> some View {
        ExperienceSectionCard(
            title: "Hoy",
            summary: growth.coachBody,
            badgeText: growth.riskState.label,
            badgeSystemImage: "sparkles"
        ) {
            BrandFeatureRow(
                systemImage: "banknote.fill",
                title: "Disponible ahora",
                detail: AppLocalization.localized(
                    "Todavía tienes %@ disponibles dentro del plan mensual.",
                    arguments: state.budgetSnapshot.remaining.formatted(.currency(code: currencyCode))
                )
            )

            BrandFeatureRow(
                systemImage: "arrow.triangle.branch",
                title: "Mejor siguiente paso",
                detail: growth.coachAction
            )

            ProgressView(value: min(max(state.utilizationRatio, 0), 1))
                .tint(BrandTheme.primary)
        }
    }

    private func strategyCard(growth: DashboardGrowthSnapshot) -> some View {
        GuidedSectionCard(
            title: "Plan de ahorro",
            summary: "Una lista corta de movimientos que protegen tu dinero sin convertir inicio en un reporte denso.",
            character: .mei,
            expression: growth.riskState == .urgent ? .warning : .thinking,
            systemImage: "brain.head.profile"
        ) {
            if growth.strategies.isEmpty {
                FinanceEmptyStateCard(
                    title: "Las estrategias de ahorro aparecerán aquí",
                    summary: "Cuando el libro tenga un poco más de historia, el coach mostrará el mejor movimiento para esta semana.",
                    systemImage: "sparkles"
                )
            } else {
                ForEach(growth.strategies) { strategy in
                    VStack(alignment: .leading, spacing: 10) {
                        Label(strategy.title, systemImage: strategy.systemImage)
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                            .labelStyle(.titleAndIcon)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        FlowStack(spacing: 8, rowSpacing: 8) {
                            BrandBadge(text: strategy.badgeText, systemImage: strategy.badgeSystemImage)
                        }

                        Text(strategy.detail)
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .lineLimit(4)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(strategy.footnote)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(BrandTheme.primary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(BrandTheme.surfaceTint)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(BrandTheme.line.opacity(0.82), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func paceCard(for state: FinanceDashboardState, growth: DashboardGrowthSnapshot) -> some View {
        let daily = safeToSpendDay(for: state)
        let weekly = safeToSpendWeek(for: state)
        let remaining = state.budgetSnapshot.remaining
        let statusText: String

        if remaining < 0 {
            statusText = "Pausa gastos no esenciales y registra solo lo importante hasta cerrar el mes."
        } else if state.utilizationRatio >= 0.85 {
            statusText = "Vas justo. Mantén compras pequeñas en espera y revisa el próximo gasto antes de pagarlo."
        } else {
            statusText = "Tu ritmo sigue manejable. Usa este número como guía rápida antes de comprar."
        }

        return GuidedSectionCard(
            title: "Ritmo de ahorro",
            summary: "Un solo número para decidir rápido sin abrir reportes: cuánto puedes usar sin romper tu plan.",
            character: .tikki,
            expression: growth.riskState == .urgent ? .warning : .happy,
            systemImage: "speedometer"
        ) {
            BrandFeatureRow(
                systemImage: "sun.max.fill",
                title: "Hoy puedes usar",
                detail: daily.formatted(.currency(code: currencyCode))
            )

            BrandFeatureRow(
                systemImage: "calendar.badge.clock",
                title: "Semana segura",
                detail: weekly.formatted(.currency(code: currencyCode))
            )

            BrandFeatureRow(
                systemImage: "sparkles",
                title: "Movimiento recomendado",
                detail: statusText
            )

            ProgressView(value: min(max(state.utilizationRatio, 0), 1))
                .tint(growth.riskState == .urgent ? BrandTheme.warning : BrandTheme.primary)
        }
    }

    private func missionSummaryCard(growth: DashboardGrowthSnapshot) -> some View {
        GuidedSectionCard(
            title: "Tablero de misiones",
            summary: "Una mezcla corta de retos para ayudarte a registrar mejor, ordenar gastos y ahorrar sin volver compleja la pantalla principal.",
            character: .manchas,
            expression: .excited,
            systemImage: "checklist"
        ) {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                BrandMetricTile(title: "Misiones", value: "\(growth.allMissions.filter { $0.status == .completed }.count)/\(growth.allMissions.count)", systemImage: "checklist")
                BrandMetricTile(title: "En curso", value: "\(growth.allMissions.filter { $0.status != .completed }.count)", systemImage: "figure.walk")
                BrandMetricTile(title: "Eventos", value: "\(growth.eventCalendar.count)", systemImage: "calendar")
                BrandMetricTile(title: "Logros", value: "\(growth.trophies.filter { $0.unlocked }.count)", systemImage: "trophy.fill")
            }

            ProgressView(value: growth.levelProgress)
                .tint(BrandTheme.primary)

            if let liveEvent = growth.liveEvent {
                liveEventCard(liveEvent)
            }

            if growth.missions.isEmpty {
                FinanceEmptyStateCard(
                    title: "Todavía no hay misiones",
                    summary: "Agrega tu primera actividad y tus retos aparecerán aquí.",
                    systemImage: "sparkles"
                )
            } else {
                ForEach(Array(growth.missions.prefix(2))) { mission in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 14) {
                            GrowthMissionBadgeView(mission: mission, size: 54)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(mission.title)
                                    .font(.headline)
                                    .foregroundStyle(BrandTheme.ink)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(mission.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(BrandTheme.muted)
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }

                        FlowStack(spacing: 8, rowSpacing: 8) {
                            BrandBadge(text: mission.status.localizedTitle, systemImage: mission.systemImage)
                            BrandBadge(text: mission.cadenceLabel, systemImage: "calendar")
                            if mission.isSeasonal {
                                BrandBadge(text: "Evento", systemImage: "wand.and.stars")
                            }
                        }

                        ProgressView(value: mission.progressRatio)
                            .tint(BrandTheme.primary)

                        HStack {
                            Text("\(mission.progressText) · \(mission.rewardXP) XP")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BrandTheme.muted)

                            Spacer()
                        }
                        Text(mission.coachNote)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(BrandTheme.primary)
                            .lineLimit(2)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(BrandTheme.surfaceTint)
                    )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(BrandTheme.line.opacity(0.82), lineWidth: 1)
                        )
                }

                if growth.missions.count > 1 {
                    BrandFeatureRow(
                        systemImage: "checklist.checked",
                        title: AppLocalization.localized("%d misiones más disponibles", arguments: growth.allMissions.count - min(growth.missions.count, 2)),
                        detail: "Abre el historial para ver el tablero completo de misiones y el calendario de eventos."
                    )
                }
            }

            trophyRail(growth: growth)

            NavigationLink {
                TrophyHistoryView(viewModel: viewModel)
            } label: {
                QuickActionTile(
                    title: "Abrir historial de logros",
                    detail: "Mira cada badge desbloqueado, el objetivo de progreso y la línea de tiempo completa en otra pantalla.",
                    systemImage: "trophy.fill"
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("dashboard.link.trophies")
        }
    }

    private var billsSection: some View {
        ExperienceSectionCard(
            title: "Radar de facturas",
            summary: "Las próximas fechas de vencimiento se quedan guardadas hasta que las necesites.",
            badgeText: "\(viewModel.bills.count)",
            badgeSystemImage: "calendar.badge.clock"
        ) {
            ForEach(viewModel.bills.prefix(3)) { bill in
                BrandFeatureRow(
                    systemImage: bill.paymentState(referenceDate: .now, ledger: viewModel.ledger).symbolName,
                    title: bill.title,
                    detail: "\(bill.amount.formatted(.currency(code: currencyCode))) · \(FinanceToolFormatting.dueDateText(for: bill, ledger: viewModel.ledger))"
                )
            }
        }
    }

    private func categorySection(for state: FinanceDashboardState) -> some View {
        ExperienceSectionCard(
            title: "Presión por categoría",
            summary: "Las categorías principales son la forma más rápida de ver hacia dónde se inclina el mes.",
            badgeText: state.topCategory?.category.localizedTitle ?? "Mixto",
            badgeSystemImage: state.topCategory?.category.symbolName ?? "chart.pie.fill"
        ) {
            ForEach(state.categoryBreakdown.prefix(4)) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(item.category.localizedTitle, systemImage: item.category.symbolName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(BrandTheme.ink)
                        Spacer()
                        Text(item.total.formatted(.currency(code: currencyCode)))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(BrandTheme.ink)
                    }

                    ProgressView(value: categoryProgress(item.total, total: state.budgetSnapshot.monthlySpent))
                        .tint(BrandTheme.primary)

                    Text(categoryCountLabel(for: item.count))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.muted)
                }
            }
        }
    }

    private var loadingCard: some View {
        MascotLoadingCard(
            badgeText: "Cargando inicio",
            title: "Cargando inicio",
            summary: "Estamos reuniendo tus gastos, la guía del coach y las señales por categoría.",
            character: .manchas,
            expression: .excited
        )
    }

    private func dashboardExpression(growth: DashboardGrowthSnapshot) -> BrandExpression {
        switch growth.riskState {
        case .calm:
            return .happy
        case .watch:
            return .thinking
        case .urgent:
            return .warning
        }
    }

    private func safeToSpendWeek(for state: FinanceDashboardState) -> Decimal {
        let remaining = state.budgetSnapshot.remaining
        let daysLeft = max(state.remainingDaysInMonth, 1)
        let perDay = decimalDivide(remaining, by: daysLeft)
        return max(0, perDay * Decimal(7))
    }

    private func safeToSpendDay(for state: FinanceDashboardState) -> Decimal {
        max(0, decimalDivide(state.budgetSnapshot.remaining, by: max(state.remainingDaysInMonth, 1)))
    }

    private func decimalDivide(_ value: Decimal, by divisor: Int) -> Decimal {
        guard divisor > 0 else { return 0 }
        return value / Decimal(divisor)
    }

    private func categoryProgress(_ value: Decimal, total: Decimal) -> Double {
        guard total > 0 else { return 0 }
        let lhs = NSDecimalNumber(decimal: value).doubleValue
        let rhs = NSDecimalNumber(decimal: total).doubleValue
        guard rhs > 0 else { return 0 }
        return min(1, max(0, lhs / rhs))
    }

    private func categoryCountLabel(for count: Int) -> String {
        if count == 1 {
            return AppLocalization.localized("%d transacción", arguments: count)
        }
        return AppLocalization.localized("%d transacciones", arguments: count)
    }

    private func localizedCategoryName(_ rawValue: String) -> String {
        ExpenseCategory.allCases.first(where: { $0.rawValue == rawValue })?.localizedTitle ?? rawValue.appLocalized
    }

    private func liveEventCard(_ liveEvent: GrowthLiveEvent) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(BrandTheme.surface)

                    if let image = BrandAssetCatalog.shared.image(for: BrandAssetCatalog.shared.badge(named: liveEvent.badgeAsset)) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding(10)
                    } else {
                        Image(systemName: "wand.and.stars")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(BrandTheme.primary)
                    }
                }
                .frame(width: 62, height: 62)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(BrandTheme.line.opacity(0.82), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 8) {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .center, spacing: 8) {
                            BrandBadge(text: liveEvent.badgeText, systemImage: liveEvent.isActive ? "sparkles" : "calendar")
                            Spacer(minLength: 8)
                            Text(liveEvent.dateLabel)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(BrandTheme.primary)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            BrandBadge(text: liveEvent.badgeText, systemImage: liveEvent.isActive ? "sparkles" : "calendar")
                            Text(liveEvent.dateLabel)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(BrandTheme.primary)
                        }
                    }

                    Text(liveEvent.title)
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(liveEvent.detail)
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            BrandAssetImage(
                source: BrandAssetCatalog.shared.guide(liveEvent.sceneKey),
                fallbackSystemImage: "sparkles"
            )
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity)
            .frame(height: 126)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(BrandTheme.surfaceTint)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(BrandTheme.line.opacity(0.82), lineWidth: 1)
        )
    }

    private func trophyRail(growth: DashboardGrowthSnapshot) -> some View {
        let trophyPreview = growth.highlightedTrophies.isEmpty ? Array(growth.trophies.prefix(4)) : Array(growth.highlightedTrophies.prefix(4))

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Vitrina de logros")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Spacer()
                Text(AppLocalization.localized("%d desbloqueados", arguments: growth.trophies.filter { $0.unlocked }.count))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BrandTheme.primary)
            }

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(trophyPreview) { trophy in
                    VStack(alignment: .leading, spacing: 8) {
                        GrowthTrophyPlate(trophy: trophy, size: 56)
                        Text(trophy.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(BrandTheme.ink)
                            .lineLimit(2)
                        Text(trophy.unlocked ? "Desbloqueado" : trophy.progressText)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(trophy.unlocked ? BrandTheme.primary : BrandTheme.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(BrandTheme.surfaceTint)
                    )
                }
            }
        }
        .padding(.top, 4)
    }

    private func recentSpendCard(for state: FinanceDashboardState) -> some View {
        GuidedSectionCard(
            title: "Actividad reciente",
            summary: "Tus últimos movimientos y la forma del mes en un solo lugar.",
            character: .mei,
            expression: .thinking,
            systemImage: "list.bullet.rectangle"
        ) {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                BrandMetricTile(
                    title: "Gastado",
                    value: state.budgetSnapshot.monthlySpent.formatted(.currency(code: currencyCode)),
                    systemImage: "creditcard.fill"
                )
                BrandMetricTile(
                    title: "Promedio",
                    value: state.averageExpense.formatted(.currency(code: currencyCode)),
                    systemImage: "chart.bar.fill"
                )
            }

            if state.recentExpenses.isEmpty {
                FinanceEmptyStateCard(
                    title: "Agrega el primer gasto",
                    summary: "Cuando el libro se mueva, aquí aparecerán tu actividad reciente y las señales por categoría.",
                    systemImage: "square.and.pencil"
                )
            } else {
                ForEach(state.recentExpenses.prefix(5)) { expense in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(BrandTheme.accent.opacity(0.18))
                            Image(systemName: "receipt.fill")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(BrandTheme.primary)
                        }
                        .frame(width: 42, height: 42)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(expense.title)
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)
                            Text(
                                AppLocalization.localized(
                                    "%@ · %@",
                                    arguments: localizedCategoryName(expense.category),
                                    expense.date.formatted(date: .abbreviated, time: .omitted)
                                )
                            )
                                .font(.subheadline)
                                .foregroundStyle(BrandTheme.muted)
                        }

                        Spacer(minLength: 0)

                        Text(expense.amount.formatted(.currency(code: currencyCode)))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(BrandTheme.ink)
                    }
                }
            }
        }
    }
}
