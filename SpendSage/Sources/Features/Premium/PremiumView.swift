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
                actionsCard
                billingTrustCard

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
            VStack(alignment: .leading, spacing: 16) {
                BrandBadge(
                    text: currentStatus.badgeTitle,
                    systemImage: "sparkles"
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Choose the plan that fits your budget routine")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandTheme.ink)

                    Text(viewModel.session.isAuthenticated
                         ? "Review the current plans and keep billing, restore, sync, and legal actions close in one place."
                         : "Free mode stays on this device. Sign in or create an account before buying so upgrades can be restored across devices later.")
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 12) {
                    BrandMetricTile(
                        title: "Access",
                        value: sessionLabel,
                        systemImage: "person.crop.circle"
                    )
                    BrandMetricTile(
                        title: "Current plan",
                        value: currentPlan.name,
                        systemImage: "star.fill"
                    )
                    BrandMetricTile(
                        title: "Status",
                        value: currentStatus.label,
                        systemImage: currentStatus.systemImage
                    )
                }

                HStack(spacing: 8) {
                    TagChip(text: "Remove ads", systemImage: "rectangle.3.group")
                    TagChip(text: "Restore ready", systemImage: "arrow.clockwise")
                    TagChip(text: "Family ready", systemImage: "person.3.fill")
                }

                Text(viewModel.session.isAuthenticated
                     ? "Subscription state, restore, billing, sync, and legal links stay visible from this same surface."
                     : "Create an account before purchasing so the upgrade can be restored across devices later.")
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
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

                    Spacer(minLength: 0)

                    Text("01")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(BrandTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(BrandTheme.accent.opacity(0.18), in: Capsule())
                }

                HStack(spacing: 12) {
                    BrandMetricTile(title: "Plan", value: currentPlan.name, systemImage: "star.fill")
                    BrandMetricTile(title: "Source", value: viewModel.session.isAuthenticated ? "Account" : "Guest local", systemImage: "arrow.left.arrow.right")
                    BrandMetricTile(title: "Billing", value: currentStatus.billingSourceLabel, systemImage: "creditcard.fill")
                    BrandMetricTile(title: "Restore", value: viewModel.session.isAuthenticated ? "Available" : "Sign in first", systemImage: "arrow.clockwise")
                }

                Text("Auto-renew, restore, manage subscription, and legal actions stay visible here so the paywall feels like a real billing surface.")
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
                        Text("Apple and Google will show the localized checkout price. Choose the plan that matches the billing action you want to take.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Text("02")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(BrandTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(BrandTheme.accent.opacity(0.18), in: Capsule())
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
                        Text(viewModel.session.isAuthenticated
                             ? "Restore, renew, sync, and manage actions stay on the same billing surface."
                             : "Create an account or sign in before buying so the purchase can be restored later.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Text("03")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(BrandTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(BrandTheme.accent.opacity(0.18), in: Capsule())
                }

                if isGuestSession {
                    NavigationLink {
                        AuthView(viewModel: viewModel)
                    } label: {
                        actionRow(
                            title: "Create account",
                            summary: "Attach purchases to an account before buying, restoring, or managing billing.",
                            systemImage: "person.crop.circle.badge.checkmark"
                        )
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    notice = viewModel.session.isAuthenticated
                        ? "Restore purchases is ready for the signed-in account. When store billing is live, prior purchases will come back from the same account."
                        : "Sign in before restoring so the purchase can attach to an account."
                } label: {
                    actionRow(
                        title: "Restore purchases",
                        summary: "Bring back a previous purchase on this device or another one.",
                        systemImage: "arrow.clockwise.circle.fill"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    notice = "Manage subscription will open the system billing center when checkout is live."
                } label: {
                    actionRow(
                        title: "Manage subscription",
                        summary: "Review renewal state, plan details, and cancellation options.",
                        systemImage: "slider.horizontal.3"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    notice = "Subscription status refreshed."
                } label: {
                    actionRow(
                        title: "Sync status",
                        summary: "Refresh the current billing state without leaving the screen.",
                        systemImage: "arrow.triangle.2.circlepath"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    if currentPlan.id == .freeLocal {
                        storedStatus = PremiumStatus.free.rawValue
                        notice = "Free Local stays active on this device."
                    } else if currentStatus == .expired {
                        storedStatus = PremiumStatus.active.rawValue
                        notice = "Renew now is selected for \(currentPlan.name). The status card now reads as recovered premium access."
                    } else {
                        storedStatus = currentPlan.id == .removeAds ? PremiumStatus.active.rawValue : PremiumStatus.trialing.rawValue
                        notice = "Continue with \(currentPlan.name). The billing surface now reflects the current plan."
                    }
                } label: {
                    actionRow(
                        title: currentPlan.id == .freeLocal
                            ? "Stay on free local"
                            : currentStatus == .expired ? "Renew now" : "Continue with \(currentPlan.name)",
                        summary: currentPlan.id == .freeLocal
                            ? "Keep the app local and light while billing stays disconnected."
                            : currentStatus == .expired
                                ? "Recover premium access and keep restore plus billing management one tap away."
                                : "Continue with the current plan and keep restore plus billing context visible.",
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
                        Text("Privacy and terms stay one tap away from the paywall.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Text("04")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(BrandTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(BrandTheme.accent.opacity(0.18), in: Capsule())
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
                    Text(message)
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
                Text(title)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text(summary)
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
            return "Signed out"
        case .guest:
            return "Guest local"
        case .signedIn:
            return "Signed in"
        }
    }

    private var isGuestSession: Bool {
        if case .guest = viewModel.session {
            return true
        }
        return false
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
        case .free: return "Free"
        case .trialing: return "Trialing"
        case .active: return "Active"
        case .expired: return "Expired"
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
        case .free: return "Free local"
        case .trialing: return "Trial in progress"
        case .active: return "Premium active"
        case .expired: return "Renewal needed"
        }
    }

    var billingSourceLabel: String {
        switch self {
        case .free: return "Local state"
        case .trialing, .active, .expired: return "Store-ready"
        }
    }

    func detail(plan: PremiumPlan) -> String {
        switch self {
        case .free:
            return "You are on \(plan.name). Free mode stays local, sponsor surfaces may remain visible, and account-backed restore starts after sign-in."
        case .trialing:
            return "You are on \(plan.name) as trialing. Billing is already attached and the trial window is active."
        case .active:
            return "You are on \(plan.name) as active. Restore, billing, and legal links should all stay one tap away."
        case .expired:
            return "The \(plan.name) plan is expired. Renewal, restore, and billing now read as recovery actions instead of activation actions."
        }
    }
}

private struct TagChip: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label {
            Text(text)
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
            summary: "Start free, stay on-device, and keep the experience light until you are ready for more.",
            features: [
                "Guest mode and local expense tracking",
                "Dashboard overview",
                "Light sponsor surfaces",
                "No cloud sync or premium tools"
            ],
            isHighlighted: false
        ),
        PremiumPlan(
            id: .removeAds,
            name: "Remove Ads",
            priceLabel: "$7.99 one-time",
            summary: "A low-friction upgrade for users who want a quieter local experience.",
            features: [
                "Removes sponsor surfaces",
                "Keeps the app local-only",
                "Does not unlock cloud sync",
                "Restorable through the store account"
            ],
            isHighlighted: false
        ),
        PremiumPlan(
            id: .pro,
            name: "Pro",
            priceLabel: "$4.99/month or $29.99/year",
            summary: "The main upgrade for serious personal finance use. Annual should be the default choice.",
            features: [
                "Cloud sync and cross-device restore",
                "Receipt scan, AI insights, and exports",
                "Recurring bills, accounts, and rules",
                "Ad-free experience"
            ],
            isHighlighted: true
        ),
        PremiumPlan(
            id: .family,
            name: "Family",
            priceLabel: "$7.99/month or $49.99/year",
            summary: "Shared spaces and household budgeting for people managing money together.",
            features: [
                "Everything in Pro",
                "Shared spaces and collaboration",
                "Family budgeting workflows",
                "Higher-value upsell for active households"
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
                        Text(plan.name)
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

            Text(plan.summary)
                .font(.subheadline)
                .foregroundStyle(BrandTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(plan.features, id: \.self) { feature in
                    Label(feature, systemImage: "checkmark.circle.fill")
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
