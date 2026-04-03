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
            summary: "Review how SpendSage handles on-device data, support handoff details, and public privacy commitments.",
            url: PublicLegalLinks.privacy,
            systemImage: "hand.raised.fill"
        ),
        LegalResource(
            title: "Support Center",
            summary: "Public support path for escalation, documentation, and future service updates.",
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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Legal Center")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)
                        Text("Open the current public legal and support pages for the dev environment directly from the app.")
                            .foregroundStyle(BrandTheme.muted)
                    }
                }

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
                        Text("Current build posture")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Label("Profile and ledger data are stored locally on this device.", systemImage: "lock.fill")
                        Label("Support packets are generated locally and can be shared manually.", systemImage: "square.and.arrow.up")
                        Label("Cloud-linked services are only available when your account access enables them.", systemImage: "icloud.slash")
                    }
                    .foregroundStyle(BrandTheme.ink)
                }
            }
            .padding(24)
        }
        .background(BrandTheme.canvas)
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
}
