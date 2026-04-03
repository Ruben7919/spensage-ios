import SwiftUI
import UIKit

private struct LegalResource: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let url: URL
    let systemImage: String
}

struct LegalCenterView: View {
    @Environment(\.openURL) private var openURL
    @State private var copiedLinks = false

    private let resources: [LegalResource] = [
        LegalResource(
            title: "Privacy Policy",
            summary: "Review how SpendSage handles on-device data, support packet details, and public privacy commitments.",
            url: PublicLegalLinks.privacy,
            systemImage: "hand.raised.fill"
        ),
        LegalResource(
            title: "Support Center",
            summary: "Open the public support path for documentation and troubleshooting follow-up.",
            url: PublicLegalLinks.support,
            systemImage: "lifepreserver.fill"
        ),
        LegalResource(
            title: "Terms of Use",
            summary: "Read the public terms that apply to using SpendSage and its finance features.",
            url: PublicLegalLinks.terms,
            systemImage: "doc.text.fill"
        )
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                heroCard

                ForEach(resources) { resource in
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            BrandFeatureRow(systemImage: resource.systemImage, title: resource.title, detail: resource.summary)

                            Text(resource.url.absoluteString)
                                .font(.footnote.monospaced())
                                .foregroundStyle(BrandTheme.muted)
                                .textSelection(.enabled)

                            HStack(spacing: 12) {
                                Button("Open") {
                                    openURL(resource.url)
                                }
                                .buttonStyle(PrimaryCTAStyle())

                                Button("Copy link") {
                                    UIPasteboard.general.string = resource.url.absoluteString
                                    copiedLinks = true
                                }
                                .buttonStyle(SecondaryCTAStyle())
                            }
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current data posture")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Label("Profile and ledger data are stored on this device.", systemImage: "lock.fill")
                        Label("Support packets are generated locally and can be shared manually.", systemImage: "square.and.arrow.up")
                        Label("Cloud features stay hidden until you sign in to a cloud-enabled account.", systemImage: "icloud")
                    }
                    .foregroundStyle(BrandTheme.ink)
                }
            }
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .overlay(alignment: .top) {
            BrandBackdropView()
        }
        .navigationTitle("Legal Center")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if copiedLinks {
                Text("Legal link copied")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(BrandTheme.surface)
                    .clipShape(Capsule(style: .continuous))
                    .shadow(color: BrandTheme.shadow.opacity(0.12), radius: 12, x: 0, y: 6)
                    .padding(.bottom, 18)
            }
        }
    }

    private var heroCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                BrandBadge(text: "Trust center", systemImage: "hand.raised.fill")

                Text("Legal Center")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandTheme.ink)

                Text("Open privacy, support, and terms pages that match this local-first build without leaving the app.")
                    .foregroundStyle(BrandTheme.muted)

                BrandArtworkSurface {
                    VStack(alignment: .leading, spacing: 16) {
                        BrandAssetImage(
                            source: BrandAssetCatalog.shared.guide("guide_06_sharing_family_manchas"),
                            fallbackSystemImage: "doc.text.fill"
                        )
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)

                        MascotSpeechCard(
                            character: .tikki,
                            expression: .proud,
                            title: "Trust should stay close",
                            message: "When privacy and support are easy to open, testing feels safer and every packet stays easier to review."
                        )
                    }
                }
            }
        }
    }
}
