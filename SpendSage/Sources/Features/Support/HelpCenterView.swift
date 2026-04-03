import SwiftUI

private struct HelpTopic: Identifiable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String
}

private struct HelpFlowStep: Identifiable {
    let id: Int
    let title: String
    let detail: String
}

struct HelpCenterView: View {
    let viewModel: AppViewModel?

    @State private var expandedTopics: Set<String> = ["budgets"]

    private let topics: [HelpTopic] = [
        HelpTopic(
            id: "setupFamily",
            title: "How should I start in local mode?",
            detail: "Continue as guest if you want a fast private start. Your ledger stays on this iPhone until you decide to sign in and unlock cloud-linked features.",
            systemImage: "iphone.gen3"
        ),
        HelpTopic(
            id: "budgets",
            title: "What does the budget wizard actually change?",
            detail: "It saves your monthly income and monthly budget locally. Dashboard and Insights then use those values to calculate remaining safe budget, utilization, and pacing.",
            systemImage: "wand.and.stars"
        ),
        HelpTopic(
            id: "scanAutosave",
            title: "Why are some advanced tools unavailable here?",
            detail: "Some tools depend on account access or connected services. Until those are enabled, the app keeps the freemium path focused on private on-device workflows.",
            systemImage: "lock.shield.fill"
        ),
        HelpTopic(
            id: "insightsLanguage",
            title: "Where do I tune the experience?",
            detail: "Use Settings for language, currency, theme, and reminders. Advanced Settings is where you inspect exports, diagnostics, and support-ready packets.",
            systemImage: "slider.horizontal.3"
        ),
        HelpTopic(
            id: "security",
            title: "How do support and legal handoff work?",
            detail: "Support packets are generated locally and shared only when you choose. Legal Center opens the public privacy, terms, and support documents for the current environment.",
            systemImage: "lifepreserver.fill"
        )
    ]

    private let flow: [HelpFlowStep] = [
        HelpFlowStep(id: 1, title: "Start with budget basics", detail: "Open the budget wizard, set income and budget, then review your remaining safe budget."),
        HelpFlowStep(id: 2, title: "Build your local ledger", detail: "Add expenses, accounts, bills, and rules to make summaries and exports more accurate."),
        HelpFlowStep(id: 3, title: "Use support-ready handoff", detail: "If something feels off, open Support Center and generate a packet before reaching out."),
    ]

    init(viewModel: AppViewModel? = nil) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Guided help",
                    title: "Help Center",
                    summary: "Practical answers for budgeting, local-first setup, and where to go next when you need support or legal clarity.",
                    systemImage: "questionmark.circle.fill"
                )

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick start")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        HStack(spacing: 12) {
                            BrandMetricTile(title: "Mode", value: "Local-first", systemImage: "lock.fill")
                            BrandMetricTile(title: "Budget", value: "Guided", systemImage: "chart.bar.xaxis")
                            BrandMetricTile(title: "Support", value: "Packet-ready", systemImage: "paperplane.fill")
                        }

                        Text("The smoothest setup is to define your budget first, then add expenses, and only use support or legal tools when you actually need them.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Frequently asked")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        ForEach(topics) { topic in
                            DisclosureGroup(isExpanded: expansionBinding(for: topic.id)) {
                                Text(topic.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(BrandTheme.muted)
                                    .padding(.top, 8)
                            } label: {
                                FinanceToolRowLabel(
                                    title: topic.title,
                                    summary: "Tap to expand the guided answer.",
                                    systemImage: topic.systemImage
                                )
                            }

                            if topic.id != topics.last?.id {
                                Divider()
                            }
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Recommended flow")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        ForEach(flow) { step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(step.id)")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 30, height: 30)
                                    .background(BrandTheme.primary)
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(step.title)
                                        .font(.headline)
                                        .foregroundStyle(BrandTheme.ink)
                                    Text(step.detail)
                                        .font(.subheadline)
                                        .foregroundStyle(BrandTheme.muted)
                                }
                            }
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Need more help?")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text("Move from guidance into action with support and legal paths that match this local-first build.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)

                        if let viewModel {
                            NavigationLink {
                                SupportCenterView(viewModel: viewModel)
                            } label: {
                                helpRouteLabel(
                                    title: "Open Support Center",
                                    summary: "Create a packet, copy diagnostics, and open an email draft.",
                                    systemImage: "lifepreserver.fill"
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        NavigationLink {
                            LegalCenterView()
                        } label: {
                            helpRouteLabel(
                                title: "Open Legal Center",
                                summary: "Review privacy, terms, and public support links.",
                                systemImage: "doc.text.fill"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .overlay(alignment: .top) {
            BrandBackdropView()
        }
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func expansionBinding(for topicID: String) -> Binding<Bool> {
        Binding(
            get: { expandedTopics.contains(topicID) },
            set: { isExpanded in
                if isExpanded {
                    expandedTopics.insert(topicID)
                } else {
                    expandedTopics.remove(topicID)
                }
            }
        )
    }

    private func helpRouteLabel(title: String, summary: String, systemImage: String) -> some View {
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
    }
}
