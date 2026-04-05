import SwiftUI
import UIKit

enum LegalTopic: String {
    case privacy
    case support
    case terms
}

struct LegalCenterView: View {
    private let initialSection: LegalTopic?

    init(initialSection: LegalTopic? = nil) {
        self.initialSection = initialSection
    }

    private var initialDocument: LegalDocumentResource? {
        guard let initialSection else { return nil }
        return LegalDocumentLibrary.document(for: initialSection)
    }

    var body: some View {
        Group {
            if let initialDocument {
                LegalDocumentDetailView(document: initialDocument)
            } else {
                LegalDocumentLibraryView()
            }
        }
        .background(BrandTheme.canvas)
        .overlay(alignment: .top) {
            BrandBackdropView()
        }
    }
}

private struct LegalDocumentLibraryView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 14) {
                            MascotAvatarView(character: .mei, expression: .proud, size: 76)

                            VStack(alignment: .leading, spacing: 10) {
                                BrandBadge(text: "Centro legal", systemImage: "hand.raised.fill")

                                Text("Documentos legales")
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                    .foregroundStyle(BrandTheme.ink)

                                Text("Consulta privacidad, términos, soporte y el aviso beta desde una biblioteca clara, sin duplicar tarjetas ni esconder el texto importante detrás de enlaces.")
                                    .font(.subheadline)
                                    .foregroundStyle(BrandTheme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Biblioteca")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        ForEach(LegalDocumentLibrary.all) { document in
                            NavigationLink {
                                LegalDocumentDetailView(document: document)
                            } label: {
                                LegalDocumentRow(document: document)
                            }
                            .buttonStyle(.plain)

                            if document.id != LegalDocumentLibrary.all.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .navigationTitle("Centro legal")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LegalDocumentDetailView: View {
    @Environment(\.openURL) private var openURL
    @State private var copiedLink = false

    let document: LegalDocumentResource

    private var markdownBody: String {
        LegalDocumentLibrary.markdown(for: document)
    }

    private var renderedBody: AttributedString {
        if let attributed = try? AttributedString(
            markdown: markdownBody,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        ) {
            return attributed
        }

        return AttributedString(markdownBody)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        BrandBadge(text: document.title, systemImage: "doc.text.fill")

                        Text(document.title)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)

                        Text(document.summary)
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        FlowStack(spacing: 8, rowSpacing: 8) {
                            StoryTag(text: "Actualizado \(document.lastUpdated)", systemImage: "calendar")
                            StoryTag(text: "Documento local", systemImage: "lock.doc")
                            if document.publicURL != nil {
                                StoryTag(text: "Enlace público", systemImage: "globe")
                            }
                        }
                    }
                }

                if let publicURL = document.publicURL {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Publicación y referencia")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)

                            Text(publicURL.absoluteString)
                                .font(.footnote.monospaced())
                                .foregroundStyle(BrandTheme.muted)
                                .lineLimit(2)
                                .truncationMode(.middle)
                                .textSelection(.enabled)

                            HStack(spacing: 12) {
                                Button("Abrir enlace público") {
                                    openURL(publicURL)
                                }
                                .buttonStyle(PrimaryCTAStyle())

                                Button("Copiar enlace") {
                                    UIPasteboard.general.string = publicURL.absoluteString
                                    copiedLink = true
                                }
                                .buttonStyle(SecondaryCTAStyle())
                            }
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Texto completo")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text(renderedBody)
                            .foregroundStyle(BrandTheme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if copiedLink {
                Text("Enlace legal copiado")
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

private struct LegalDocumentRow: View {
    let document: LegalDocumentResource

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.headline.weight(.semibold))
                .foregroundStyle(BrandTheme.primary)
                .frame(width: 42, height: 42)
                .background(BrandTheme.accent.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                Text(document.summary)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Actualizado \(document.lastUpdated)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(BrandTheme.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(BrandTheme.muted)
                .padding(.top, 6)
        }
        .padding(.vertical, 2)
    }

    private var symbol: String {
        switch document.id {
        case .privacyPolicy:
            return "hand.raised.fill"
        case .termsOfUse:
            return "doc.text.fill"
        case .betaNotice:
            return "testtube.2"
        case .supportAndContact:
            return "lifepreserver.fill"
        }
    }
}
