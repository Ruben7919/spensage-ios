import SwiftUI

struct OnboardingView: View {
    let onContinue: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                Spacer(minLength: 6)

                BrandBadge(text: "Smart budgeting, simplified", systemImage: "sparkles")

                VStack(alignment: .leading, spacing: 12) {
                    Text("Know your safe budget in under a minute")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandTheme.ink)

                    Text("Set up your budget, track your spending, and stay on top of your goals from day one.")
                        .font(.title3)
                        .foregroundStyle(BrandTheme.muted)
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Clear plan. Calm money decisions.")
                                    .font(.headline)
                                    .foregroundStyle(BrandTheme.ink)
                                Text("Get started quickly, keep your essentials in one place, and build better money habits with a setup that feels simple from the first screen.")
                                    .font(.subheadline)
                                    .foregroundStyle(BrandTheme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Image(systemName: "iphone.gen3")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(BrandTheme.primary)
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(BrandTheme.accent.opacity(0.22))
                                )
                        }

                        HStack(spacing: 12) {
                            BrandMetricTile(title: "Access", value: "Flexible", systemImage: "person.crop.circle")
                            BrandMetricTile(title: "Budget", value: "Personalized", systemImage: "chart.bar.xaxis")
                            BrandMetricTile(title: "Setup", value: "Fast", systemImage: "bolt.fill")
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Set up in a minute")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(BrandTheme.muted)
                                Spacer()
                                Text("Quick start")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(BrandTheme.primary)
                            }

                            ProgressView(value: 0.68)
                                .tint(BrandTheme.primary)
                                .scaleEffect(y: 1.25, anchor: .center)
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("What you get")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        BrandFeatureRow(
                            systemImage: "house.fill",
                            title: "Guided setup",
                            detail: "Get started with a simple flow that helps you build a clear budget quickly."
                        )

                        BrandFeatureRow(
                            systemImage: "rectangle.stack.fill",
                            title: "Clean money overview",
                            detail: "See your key numbers, recent activity, and budget progress in one place."
                        )

                        BrandFeatureRow(
                            systemImage: "arrow.triangle.branch",
                            title: "Room to grow",
                            detail: "Start with the essentials and unlock deeper tools as you go."
                        )
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Why it feels simple")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text("The experience is designed to stay clear, quick, and focused on the money moves that matter most every day.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 8) {
                            Label("Quick setup", systemImage: "checkmark.circle.fill")
                            Label("Expense tracking", systemImage: "checkmark.circle.fill")
                            Label("Private start", systemImage: "checkmark.circle.fill")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BrandTheme.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Button("Get started", action: onContinue)
                        .buttonStyle(PrimaryCTAStyle())

                    Text("You can create an account later if you want access across devices.")
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }
                .padding(.top, 4)
            }
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .overlay(alignment: .top) {
            BrandBackdropView()
        }
    }
}
