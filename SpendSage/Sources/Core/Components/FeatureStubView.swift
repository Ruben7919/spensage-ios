import SwiftUI

struct FeatureStubView: View {
    let title: String
    let summary: String
    let readiness: String
    let bullets: [String]
    let systemImage: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: systemImage)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(BrandTheme.primary)
                                .frame(width: 48, height: 48)
                                .background(BrandTheme.accent.opacity(0.18))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                            VStack(alignment: .leading, spacing: 6) {
                                Text(title)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(BrandTheme.ink)
                                Text(summary)
                                    .foregroundStyle(BrandTheme.muted)
                            }
                        }

                        HStack {
                            Text("Availability")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BrandTheme.muted)
                            Spacer()
                            Text(readiness)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BrandTheme.primary)
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What to expect")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        ForEach(bullets, id: \.self) { bullet in
                            Label(bullet, systemImage: "checkmark.circle")
                                .foregroundStyle(BrandTheme.ink)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
