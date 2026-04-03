import SwiftUI

struct OnboardingView: View {
    let onContinue: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                firstWinCard
                featureCard
                finishCard
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
            BrandBadge(text: "SpendSage", systemImage: "sparkles")
                .padding(.leading, 24)
                .padding(.top, 12)
        }
    }

    private var heroCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                BrandBadge(text: "First win in under a minute", systemImage: "sparkles")

                VStack(alignment: .leading, spacing: 10) {
                    Text("See your safe-to-spend number fast")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandTheme.ink)

                    Text("Start with a calm local experience, get one useful number quickly, and add an account later only if you want it.")
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 12) {
                    BrandMetricTile(title: "Setup", value: "Quick", systemImage: "bolt.fill")
                    BrandMetricTile(title: "Mode", value: "Local first", systemImage: "iphone.gen3")
                }
            }
        }
    }

    private var firstWinCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your first win")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text("The first pass focuses on one result you can act on right away, not a long setup.")
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

                BrandArtworkSurface {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("What you get first")
                                    .font(.headline)
                                    .foregroundStyle(BrandTheme.ink)
                                Text("A simple preview of the habit loop the app is designed around.")
                                    .font(.subheadline)
                                    .foregroundStyle(BrandTheme.muted)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(BrandTheme.primary)
                                .padding(12)
                                .background(
                                    Circle()
                                        .fill(BrandTheme.accent.opacity(0.22))
                                )
                        }

                        HStack(spacing: 12) {
                            BrandMetricTile(title: "Safe to spend", value: "Shown fast", systemImage: "banknote.fill")
                            BrandMetricTile(title: "Next move", value: "One tap", systemImage: "arrow.right.circle.fill")
                            BrandMetricTile(title: "Confidence", value: "High", systemImage: "checkmark.seal.fill")
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Setup progress")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(BrandTheme.muted)
                                Spacer()
                                Text("Quick start")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(BrandTheme.primary)
                            }

                            ProgressView(value: 0.7)
                                .tint(BrandTheme.primary)
                                .scaleEffect(y: 1.25, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private var featureCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Why it feels simple")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text("The app keeps the first screen focused on clarity, not setup debt.")
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

                BrandFeatureRow(
                    systemImage: "clock.fill",
                    title: "Fast start",
                    detail: "You can move from launch to a useful signal without a long setup."
                )

                BrandFeatureRow(
                    systemImage: "lock.fill",
                    title: "Private by default",
                    detail: "The local path stays on this device until you decide to connect an account."
                )

                BrandFeatureRow(
                    systemImage: "sparkles",
                    title: "Room to grow",
                    detail: "When you are ready, the app can expand into account-backed features and upgrades."
                )
            }
        }
    }

    private var finishCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ready to start")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text("You can create an account later if you want your access across devices.")
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

                Button("Get started", action: onContinue)
                    .buttonStyle(PrimaryCTAStyle())

                Text("This first pass stays local and light, so you can decide on an account later without friction.")
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
            }
        }
    }
}
