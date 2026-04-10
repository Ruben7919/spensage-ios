import Foundation
import StoreKit

enum LaunchMonetizationCatalog {
    struct PlanCard: Equatable {
        let planKey: StorePlanKey
        let priceLabel: String
        let summary: String
        let features: [String]
        let isHighlighted: Bool
    }

    static let freeMonthlyExpenseLimit = 60
    static let freeReceiptScanLimit = 5
    static let localPlusMonthlyExpenseLimit = 150
    static let localPlusReceiptScanLimit = 25
    static let familyMaxMembers = 5

    static let planCards: [PlanCard] = [
        PlanCard(
            planKey: .freeLocal,
            priceLabel: "$0",
            summary: "Para probar MichiFinanzas sin pagar.",
            features: [
                "Hasta \(freeMonthlyExpenseLimit) gastos manuales al mes",
                "\(freeReceiptScanLimit) escaneos de prueba al mes",
                "Sin sync ni herramientas avanzadas"
            ],
            isHighlighted: false
        ),
        PlanCard(
            planKey: .removeAds,
            priceLabel: "$14.99 pago único",
            summary: "Una compra única para ampliar el uso local sin suscripción.",
            features: [
                "Quita superficies patrocinadas",
                "Hasta \(localPlusMonthlyExpenseLimit) gastos y \(localPlusReceiptScanLimit) escaneos al mes",
                "Facturas y recordatorios locales",
                "No desbloquea sync, CSV, reglas ni Family"
            ],
            isHighlighted: false
        ),
        PlanCard(
            planKey: .pro,
            priceLabel: "$5.99/mes o $39.99/año",
            summary: "Para usar MichiFinanzas como herramienta financiera diaria.",
            features: [
                "Respaldo y sync entre dispositivos",
                "Escaneo de recibos, CSV, cuentas, facturas, reglas e insights"
            ],
            isHighlighted: true
        ),
        PlanCard(
            planKey: .family,
            priceLabel: "$9.99/mes o $69.99/año",
            summary: "Para manejar el presupuesto del hogar sin duplicar cuentas.",
            features: [
                "Todo lo incluido en Pro",
                "Hasta \(familyMaxMembers) miembros con espacios compartidos e invitaciones"
            ],
            isHighlighted: false
        )
    ]

    static func displayName(for planKey: StorePlanKey) -> String {
        switch planKey {
        case .freeLocal:
            return "Gratis"
        case .removeAds:
            return "Plus local"
        case .pro:
            return "Pro"
        case .family:
            return "Familia"
        }
    }
}

enum StorePlanKey: String, Equatable {
    case freeLocal
    case removeAds
    case pro
    case family

    var displayName: String {
        LaunchMonetizationCatalog.displayName(for: self)
    }
}

enum StorePurchaseKind: String, Equatable {
    case monthly
    case annual
    case lifetime

    var ctaLabel: String {
        switch self {
        case .monthly:
            return "Comprar mensual"
        case .annual:
            return "Comprar anual"
        case .lifetime:
            return "Comprar"
        }
    }

    var summaryLabel: String {
        switch self {
        case .monthly:
            return "Mensual"
        case .annual:
            return "Anual"
        case .lifetime:
            return "Pago unico"
        }
    }
}

struct StoreCatalogProduct: Identifiable, Equatable {
    let id: String
    let planKey: StorePlanKey
    let kind: StorePurchaseKind
    let displayName: String
    let displayPrice: String
    let shortDescription: String
    let sortOrder: Int

    var ctaLabel: String {
        "\(kind.ctaLabel) · \(displayPrice)"
    }
}

struct StoreEntitlementSnapshot: Equatable {
    let activeProductIDs: [String]
    let activePlanKey: StorePlanKey?
    let hasRemoveAds: Bool

    static let empty = StoreEntitlementSnapshot(
        activeProductIDs: [],
        activePlanKey: nil,
        hasRemoveAds: false
    )

    var displayPlanName: String {
        activePlanKey?.displayName ?? StorePlanKey.freeLocal.displayName
    }
}

struct StoreBillingState: Equatable {
    var products: [StoreCatalogProduct] = []
    var entitlements: StoreEntitlementSnapshot = .empty
    var isLoading = false
    var isRestoring = false
    var activePurchaseProductID: String?
    var lastError: String?
    var lastUpdatedAt: Date?
}

enum StoreBillingError: LocalizedError, Equatable {
    case productUnavailable
    case purchaseCancelled
    case purchasePending
    case unverifiedTransaction
    case unsupportedResult

    var errorDescription: String? {
        switch self {
        case .productUnavailable:
            return "App Store no devolvio ese producto para esta app."
        case .purchaseCancelled:
            return "La compra se cancelo antes de completarse."
        case .purchasePending:
            return "La compra quedo pendiente de aprobacion en App Store."
        case .unverifiedTransaction:
            return "App Store devolvio una transaccion que no se pudo verificar."
        case .unsupportedResult:
            return "App Store devolvio un estado de compra no soportado por esta version."
        }
    }
}

