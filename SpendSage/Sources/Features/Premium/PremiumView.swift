import SwiftUI

struct PremiumView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var notice: String?
    @AppStorage("native.premium.status") private var storedStatus = PremiumStatus.free.rawValue

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                statusCard
                plansCard
                ExperienceDisclosureCard(
                    title: "Billing tools",
                    summary: "Restore, manage, sync, and legal links stay available without crowding the upgrade choice.",
                    character: .mei,
                    expression: .proud
                ) {
                    actionsCard
                    billingTrustCard
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
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.large)
    }

    private var heroCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                BrandBadge(
                    text: currentStatus.badgeTitle,
                    systemImage: "sparkles"
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Choose what you want unlocked next".appLocalized)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandTheme.ink)

                    Text(
                        viewModel.session.isAuthenticated
                            ? "Review the plan preview, account restore readiness, and what unlocks later once store billing is connected.".appLocalized
                            : "Free mode stays on this device. Sign in first so future purchases can attach to your account once billing is connected.".appLocalized
                    )
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                BrandArtworkSurface {
                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("This screen previews plans, value, and account readiness without pretending checkout is already live.".appLocalized)
                                .font(.subheadline)
                                .foregroundStyle(BrandTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)

                            BrandMetricTile(
                                title: "Access",
                                value: sessionLabel,
                                systemImage: "person.crop.circle"
                            )

                            BrandBadge(
                                text: currentPlan.name,
                                systemImage: "star.fill"
                            )
                        }

                        BrandAssetImage(
                            source: BrandAssetCatalog.shared.guide("guide_19_pricing_cards_tikki"),
                            fallbackSystemImage: "sparkles"
                        )
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 126, height: 126)
                    }
                }

                MascotSpeechCard(
                    character: .mei,
                    expression: currentStatus == .expired ? .warning : .proud,
                    title: "Ludo",
                    message: viewModel.session.isAuthenticated
                        ? "You can review plan structure and restore readiness now. Real purchases activate once Store billing is connected."
                        : "You can stay local for now. Sign in first, then the upgrade path will be ready when billing goes live."
                )

                CharacterCrewRail(
                    members: [
                        CharacterCrewMember(
                            title: "Tikki",
                            role: "Plan guide",
                            detail: "Helps you compare the plans without adding pressure.",
                            character: .tikki,
                            expression: .proud
                        ),
                        CharacterCrewMember(
                            title: "Ludo",
                            role: "Billing preview",
                            detail: "Keeps restore and account readiness easy to understand.",
                            character: .mei,
                            expression: .proud
                        ),
                        CharacterCrewMember(
                            title: "Manchas",
                            role: "Value map",
                            detail: "Keeps the upgrade focused on what actually improves next.",
                            character: .manchas,
                            expression: .happy
                        )
                    ]
                )

                HStack(spacing: 12) {
                    BrandMetricTile(
                        title: "Access",
                        value: sessionLabel,
                        systemImage: "person.crop.circle"
                    )
                    BrandMetricTile(
                        title: "Current plan",
                        value: currentPlan.name.appLocalized,
                        systemImage: "star.fill"
                    )
                    BrandMetricTile(
                        title: "Status",
                        value: currentStatus.label,
                        systemImage: currentStatus.systemImage
                    )
                }

                HStack(spacing: 8) {
                    TagChip(text: "Plan preview", systemImage: "rectangle.3.group")
                    TagChip(text: "Restore path", systemImage: "arrow.clockwise")
                    TagChip(text: "Family planned", systemImage: "person.3.fill")
                }

            }
        }
    }

    private var statusCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text(currentStatus.detail(plan: currentPlan))
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 12) {
                    BrandMetricTile(title: "Plan", value: currentPlan.name.appLocalized, systemImage: "star.fill")
                    BrandMetricTile(title: "Source", value: viewModel.session.isAuthenticated ? "Account".appLocalized : "Not linked".appLocalized, systemImage: "arrow.left.arrow.right")
                    BrandMetricTile(title: "Billing", value: currentStatus.billingSourceLabel, systemImage: "creditcard.fill")
                    BrandMetricTile(title: "Restore", value: viewModel.session.isAuthenticated ? "Account-ready".appLocalized : "Sign in first".appLocalized, systemImage: "arrow.clockwise")
                }

                Text("Store billing, renewals, and restore are not live in this build yet. This screen defines the plan structure and trust path clearly.".appLocalized)
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
            }
        }
    }

    private var plansCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Plans")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text("These tiers are product previews for now. Real checkout and localized pricing will appear once Store billing is connected.".appLocalized)
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(spacing: 12) {
                    ForEach(PremiumPlan.allCases) { plan in
                        PremiumPlanCard(plan: plan)
                    }
                }
            }
        }
    }

    private var actionsCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Actions")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text("Use these actions to preview the purchase flow and account readiness without implying live billing.".appLocalized)
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Button {
                    notice = viewModel.session.isAuthenticated
                        ? "Restore will use this signed-in account once Store billing is connected. For now, this is a readiness preview."
                        : "Sign in first so future purchases can attach to your account when restore becomes available."
                } label: {
                    actionRow(
                        title: "Restore purchases",
                        summary: "Preview how past purchases will be recovered on this device or another one later.",
                        systemImage: "arrow.clockwise.circle.fill"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    notice = "Manage subscription will open the system billing center once checkout is connected."
                } label: {
                    actionRow(
                        title: "Manage subscription",
                        summary: "Preview renewal, plan details, and cancellation entry points.",
                        systemImage: "slider.horizontal.3"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    notice = "Billing preview refreshed."
                } label: {
                    actionRow(
                        title: "Sync status",
                        summary: "Refresh the current billing preview without leaving the screen.",
                        systemImage: "arrow.triangle.2.circlepath"
                    )
                }
                .buttonStyle(.plain)

                Text("Premium stays guided by the crew so the upgrade path feels clear and trustworthy, not sales-heavy.".appLocalized)
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)

                Button {
                    if currentPlan.id == .freeLocal {
                        storedStatus = PremiumStatus.free.rawValue
                        notice = "Free local stays active on this device."
                    } else if currentStatus == .expired {
                        storedStatus = PremiumStatus.active.rawValue
                        notice = AppLocalization.localized("%@ is selected as the next billing preview. The status card now reads as recovered access.", arguments: currentPlan.name.appLocalized)
                    } else {
                        storedStatus = currentPlan.id == .removeAds ? PremiumStatus.active.rawValue : PremiumStatus.trialing.rawValue
                        notice = AppLocalization.localized("%@ is now the active plan preview on this screen.", arguments: currentPlan.name.appLocalized)
                    }
                } label: {
                    actionRow(
                        title: currentPlan.id == .freeLocal
                            ? "Stay on free local"
                            : currentStatus == .expired ? "Renew now" : AppLocalization.localized("Preview %@", arguments: currentPlan.name.appLocalized),
                        summary: currentPlan.id == .freeLocal
                            ? "Keep the app local and light while billing stays disconnected."
                            : currentStatus == .expired
                                ? "Preview the recovery path and keep restore plus billing context one tap away."
                                : "Switch this screen to the selected plan preview and keep the trust context visible.",
                        systemImage: "checkmark.circle.fill"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var billingTrustCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Legal and trust")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text("Privacy and terms stay one tap away from the upgrade path.".appLocalized)
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                NavigationLink {
                    LegalCenterView(initialSection: .terms)
                } label: {
                    actionRow(
                        title: "Terms",
                        summary: "Review the public legal documents without leaving the premium surface.",
                        systemImage: "doc.text.fill"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    LegalCenterView(initialSection: .privacy)
                } label: {
                    actionRow(
                        title: "Privacy",
                        summary: "Review the privacy policy without leaving the premium surface.",
                        systemImage: "hand.raised.fill"
                    )
                }
                .buttonStyle(.plain)
            }
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
                    Text("Status")
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

    private var sessionLabel: String {
        switch viewModel.session {
        case .signedOut:
            return "Signed out".appLocalized
        case .guest:
            return "Preview guest".appLocalized
        case .signedIn:
            return "Signed in".appLocalized
        }
    }

    private var currentStatus: PremiumStatus {
        guard viewModel.session.isAuthenticated else { return .free }
        return PremiumStatus(rawValue: storedStatus) ?? .free
    }

    private var currentPlan: PremiumPlan {
        switch currentStatus {
        case .free:
            return PremiumPlan.allCases.first(where: { $0.id == .freeLocal }) ?? PremiumPlan.allCases[0]
        case .trialing, .active, .expired:
            return PremiumPlan.allCases.first(where: { $0.id == .pro }) ?? PremiumPlan.allCases[2]
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
        case .free: return "Free".appLocalized
        case .trialing: return "Preview".appLocalized
        case .active: return "Ready".appLocalized
        case .expired: return "Needs review".appLocalized
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
        case .free: return "Free local".appLocalized
        case .trialing: return "Plan preview".appLocalized
        case .active: return "Premium ready".appLocalized
        case .expired: return "Renewal path".appLocalized
        }
    }

    var billingSourceLabel: String {
        switch self {
        case .free: return "Local state".appLocalized
        case .trialing, .active, .expired: return "Store preview".appLocalized
        }
    }

    func detail(plan: PremiumPlan) -> String {
        switch self {
        case .free:
            return AppLocalization.localized("%@ stays local in this build. Store billing, purchases, and restore are still pending integration.", arguments: plan.name.appLocalized)
        case .trialing:
            return AppLocalization.localized("%@ is selected as the current plan preview. Billing is not attached yet in this build.", arguments: plan.name.appLocalized)
        case .active:
            return AppLocalization.localized("%@ is marked as the ready plan on this screen. Real checkout and restore still require store integration.", arguments: plan.name.appLocalized)
        case .expired:
            return AppLocalization.localized("%@ is using the recovery preview. Renewal and restore will become real actions once billing is connected.", arguments: plan.name.appLocalized)
        }
    }
}

private struct TagChip: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label {
            Text(text.appLocalized)
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(BrandTheme.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(BrandTheme.surfaceTint, in: Capsule())
        .overlay(
            Capsule(style: .continuous)
                .stroke(BrandTheme.line.opacity(0.85), lineWidth: 1)
        )
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
            name: "Free Local",
            priceLabel: "$0",
            summary: "Current local mode with the main budgeting and tracking loop available on-device.",
            features: [
                "Current: local ledger, dashboard, and budgets",
                "Current: accounts, bills, and rules",
                "Current: smart fill and receipt drafts",
                "No cloud sync or store billing yet"
            ],
            isHighlighted: false
        ),
        PremiumPlan(
            id: .removeAds,
            name: "Remove Ads",
            priceLabel: "$7.99 one-time",
            summary: "Planned one-time unlock for people who want a quieter local-only experience.",
            features: [
                "Planned: removes sponsor surfaces",
                "Keeps the app local-only",
                "Does not depend on cloud sync",
                "Planned: restorable through the store account"
            ],
            isHighlighted: false
        ),
        PremiumPlan(
            id: .pro,
            name: "Pro",
            priceLabel: "$4.99/month or $29.99/year",
            summary: "Planned main subscription once billing and cloud-backed features are connected.",
            features: [
                "Current: premium plan preview and guidance",
                "Planned: cloud sync and cross-device restore",
                "Planned: OCR receipts and deeper insights",
                "Planned: ad-free experience and support upgrades"
            ],
            isHighlighted: true
        ),
        PremiumPlan(
            id: .family,
            name: "Family",
            priceLabel: "$7.99/month or $49.99/year",
            summary: "Planned shared plan once household sync and collaboration are implemented.",
            features: [
                "Everything planned in Pro",
                "Planned: shared household space",
                "Planned: family goals and collaboration",
                "Planned: shared notifications and review loops"
            ],
            isHighlighted: false
        )
    ]
}

private struct PremiumPlanCard: View {
    let plan: PremiumPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(plan.name.appLocalized)
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        if plan.isHighlighted {
                            BrandBadge(text: "Recommended", systemImage: "sparkles")
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
