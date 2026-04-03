import SwiftUI

private struct TrophyMilestone: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let systemImage: String
    let achieved: Bool
    let progress: String
}

struct TrophyHistoryView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        let trophies = buildTrophies()
        let earned = trophies.filter(\.achieved).count

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Trophy History")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)

                        Text("Celebrate the milestones already unlocked by your local ledger, plus the next wins available from the data on this device.")
                            .foregroundStyle(BrandTheme.muted)

                        BrandBadge(text: "\(earned) earned", systemImage: "trophy.fill")
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Progress")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        ProgressView(value: Double(earned), total: Double(max(trophies.count, 1)))
                            .tint(BrandTheme.primary)

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            BrandMetricTile(title: "Earned", value: "\(earned)", systemImage: "rosette")
                            BrandMetricTile(title: "Next goal", value: trophies.first(where: { !$0.achieved })?.title ?? "Complete", systemImage: "flag.checkered")
                        }
                    }
                }

                ForEach(trophies) { trophy in
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                Image(systemName: trophy.systemImage)
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(trophy.achieved ? BrandTheme.primary : BrandTheme.muted)
                                    .frame(width: 48, height: 48)
                                    .background((trophy.achieved ? BrandTheme.accent : BrandTheme.surfaceTint).opacity(0.28))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(trophy.title)
                                        .font(.headline)
                                        .foregroundStyle(BrandTheme.ink)
                                    Text(trophy.detail)
                                        .foregroundStyle(BrandTheme.muted)
                                }

                                Spacer()

                                Text(trophy.achieved ? "Unlocked" : "In progress")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(trophy.achieved ? BrandTheme.primary : BrandTheme.muted)
                            }

                            Text(trophy.progress)
                                .font(.subheadline)
                                .foregroundStyle(BrandTheme.ink)
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .navigationTitle("Trophy History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func buildTrophies() -> [TrophyMilestone] {
        let state = viewModel.dashboardState
        let expenseCount = state?.transactionCount ?? 0
        let accounts = viewModel.accounts.count
        let bills = viewModel.bills.count
        let rules = viewModel.rules.count
        let profileCustomized = viewModel.profile.fullName != ProfileRecord.default.fullName || viewModel.profile.householdName != ProfileRecord.default.householdName
        let stayingOnBudget = (state?.budgetSnapshot.remaining ?? 0) >= 0 && expenseCount > 0

        return [
            TrophyMilestone(
                title: "First expense logged",
                detail: "You started the native ledger with a real transaction.",
                systemImage: "1.circle.fill",
                achieved: expenseCount >= 1,
                progress: "\(expenseCount)/1 expense saved locally"
            ),
            TrophyMilestone(
                title: "Five-transaction streak",
                detail: "You have enough activity for meaningful budget and category insights.",
                systemImage: "flame.fill",
                achieved: expenseCount >= 5,
                progress: "\(min(expenseCount, 5))/5 recent expenses"
            ),
            TrophyMilestone(
                title: "Rule architect",
                detail: "You created at least one merchant rule to improve local categorization.",
                systemImage: "point.3.filled.connected.trianglepath.dotted",
                achieved: rules >= 1,
                progress: "\(rules) rule\(rules == 1 ? "" : "s") saved"
            ),
            TrophyMilestone(
                title: "Bill keeper",
                detail: "Recurring obligations are tracked inside the device ledger.",
                systemImage: "calendar.badge.clock",
                achieved: bills >= 1,
                progress: "\(bills) bill\(bills == 1 ? "" : "s") configured"
            ),
            TrophyMilestone(
                title: "Account stack",
                detail: "You are tracking multiple financial buckets, not just spend.",
                systemImage: "building.columns.fill",
                achieved: accounts >= 2,
                progress: "\(accounts)/2 accounts added"
            ),
            TrophyMilestone(
                title: "Budget guardian",
                detail: "Current monthly spend is still within the target budget.",
                systemImage: "shield.checkered",
                achieved: stayingOnBudget,
                progress: stayingOnBudget ? "Remaining budget is positive." : "Spend is above budget or not tracked yet."
            ),
            TrophyMilestone(
                title: "Identity tuned",
                detail: "Your profile is customized for the household using this device.",
                systemImage: "person.crop.circle.badge.checkmark",
                achieved: profileCustomized,
                progress: profileCustomized ? "Profile record updated." : "Customize the local profile to unlock this trophy."
            )
        ]
    }
}
