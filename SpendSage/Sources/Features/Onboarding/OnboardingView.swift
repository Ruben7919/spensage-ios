import SwiftUI

struct OnboardingView: View {
    let onContinue: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                Spacer(minLength: 6)

                BrandBadge(text: "Phase 1 local-first shell", systemImage: "sparkles")

                VStack(alignment: .leading, spacing: 12) {
                    Text("Know your safe budget in under a minute")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandTheme.ink)

                    Text("This native track is intentionally narrow: make the shell feel premium, prove guest mode, and move the migration forward without waiting on backend work.")
                        .font(.title3)
                        .foregroundStyle(BrandTheme.muted)
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Native first. Local by default.")
                                    .font(.headline)
                                    .foregroundStyle(BrandTheme.ink)
                                Text("The first app shell keeps the highest-value flows fast and simple while the hybrid app continues shipping.")
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
                            BrandMetricTile(title: "Mode", value: "Guest local", systemImage: "person.crop.circle")
                            BrandMetricTile(title: "Budget", value: "Preview data", systemImage: "chart.bar.xaxis")
                            BrandMetricTile(title: "Speed", value: "SwiftUI", systemImage: "bolt.fill")
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Shell readiness")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(BrandTheme.muted)
                                Spacer()
                                Text("Phase 1")
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
                        Text("What this track is for")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        BrandFeatureRow(
                            systemImage: "house.fill",
                            title: "Local-first onboarding",
                            detail: "Keep the first-run experience crisp, grounded, and usable without account setup."
                        )

                        BrandFeatureRow(
                            systemImage: "rectangle.stack.fill",
                            title: "Reusable shell components",
                            detail: "Capture cards, badges, and CTA styles once so later native screens stay consistent."
                        )

                        BrandFeatureRow(
                            systemImage: "arrow.triangle.branch",
                            title: "Parallel migration",
                            detail: "Ship native screens in slices while the existing app keeps serving production traffic."
                        )
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Phase 1 guardrails")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text("Do not introduce backend dependency, purchase wiring, or auth complexity before the shell feels intentional and fast.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 8) {
                            Label("Guest mode", systemImage: "checkmark.circle.fill")
                            Label("Dashboard stub", systemImage: "checkmark.circle.fill")
                            Label("No backend lock", systemImage: "checkmark.circle.fill")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BrandTheme.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Button("Start native migration", action: onContinue)
                        .buttonStyle(PrimaryCTAStyle())

                    Text("This keeps the first native pass focused on polish, speed, and a clear migration path.")
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
