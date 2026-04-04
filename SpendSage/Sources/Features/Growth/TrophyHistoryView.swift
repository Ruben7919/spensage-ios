import SwiftUI

struct TrophyHistoryView: View {
    @ObservedObject var viewModel: AppViewModel

    private var growthSnapshot: DashboardGrowthSnapshot {
        GrowthSnapshotBuilder.build(
            session: viewModel.session,
            state: viewModel.dashboardState,
            ledger: viewModel.ledger,
            accounts: viewModel.accounts,
            bills: viewModel.bills,
            rules: viewModel.rules,
            profile: viewModel.profile
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                trophyCollection
                trophyTimeline
                trophyFootnotes
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
        .background(
            ZStack {
                BrandTheme.canvas
                BrandBackdropView()
            }
            .ignoresSafeArea()
        )
        .overlay(alignment: .top) {
            BrandBackdropView()
        }
        .navigationTitle("Trophy History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                BrandBadge(text: "\(growthSnapshot.trophies.filter(\.unlocked).count) unlocked", systemImage: "trophy.fill")

                Text("Trophy collection")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandTheme.ink)

                Text("Track the wins that make the finance loop feel alive: streaks, budgeting, clean categories, and stronger daily habits.")
                    .foregroundStyle(BrandTheme.muted)

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(title: "Level", value: "\(growthSnapshot.level)", systemImage: "bolt.fill")
                    BrandMetricTile(title: "XP", value: "\(growthSnapshot.totalXP)", systemImage: "sparkles")
                    BrandMetricTile(title: "Unlocked", value: "\(growthSnapshot.trophies.filter(\.unlocked).count)", systemImage: "rosette")
                    BrandMetricTile(title: "Next level", value: "\(growthSnapshot.xpToNextLevel) XP", systemImage: "arrow.up.forward")
                }

                BrandArtworkSurface {
                    MascotSpeechCard(
                        character: .manchas,
                        expression: .proud,
                        title: "Progress lives here",
                        message: "Trophies and streaks reflect the habits already visible in your local ledger."
                    )
                }
            }
        }
    }

    private var trophyCollection: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Collection",
                    detail: "Unlocked trophies stay bright; the rest expose progress toward the next visible milestone."
                )

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(growthSnapshot.trophies) { trophy in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                GrowthTrophyPlate(trophy: trophy, size: 52)

                                Spacer(minLength: 0)

                                Text(trophy.unlocked ? "Unlocked".appLocalized : trophy.progressText.appLocalized)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(trophy.unlocked ? BrandTheme.primary : BrandTheme.muted)
                            }

                            Text(trophy.title.appLocalized)
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)
                            Text(trophy.detail.appLocalized)
                                .font(.subheadline)
                                .foregroundStyle(BrandTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)

                            ProgressView(value: trophy.progressRatio)
                                .tint(trophy.unlocked ? BrandTheme.primary : BrandTheme.muted.opacity(0.8))

                            if let unlockedAt = trophy.unlockedAt {
                                Text(unlockedAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BrandTheme.primary)
                            } else {
                                Text(AppLocalization.localized("Next unlock at %@", arguments: trophy.progressText.appLocalized))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BrandTheme.muted)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(BrandTheme.surfaceTint)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private var trophyTimeline: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Timeline",
                    detail: "A simple event stream built from unlocked trophies, category momentum, and coach prompts."
                )

                if growthSnapshot.events.isEmpty {
                    emptyTimeline
                } else {
                    ForEach(growthSnapshot.events) { event in
                        DashboardTimelineRow(event: event)
                    }
                }
            }
        }
    }

    private var trophyFootnotes: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeading(
                    title: "How trophies are earned",
                    detail: "Trophies react to the habits visible in your current ledger and help turn routine finance work into a repeatable loop."
                )

                Label("Add expenses consistently to grow streak-based badges faster.", systemImage: "flame.fill")
                Label("Accounts, bills, and rules unlock deeper trophies because the dashboard sees more of the month.", systemImage: "square.stack.3d.up")
                Label("A clean budget and regular review flow usually unlock the most visible wins first.", systemImage: "checkmark.seal.fill")
            }
            .foregroundStyle(BrandTheme.ink)
        }
    }

    private var emptyTimeline: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("No trophy events yet")
                .font(.headline)
                .foregroundStyle(BrandTheme.ink)
            Text("The first expense usually unlocks the first visible event in this timeline.")
                .font(.subheadline)
                .foregroundStyle(BrandTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BrandTheme.surfaceTint)
        )
    }

    private func sectionHeading(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.appLocalized)
                .font(.headline)
                .foregroundStyle(BrandTheme.ink)
            Text(detail.appLocalized)
                .font(.subheadline)
                .foregroundStyle(BrandTheme.muted)
        }
    }
}

private struct GrowthTrophyPlate: View {
    let trophy: GrowthTrophy
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(trophy.unlocked ? BrandTheme.heroGlowGradient : LinearGradient(
                    colors: [BrandTheme.surfaceTint, BrandTheme.surface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            if let image = BrandAssetCatalog.shared.image(for: BrandAssetCatalog.shared.badge(named: trophy.hybridBadgeAsset)) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(10)
            } else {
                Image(systemName: trophy.systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(trophy.unlocked ? BrandTheme.primary : BrandTheme.muted)
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(BrandTheme.line.opacity(0.82), lineWidth: 1)
        )
    }
}

private struct DashboardTimelineRow: View {
    let event: GrowthEvent

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(BrandTheme.accent.opacity(0.18))
                Image(systemName: event.systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(BrandTheme.primary)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title.appLocalized)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text(event.detail.appLocalized)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Text(event.occurredAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BrandTheme.primary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BrandTheme.surfaceTint)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
        )
    }
}
