import SwiftUI

struct PremiumView: View {
    @ObservedObject var viewModel: AppViewModel
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
        .navigationTitle("Planes")
        .navigationBarTitleDisplayMode(.inline)
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
                            ? "Elige el nivel que quieres activar después. Si necesitas ayuda con pagos o restauración, la encuentras más abajo."
                            : "Compara planes primero. Luego inicia sesión si quieres que tus compras y restauración queden ligadas a tu cuenta."
                    )
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                BrandFeatureRow(
                    systemImage: currentStatus.systemImage,
                    title: AppLocalization.localized("Actual: %@", arguments: currentPlan.name.appLocalized),
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
                    detail: "Compara los niveles primero. Abre facturación solo si necesitas restaurar o revisar enlaces legales."
                )

                VStack(spacing: 12) {
                    ForEach(PremiumPlan.allCases) { plan in
                        PremiumPlanCard(
                            plan: plan,
                            isCurrent: plan.id == currentPlan.id,
                            canPreview: viewModel.session.isAuthenticated || plan.id == .freeLocal
                        ) {
                            select(plan: plan)
                        }
                    }
                }
            }
        }
    }

    private var billingDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                notice = viewModel.session.isAuthenticated
                    ? "Restaurar usará esta cuenta cuando activemos los pagos de App Store."
                    : "Inicia sesión primero para que futuras compras queden ligadas a tu cuenta cuando restaurar esté disponible."
            } label: {
                actionRow(
                    title: "Restaurar compras",
                    summary: "Revisa la ruta de restauración para esta cuenta.",
                    systemImage: "arrow.clockwise.circle.fill"
                )
            }
            .buttonStyle(.plain)

            Button {
                notice = "Gestionar suscripción abrirá la sección de pagos del sistema cuando activemos ese flujo."
            } label: {
                actionRow(
                    title: "Gestionar suscripción",
                    summary: "Abre después los controles de renovación y cancelación.",
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

    private func select(plan: PremiumPlan) {
        guard viewModel.session.isAuthenticated || plan.id == .freeLocal else {
            notice = "Inicia sesión primero para mantener la vista previa premium ligada a tu cuenta."
            return
        }

        switch plan.id {
        case .freeLocal:
            storedPlanID = PremiumPlan.ID.freeLocal.rawValue
            storedStatus = PremiumStatus.free.rawValue
            notice = "Local gratis sigue activo en este dispositivo."
        case .removeAds:
            storedPlanID = PremiumPlan.ID.removeAds.rawValue
            storedStatus = PremiumStatus.active.rawValue
            notice = AppLocalization.localized("%@ quedó seleccionado como mejora única para esta cuenta.", arguments: plan.name.appLocalized)
        case .pro, .family:
            storedPlanID = plan.id.rawValue
            storedStatus = currentStatus == .expired ? PremiumStatus.active.rawValue : PremiumStatus.trialing.rawValue
            notice = AppLocalization.localized("%@ quedó seleccionado como el plan principal de esta cuenta.", arguments: plan.name.appLocalized)
        }
    }

    private var currentStatus: PremiumStatus {
        guard viewModel.session.isAuthenticated else { return .free }
        return PremiumStatus(rawValue: storedStatus) ?? .free
    }

    private var currentPlan: PremiumPlan {
        let planID: PremiumPlan.ID
        if currentStatus == .free {
            planID = .freeLocal
        } else {
            planID = PremiumPlan.ID(rawValue: storedPlanID) ?? .pro
        }
        return PremiumPlan.allCases.first(where: { $0.id == planID }) ?? PremiumPlan.allCases[0]
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
        case .free: return "Local gratis".appLocalized
        case .trialing: return "Vista previa".appLocalized
        case .active: return "Premium listo".appLocalized
        case .expired: return "Ruta de renovación".appLocalized
        }
    }

    var billingSourceLabel: String {
        switch self {
        case .free: return "Estado local".appLocalized
        case .trialing, .active, .expired: return "Vista previa de Store".appLocalized
        }
    }

    func detail(plan: PremiumPlan) -> String {
        switch self {
        case .free:
            return AppLocalization.localized("%@ se mantiene local por ahora. Los pagos, compras y restauración desde App Store todavía no están activos.", arguments: plan.name.appLocalized)
        case .trialing:
            return AppLocalization.localized("%@ está seleccionado en esta vista. Los pagos todavía no están activos en esta versión.", arguments: plan.name.appLocalized)
        case .active:
            return AppLocalization.localized("%@ aparece como el plan listo en esta pantalla. Los pagos reales y la restauración se activarán cuando conectemos App Store.", arguments: plan.name.appLocalized)
        case .expired:
            return AppLocalization.localized("%@ está mostrando la ruta de recuperación. Renovar y restaurar serán acciones reales cuando activemos los pagos.", arguments: plan.name.appLocalized)
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

    static let allCases: [PremiumPlan] = [
        PremiumPlan(
            id: .freeLocal,
            name: "Local gratis",
            priceLabel: "$0",
            summary: "La base gratuita.",
            features: [
                "Presupuesto y registro en este dispositivo",
                "Todavía no hay sincronización en la nube ni pagos activos"
            ],
            isHighlighted: false
        ),
        PremiumPlan(
            id: .removeAds,
            name: "Quitar anuncios",
            priceLabel: "$7.99 pago único",
            summary: "Una compra única para usar la app sin anuncios.",
            features: [
                "Quita las superficies patrocinadas",
                "Mantiene la app en modo local"
            ],
            isHighlighted: false
        ),
        PremiumPlan(
            id: .pro,
            name: "Pro",
            priceLabel: "$4.99/mes o $29.99/año",
            summary: "Más automatización, más claridad y respaldo en la nube.",
            features: [
                "Sincronización en la nube y restauración entre dispositivos",
                "Escaneo inteligente de recibos y análisis más profundos"
            ],
            isHighlighted: true
        ),
        PremiumPlan(
            id: .family,
            name: "Familia",
            priceLabel: "$7.99/mes o $49.99/año",
            summary: "Un plan compartido para el hogar.",
            features: [
                "Todo lo incluido en Pro",
                "Espacio y metas compartidas del hogar"
            ],
            isHighlighted: false
        )
    ]
}

private struct PremiumPlanCard: View {
    let plan: PremiumPlan
    let isCurrent: Bool
    let canPreview: Bool
    let action: () -> Void

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

                    Text(plan.priceLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BrandTheme.primary)
                }

                Spacer(minLength: 0)
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

            if isCurrent {
                Button(action: action) {
                    Text("Actual".appLocalized)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryCTAStyle())
                .disabled(true)
            } else {
                Button(action: action) {
                    Text(
                        canPreview
                            ? AppLocalization.localized("Elegir %@", arguments: plan.name.appLocalized)
                            : "Inicia sesión para verlo".appLocalized
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryCTAStyle())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(BrandTheme.surfaceTint)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: BrandTheme.shadow.opacity(0.06), radius: 14, x: 0, y: 8)
    }
}
