import Foundation

enum LegalDocumentID: String, CaseIterable, Identifiable {
    case privacyPolicy = "PRIVACY_POLICY"
    case termsOfUse = "TERMS_OF_USE"
    case betaNotice = "BETA_NOTICE_AND_DISCLOSURES"
    case supportAndContact = "SUPPORT_AND_CONTACT"

    var id: String { rawValue }
}

struct LegalDocumentResource: Identifiable, Equatable {
    let id: LegalDocumentID
    let topic: LegalTopic
    let title: String
    let summary: String
    let fileName: String
    let lastUpdated: String
    let publicURL: URL?
}

enum LegalDocumentLibrary {
    static let all: [LegalDocumentResource] = [
        LegalDocumentResource(
            id: .privacyPolicy,
            topic: .privacy,
            title: "Política de privacidad",
            summary: "Describe datos tratados, almacenamiento local, permisos, exportaciones y uso de soporte.",
            fileName: "PRIVACY_POLICY",
            lastUpdated: "2026-04-05",
            publicURL: PublicLegalLinks.privacy
        ),
        LegalDocumentResource(
            id: .termsOfUse,
            topic: .terms,
            title: "Términos de uso",
            summary: "Regulan el uso de la app, las limitaciones del servicio, OCR, beta y planes.",
            fileName: "TERMS_OF_USE",
            lastUpdated: "2026-04-05",
            publicURL: PublicLegalLinks.terms
        ),
        LegalDocumentResource(
            id: .betaNotice,
            topic: .support,
            title: "Aviso beta y divulgaciones",
            summary: "Explica el alcance de TestFlight, funciones preparatorias y límites de esta build.",
            fileName: "BETA_NOTICE_AND_DISCLOSURES",
            lastUpdated: "2026-04-05",
            publicURL: nil
        ),
        LegalDocumentResource(
            id: .supportAndContact,
            topic: .support,
            title: "Soporte y contacto",
            summary: "Define cómo se genera el paquete local, qué enviar y cómo contactar soporte.",
            fileName: "SUPPORT_AND_CONTACT",
            lastUpdated: "2026-04-05",
            publicURL: PublicLegalLinks.support
        )
    ]

    static func document(for topic: LegalTopic) -> LegalDocumentResource? {
        switch topic {
        case .privacy:
            all.first(where: { $0.id == .privacyPolicy })
        case .support:
            all.first(where: { $0.id == .supportAndContact })
        case .terms:
            all.first(where: { $0.id == .termsOfUse })
        }
    }

    static func markdown(for document: LegalDocumentResource, bundle: Bundle = .main) -> String {
        guard let url = bundle.url(forResource: document.fileName, withExtension: "md", subdirectory: "Legal"),
              let markdown = try? String(contentsOf: url, encoding: .utf8) else {
            return "Documento no disponible en esta build."
        }
        return markdown
    }
}