@MainActor
protocol StoreBillingServicing {
    func loadCatalog() async throws -> [StoreCatalogProduct]
    func refreshEntitlements() async throws -> StoreEntitlementSnapshot
    func purchase(productID: String) async throws -> StoreEntitlementSnapshot
    func restorePurchases() async throws -> StoreEntitlementSnapshot
    func managementURL() -> URL?
}

enum DefaultStoreBillingService {
    @MainActor
    static func make() -> StoreBillingServicing {
        LiveStoreBillingService()
    }
}

enum StoreProductID: String, CaseIterable {
    case proMonthly = "spendsage.pro.monthly"
    case proAnnual = "spendsage.pro.annual"
    case familyMonthly = "spendsage.family.monthly"
    case familyAnnual = "spendsage.family.annual"
    case removeAds = "spendsage.remove_ads"

    var planKey: StorePlanKey {
        switch self {
        case .proMonthly, .proAnnual:
            return .pro
        case .familyMonthly, .familyAnnual:
            return .family
        case .removeAds:
            return .removeAds
        }
    }

    var purchaseKind: StorePurchaseKind {
        switch self {
        case .proMonthly, .familyMonthly:
            return .monthly
        case .proAnnual, .familyAnnual:
            return .annual
        case .removeAds:
            return .lifetime
        }
    }

    var sortOrder: Int {
        switch self {
        case .proMonthly:
            return 10
        case .proAnnual:
            return 11
        case .familyMonthly:
            return 20
        case .familyAnnual:
            return 21
        case .removeAds:
            return 30
        }
    }
}

@MainActor
final class LiveStoreBillingService: StoreBillingServicing {
    func loadCatalog() async throws -> [StoreCatalogProduct] {
        let products = try await Product.products(for: StoreProductID.allCases.map(\.rawValue))
        let indexedProducts = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })

        return StoreProductID.allCases.compactMap { productID in
            guard let product = indexedProducts[productID.rawValue] else { return nil }
            return Self.catalogProduct(from: product, productID: productID)
        }
    }

    func refreshEntitlements() async throws -> StoreEntitlementSnapshot {
        var productIDs = Set<String>()

        for await result in Transaction.currentEntitlements {
            switch result {
            case let .verified(transaction):
                productIDs.insert(transaction.productID)
            case .unverified:
                continue
            }
        }

        return Self.entitlementSnapshot(from: productIDs)
    }

    func purchase(productID: String) async throws -> StoreEntitlementSnapshot {
        guard let product = try await Product.products(for: [productID]).first else {
            throw StoreBillingError.productUnavailable
        }

        let purchaseResult = try await product.purchase()
        switch purchaseResult {
        case let .success(verification):
            let transaction = try verifiedTransaction(from: verification)
            await transaction.finish()
            return try await refreshEntitlements()
        case .pending:
            throw StoreBillingError.purchasePending
        case .userCancelled:
            throw StoreBillingError.purchaseCancelled
        @unknown default:
            throw StoreBillingError.unsupportedResult
        }
    }

    func restorePurchases() async throws -> StoreEntitlementSnapshot {
        try await AppStore.sync()
        return try await refreshEntitlements()
    }

    func managementURL() -> URL? {
        URL(string: "https://apps.apple.com/account/subscriptions")
    }

    private func verifiedTransaction(
        from verification: VerificationResult<Transaction>
    ) throws -> Transaction {
        switch verification {
        case let .verified(transaction):
            return transaction
        case .unverified:
            throw StoreBillingError.unverifiedTransaction
        }
    }

    private static func catalogProduct(
        from product: Product,
        productID: StoreProductID
    ) -> StoreCatalogProduct {
        StoreCatalogProduct(
            id: product.id,
            planKey: productID.planKey,
            kind: productID.purchaseKind,
            displayName: product.displayName,
            displayPrice: product.displayPrice,
            shortDescription: product.description,
            sortOrder: productID.sortOrder
        )
    }

    private static func entitlementSnapshot(from productIDs: Set<String>) -> StoreEntitlementSnapshot {
        let orderedIDs = StoreProductID.allCases
            .map(\.rawValue)
            .filter(productIDs.contains)

        let activePlanKey: StorePlanKey?
        if orderedIDs.contains(StoreProductID.familyMonthly.rawValue) || orderedIDs.contains(StoreProductID.familyAnnual.rawValue) {
            activePlanKey = .family
        } else if orderedIDs.contains(StoreProductID.proMonthly.rawValue) || orderedIDs.contains(StoreProductID.proAnnual.rawValue) {
            activePlanKey = .pro
        } else if orderedIDs.contains(StoreProductID.removeAds.rawValue) {
            activePlanKey = .removeAds
        } else {
            activePlanKey = nil
        }

        return StoreEntitlementSnapshot(
            activeProductIDs: orderedIDs,
            activePlanKey: activePlanKey,
            hasRemoveAds: orderedIDs.contains(StoreProductID.removeAds.rawValue)
        )
    }
}
