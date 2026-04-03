import SwiftUI

struct PremiumView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedPlanID: PremiumPlan.ID = .pro
    @State private var notice: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                statusCard
                plansCard
                actionsCard

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
                    text: viewModel.session.isAuthenticated ? "Account ready" : "Local preview",
                    systemImage: "sparkles"
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Choose the plan that fits your budget routine")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandTheme.ink)

                    Text("Review the launch lineup, see what each tier unlocks, and keep the experience local until you are ready to connect billing.")
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
                        value: selectedPlan.name,
                        systemImage: "star.fill"
                    )
                }

                HStack(spacing: 8) {
                    TagChip(text: "Remove ads", systemImage: "rectangle.3.group")
                    TagChip(text: "Restore later", systemImage: "arrow.clockwise")
                    TagChip(text: "Family ready", systemImage: "person.3.fill")
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
                        Text(selectedPlan.summary)
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
                    BrandMetricTile(title: "Source", value: viewModel.session.isAuthenticated ? "Signed in" : "Guest local", systemImage: "arrow.left.arrow.right")
                    BrandMetricTile(title: "Restore", value: "Store-ready", systemImage: "arrow.clockwise")
                }

                Text("This screen mirrors the launch lineup so the app still feels complete before billing is wired to a live store flow.")
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
                        Text("Launch plans")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text("Tap a plan to preview its role in the lineup. Pricing stays descriptive here until store checkout is enabled.")
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
                        Button {
                            selectedPlanID = plan.id
                            notice = "Previewing \(plan.name). Store checkout can be connected later without changing this layout."
                        } label: {
                            PremiumPlanCard(plan: plan, isSelected: selectedPlanID == plan.id)
                        }
                        .buttonStyle(.plain)
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
                        Text("Keep the flow useful even before live billing lands.")
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
                            title: "Sign in to restore",
                            summary: "Attach purchases to an account before buying or restoring.",
                            systemImage: "person.crop.circle.badge.checkmark"
                        )
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    notice = "Restore purchases will connect to the store account once billing is wired in."
                } label: {
                    actionRow(
                        title: "Restore purchases",
                        summary: "Bring back a previous purchase on this device or another one.",
                        systemImage: "arrow.clockwise.circle.fill"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    notice = "Manage subscription will open the system-managed purchase settings when live billing is available."
                } label: {
                    actionRow(
                        title: "Manage subscription",
                        summary: "Review the current plan, renewal state, and cancellation options.",
                        systemImage: "slider.horizontal.3"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    notice = "This preview keeps plan selection local until store checkout is connected."
                } label: {
                    actionRow(
                        title: "Use the selected plan",
                        summary: "Continue with \(selectedPlan.name) in this preview screen.",
                        systemImage: "checkmark.circle.fill"
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

    private var selectedPlan: PremiumPlan {
        PremiumPlan.allCases.first(where: { $0.id == selectedPlanID }) ?? PremiumPlan.allCases[2]
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
    let isSelected: Bool

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

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? BrandTheme.primary : BrandTheme.muted)
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
                .fill(isSelected ? BrandTheme.surface : BrandTheme.surfaceTint)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isSelected ? BrandTheme.primary.opacity(0.9) : BrandTheme.line.opacity(0.8), lineWidth: isSelected ? 1.6 : 1)
        )
        .shadow(color: BrandTheme.shadow.opacity(isSelected ? 0.12 : 0.06), radius: 14, x: 0, y: 8)
    }
}
