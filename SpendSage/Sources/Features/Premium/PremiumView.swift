import SwiftUI

struct PremiumView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.openURL) private var openURL
    @State private var notice: String?
    @AppStorage("native.premium.status") private var storedStatus = PremiumStatus.free.rawValue
    @AppStorage("native.premium.plan") private var storedPlanID = PremiumPlan.ID.freeLocal.rawValue

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                plansCard
                ExperienceDisclosureCard(
                    title: "Facturación y soporte",
                    summary: "Restaurar, gestionar y revisar lo legal queda cerca sin competir con la lista de planes.",
                    character: .mei,
                    expression: .proud
                ) {
                    billingDetails
                }

                if let notice {
                    messageCard(message: notice)
                }
            }
            .padding(24)
        }
        .background(
            ZStack {
                BrandTheme.canvas
                BrandBackdropView()
            }
            .ignoresSafeArea()
        )
        .overlay(alignment: .topLeading) {
            AccessibilityProbe(identifier: "premium.screen")
        }
        .accessibilityIdentifier("premium.screen")
        .navigationTitle("Planes")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.refreshBackendStatus(force: true)
            await viewModel.refreshStoreBilling(force: true)
        }
    }

    private var heroCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                BrandBadge(
                    text: currentStatus.badgeTitle,
                    systemImage: "sparkles"
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Elige un plan")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandTheme.ink)

                    Text(
                        viewModel.session.isAuthenticated
                            ? "Gratis sirve para empezar. Pro desbloquea automatización y respaldo; Family suma el hogar completo."
                            : "Compara planes primero. Luego inicia sesión si quieres que tus compras y restauración queden ligadas a tu cuenta."
                    )
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                BrandFeatureRow(
                    systemImage: currentStatus.systemImage,
                    title: AppLocalization.localized("Plan actual: %@", arguments: currentPlan.name.appLocalized),
                    detail: currentStatus.detail(plan: currentPlan)
                )
            }
        }
    }

    private var plansCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                CompactSectionHeader(
                    title: "Planes",
                    detail: "El plan anual es el mejor valor si vas en serio con tu presupuesto."
                )

                VStack(spacing: 12) {
                    ForEach(PremiumPlan.allCases) { plan in
                        PremiumPlanCard(
                            plan: plan,
                            priceLabel: priceLabel(for: plan),
                            isCurrent: plan.id == currentPlan.id,
                            canPurchase: viewModel.session.isAuthenticated || plan.id == .freeLocal,
                            storeOptions: storeOptions(for: plan),
                            isBusy: viewModel.storeBillingState.isLoading,
                            activeProductIDs: Set(viewModel.storeEntitlements.activeProductIDs),
                            activePurchaseProductID: viewModel.storeBillingState.activePurchaseProductID
                        ) { action in
                            handle(action)
                        }
                    }
                }
            }
        }
    }

    private var billingDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.backendConfiguration != nil {
                actionRow(
                    title: "Estado del plan",
                    summary: viewModel.backendStatusError ?? currentPlan.name.appLocalized,
                    systemImage: viewModel.backendStatusError == nil ? "checkmark.shield.fill" : "exclamationmark.triangle.fill"
                )

                Button {
                    Task {
                        await viewModel.refreshBackendStatus(force: true)
                        notice = viewModel.backendStatusError ?? "Plan actualizado."
                    }
                } label: {
                    actionRow(
                        title: "Actualizar plan",
                        summary: "Vuelve a leer el plan activo y tus compras disponibles.",
                        systemImage: "arrow.clockwise.circle.fill"
                    )
                }
                .buttonStyle(.plain)
            }

            Button {
                Task {
                    await viewModel.restoreStorePurchases()
                    notice = viewModel.storeBillingState.lastError ?? viewModel.notice ?? "Restauracion completada."
                }
            } label: {
                actionRow(
                    title: "Restaurar compras",
                    summary: "Relee compras y suscripciones del Apple ID actual.",
                    systemImage: "arrow.clockwise.circle.fill"
                )
            }
            .buttonStyle(.plain)

            Button {
                guard let url = viewModel.subscriptionManagementURL else {
                    notice = "No se pudo abrir la gestion de suscripciones."
                    return
                }
                openURL(url)
                notice = "Gestion de suscripciones abierta en App Store."
            } label: {
                actionRow(
                    title: "Gestionar suscripción",
                    summary: "Abre los controles de renovacion, cambio o cancelacion del sistema.",
                    systemImage: "slider.horizontal.3"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                LegalCenterView(initialSection: .terms)
            } label: {
                actionRow(
                    title: "Términos",
                    summary: "Revisa los términos del plan.",
                    systemImage: "doc.text.fill"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                LegalCenterView(initialSection: .privacy)
            } label: {
                actionRow(
                    title: "Privacidad",
                    summary: "Revisa los detalles de privacidad.",
                    systemImage: "hand.raised.fill"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func messageCard(message: String) -> some View {
        SurfaceCard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "bell.badge.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(BrandTheme.primary)
                    .frame(width: 42, height: 42)
                    .background(BrandTheme.accent.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Estado")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Text(message.appLocalized)
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private func actionRow(title: String, summary: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(BrandTheme.primary)
                .frame(width: 42, height: 42)
                .background(BrandTheme.accent.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title.appLocalized)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text(summary.appLocalized)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(BrandTheme.muted)
                .padding(.top, 6)
        }
        .padding(14)
        .background(BrandTheme.surfaceTint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
        )
    }

    private func handle(_ action: PremiumPlanAction) {
        switch action {
        case .keepFree:
            guard viewModel.storeEntitlements.activeProductIDs.isEmpty else {
                notice = "Ya tienes una compra activa en App Store. Usa Gestionar suscripcion si quieres cambiarla."
                return
            }
            viewModel.chooseFreeLocalPlan()
            notice = viewModel.notice ?? "El plan gratis sigue activo."
        case let .purchase(product):
            guard viewModel.session.isAuthenticated else {
                notice = "Inicia sesion primero para comprar o restaurar desde App Store."
                return
            }

            Task {
                await viewModel.purchaseStoreProduct(product.id)
                notice = viewModel.storeBillingState.lastError ?? viewModel.notice
            }
        }
    }

    private func storeOptions(for plan: PremiumPlan) -> [StoreCatalogProduct] {
        viewModel.storeProducts(for: plan.id.rawValue)
    }

    private func priceLabel(for plan: PremiumPlan) -> String {
        let storeOptions = storeOptions(for: plan)
        guard !storeOptions.isEmpty else { return plan.priceLabel }

        return storeOptions
            .map { "\($0.kind.summaryLabel) \($0.displayPrice)" }
            .joined(separator: " · ")
    }

    private var currentStatus: PremiumStatus {
        guard viewModel.session.isAuthenticated else { return .free }
        if let cloudPlanID, cloudPlanID != .freeLocal {
            return .active
        }
        if !viewModel.storeEntitlements.activeProductIDs.isEmpty {
            return .active
        }
        if viewModel.storeBillingState.lastError == StoreBillingError.purchasePending.errorDescription {
            return .trialing
        }
        return PremiumStatus(rawValue: storedStatus) ?? .free
    }

    private var currentPlan: PremiumPlan {
        if let cloudPlanID, cloudPlanID != .freeLocal {
            return PremiumPlan.allCases.first(where: { $0.id == cloudPlanID }) ?? PremiumPlan.allCases[0]
        }

        if let activePlanKey = viewModel.storeEntitlements.activePlanKey {
            switch activePlanKey {
            case .freeLocal:
                return PremiumPlan.allCases.first(where: { $0.id == .freeLocal }) ?? PremiumPlan.allCases[0]
            case .removeAds:
                return PremiumPlan.allCases.first(where: { $0.id == .removeAds }) ?? PremiumPlan.allCases[0]
            case .pro:
                return PremiumPlan.allCases.first(where: { $0.id == .pro }) ?? PremiumPlan.allCases[0]
            case .family:
                return PremiumPlan.allCases.first(where: { $0.id == .family }) ?? PremiumPlan.allCases[0]
            }
        }

        let planID: PremiumPlan.ID
        if currentStatus == .free {
            planID = .freeLocal
        } else {
            planID = PremiumPlan.ID(rawValue: storedPlanID) ?? .pro
        }
        return PremiumPlan.allCases.first(where: { $0.id == planID }) ?? PremiumPlan.allCases[0]
    }

    private var cloudPlanID: PremiumPlan.ID? {
        guard let planId = viewModel.cloudEntitlements?.planId.lowercased() else { return nil }
        switch planId {
        case "personal", "pro":
            return .pro
        case "family":
            return .family
        case "enterprise":
            return .family
        case "free":
            return .freeLocal
        default:
            return nil
        }
    }
}

private enum PremiumStatus: String {
    case free
    case trialing
    case active
    case expired

    var label: String {
        switch self {
        case .free: return "Gratis".appLocalized
        case .trialing: return "Vista previa".appLocalized
        case .active: return "Listo".appLocalized
        case .expired: return "Revisar".appLocalized
        }
    }

    var systemImage: String {
        switch self {
        case .free: return "leaf.fill"
        case .trialing: return "hourglass"
        case .active: return "checkmark.seal.fill"
        case .expired: return "exclamationmark.triangle.fill"
        }
    }

    var badgeTitle: String {
        switch self {
        case .free: return "Gratis".appLocalized
        case .trialing: return "Vista previa".appLocalized
        case .active: return "Premium listo".appLocalized
        case .expired: return "Ruta de renovación".appLocalized
        }
    }

    var billingSourceLabel: String {
        switch self {
        case .free: return "Estado del plan".appLocalized
        case .trialing, .active, .expired: return "Estado de App Store".appLocalized
        }
    }

    func detail(plan: PremiumPlan) -> String {
        switch self {
        case .free:
            return AppLocalization.localized("%@ está activo. Puedes seguir usando la app y actualizar cuando quieras más funciones.", arguments: plan.name.appLocalized)
        case .trialing:
            return AppLocalization.localized("%@ quedo pendiente en App Store. Revisa aprobacion familiar, cobro o restauracion.", arguments: plan.name.appLocalized)
        case .active:
            return AppLocalization.localized("%@ está activo para esta cuenta.", arguments: plan.name.appLocalized)
        case .expired:
            return AppLocalization.localized("%@ necesita revision. Usa restaurar o gestionar suscripcion para corregirlo.", arguments: plan.name.appLocalized)
        }
    }
}

private struct PremiumPlan: Identifiable, Equatable, CaseIterable {
    enum ID: String, CaseIterable, Identifiable {
        case freeLocal
        case removeAds
        case pro
        case family

        var id: String { rawValue }
    }

    let id: ID
    let name: String
    let priceLabel: String
    let summary: String
    let features: [String]
    let isHighlighted: Bool

    static let allCases: [PremiumPlan] = LaunchMonetizationCatalog.planCards.map { plan in
        PremiumPlan(
            id: ID(rawValue: plan.planKey.rawValue) ?? .freeLocal,
            name: plan.planKey.displayName,
            priceLabel: plan.priceLabel,
            summary: plan.summary,
            features: plan.features,
            isHighlighted: plan.isHighlighted
        )
    }
}

private struct PremiumPlanCard: View {
    let plan: PremiumPlan
    let priceLabel: String
    let isCurrent: Bool
    let canPurchase: Bool
    let storeOptions: [StoreCatalogProduct]
    let isBusy: Bool
    let activeProductIDs: Set<String>
    let activePurchaseProductID: String?
    let action: (PremiumPlanAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(plan.name.appLocalized)
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        if plan.isHighlighted {
                            BrandBadge(text: "Recomendado", systemImage: "sparkles")
                        }

                        if isCurrent {
                            BrandBadge(text: "Actual", systemImage: "checkmark.circle.fill")
                        }
                    }

                    Text(priceLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BrandTheme.primary)
                }

                Spacer(minLength: 0)

                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            plan.isHighlighted
                                ? AnyShapeStyle(BrandTheme.heroGlowGradient)
                                : AnyShapeStyle(BrandTheme.accent.opacity(0.16))
                        )
                    Image(systemName: plan.isHighlighted ? "sparkles" : "leaf.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(plan.isHighlighted ? BrandTheme.primary : BrandTheme.muted)
                }
                .frame(width: 42, height: 42)
            }

            Text(plan.summary.appLocalized)
                .font(.subheadline)
                .foregroundStyle(BrandTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(plan.features, id: \.self) { feature in
                    Label(feature.appLocalized, systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BrandTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if plan.id == .freeLocal {
                if isCurrent {
                    Button(action: {}) {
                        Text("Actual".appLocalized)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryCTAStyle())
                    .disabled(true)
                } else {
                    Button {
                        action(.keepFree)
                    } label: {
                        Text("Mantener gratis".appLocalized)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryCTAStyle())
                }
            } else if !storeOptions.isEmpty {
                VStack(spacing: 8) {
                    ForEach(storeOptions) { product in
                        purchaseButton(for: product)
                    }
                }
            } else if isBusy {
                HStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("Cargando App Store".appLocalized)
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Button(action: {}) {
                    Text(
                        canPurchase
                            ? "Producto pendiente en App Store Connect".appLocalized
                            : "Inicia sesion para comprar".appLocalized
                    )
                        .frame(maxWidth: .infinity)
                }
                .disabled(true)
                .buttonStyle(PrimaryCTAStyle())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            BrandTheme.surfaceTint,
                            plan.isHighlighted ? BrandTheme.glow.opacity(0.18) : BrandTheme.surface.opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(plan.isHighlighted ? BrandTheme.primary.opacity(0.28) : BrandTheme.line.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: plan.isHighlighted ? BrandTheme.primary.opacity(0.12) : BrandTheme.shadow.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    private func label(for product: StoreCatalogProduct) -> String {
        productIsActive(product) ? "Actual · \(product.displayPrice)" : product.ctaLabel
    }

    private func productIsActive(_ product: StoreCatalogProduct) -> Bool {
        activeProductIDs.contains(product.id)
    }

    @ViewBuilder
    private func purchaseButton(for product: StoreCatalogProduct) -> some View {
        let isActive = productIsActive(product)
        let isPurchasing = activePurchaseProductID == product.id
        let title = label(for: product)
        let button = Button {
            action(.purchase(product))
        } label: {
            HStack(spacing: 12) {
                Text(title)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .disabled(!canPurchase || activePurchaseProductID != nil || isActive)

        if isActive {
            button.buttonStyle(SecondaryCTAStyle())
        } else {
            button.buttonStyle(PrimaryCTAStyle())
        }
    }
}

private enum PremiumPlanAction {
    case keepFree
    case purchase(StoreCatalogProduct)
}
