import Foundation

enum InternalTesterPlanID: String, CaseIterable, Identifiable {
    case free
    case personal
    case family
    case enterprise

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .personal:
            return "Pro"
        case .family:
            return "Family"
        case .enterprise:
            return "Enterprise"
        }
    }
}

struct CloudExpenseMirror: Equatable {
    let cloudID: String
    let merchant: String
    let category: ExpenseCategory
    let amount: Decimal
    let date: Date
    let locationLabel: String?
    let note: String?
    let source: ExpenseEntrySource
}

struct CloudAccountMirror: Equatable {
    let cloudID: String
    let name: String
    let institution: String
    let balance: Decimal
    let kind: AccountKind
}

struct CloudBillMirror: Equatable {
    let cloudID: String
    let title: String
    let amount: Decimal
    let dueDay: Int
    let category: ExpenseCategory
    let cadence: RecurringCadence
    let renewalMonth: Int?
}

struct CloudRuleMirror: Equatable {
    let cloudID: String
    let merchantKeyword: String
    let category: ExpenseCategory
    let note: String?
    let isEnabled: Bool
}

struct CloudFinanceSnapshot: Equatable {
    let spaceID: String
    let role: String
    let pulledAt: Date
    let monthlyIncome: Decimal
    let monthlyBudget: Decimal
    let profile: ProfileRecord
    let expenses: [CloudExpenseMirror]
    let accounts: [CloudAccountMirror]
    let bills: [CloudBillMirror]
    let rules: [CloudRuleMirror]

    var isEmpty: Bool {
        expenses.isEmpty
            && accounts.isEmpty
            && bills.isEmpty
            && rules.isEmpty
            && monthlyIncome == 0
            && monthlyBudget == 0
            && profile == .default
    }
}

@MainActor
protocol CloudFinanceSyncing {
    var isConfigured: Bool { get }
    func fetchFinanceSnapshot(spaceID: String?) async throws -> CloudFinanceSnapshot
    func createExpense(_ draft: ExpenseDraft, spaceID: String?) async throws -> CloudExpenseMirror
    func updateExpense(cloudID: String, draft: ExpenseDraft, spaceID: String?) async throws -> CloudExpenseMirror
    func deleteExpense(cloudID: String, spaceID: String?) async throws
    func createAccount(_ draft: AccountDraft, spaceID: String?) async throws -> CloudAccountMirror
    func updateAccount(cloudID: String, draft: AccountDraft, spaceID: String?) async throws -> CloudAccountMirror
    func deleteAccount(cloudID: String, spaceID: String?) async throws
    func createBill(_ draft: BillDraft, spaceID: String?) async throws -> CloudBillMirror
    func updateBill(cloudID: String, draft: BillDraft, spaceID: String?) async throws -> CloudBillMirror
    func deleteBill(cloudID: String, spaceID: String?) async throws
    func createRule(_ draft: RuleDraft, spaceID: String?) async throws -> CloudRuleMirror
    func updateRule(cloudID: String, draft: RuleDraft, isEnabled: Bool, spaceID: String?) async throws -> CloudRuleMirror
    func deleteRule(cloudID: String, spaceID: String?) async throws
    func upsertNativeProfile(monthlyIncome: Decimal, monthlyBudget: Decimal, profile: ProfileRecord) async throws
    func claimTesterPlan(_ planID: InternalTesterPlanID) async throws -> BackendEntitlements
}

enum DefaultCloudFinanceClient {
    @MainActor
    static func make(
        authService: AuthServicing,
        configuration: BackendConfiguration?
    ) -> CloudFinanceSyncing {
        guard let configuration else {
            return PreviewCloudFinanceClient()
        }
        return LiveCloudFinanceClient(authService: authService, configuration: configuration)
    }
}

private struct FinanceBootstrapEnvelope: Decodable {
    let finance: FinanceBootstrapPayload
}

private struct FinanceBootstrapPayload: Decodable {
    struct NativeProfilePayload: Decodable {
        let monthlyIncomeCents: Int
        let monthlyBudgetCents: Int
        let profile: NativeProfileBody
        let updatedAt: String
    }

    struct NativeProfileBody: Decodable {
        let fullName: String
        let householdName: String
        let email: String
        let countryCode: String
        let marketingOptIn: Bool
    }

    struct BudgetPayload: Decodable {
        let categoryBudgetsCents: [String: Int]
    }

    struct ExpensePayload: Decodable {
        let id: String
        let merchant: String?
        let category: String
        let amountCents: Int
        let occurredAt: String
        let locationLabel: String?
        let notes: String?
        let source: String
    }

    struct AccountPayload: Decodable {
        let id: String
        let name: String
        let institution: String?
        let kind: String
        let type: String
        let currentBalanceCents: Int
    }

    struct BillPayload: Decodable {
        let id: String
        let label: String
        let expectedAmountCents: Int
        let nextDueAt: String
        let category: String
        let cadence: String
        let active: Bool
    }

    struct RulePayload: Decodable {
        let id: String
        let merchantContains: String
        let category: String
        let active: Bool
        let paymentMethod: String?
    }

    let spaceId: String
    let role: String
    let pulledAt: String
    let nativeProfile: NativeProfilePayload?
    let budget: BudgetPayload?
    let expenses: [ExpensePayload]
    let accounts: [AccountPayload]
    let bills: [BillPayload]
    let rules: [RulePayload]
}

private struct ExpenseEnvelope: Decodable {
    struct Payload: Decodable {
        let id: String
        let merchant: String?
        let category: String
        let amountCents: Int
        let occurredAt: String
        let locationLabel: String?
        let notes: String?
        let source: String
    }

    let expense: Payload
}

private struct AccountEnvelope: Decodable {
    struct Payload: Decodable {
        let id: String
        let name: String
        let institution: String?
        let kind: String
        let type: String
        let currentBalanceCents: Int
    }

    let account: Payload
}

private struct BillEnvelope: Decodable {
    struct Payload: Decodable {
        let id: String
        let label: String
        let expectedAmountCents: Int
        let nextDueAt: String
        let category: String
        let cadence: String
        let active: Bool
    }

    let bill: Payload
}

private struct RuleEnvelope: Decodable {
    struct Payload: Decodable {
        let id: String
        let merchantContains: String
        let category: String
        let active: Bool
        let paymentMethod: String?
    }

    let rule: Payload
}

private struct EntitlementsEnvelope: Decodable {
    let entitlements: BackendEntitlements
}

@MainActor
final class LiveCloudFinanceClient: CloudFinanceSyncing {
    let isConfigured = true

    private let authService: AuthServicing
    private let configuration: BackendConfiguration
    private let decoder: JSONDecoder

    init(authService: AuthServicing, configuration: BackendConfiguration) {
        self.authService = authService
        self.configuration = configuration

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func fetchFinanceSnapshot(spaceID: String?) async throws -> CloudFinanceSnapshot {
        let payload = try await requestJSON(
            path: "/me/finance-bootstrap",
            method: "GET",
            queryItems: spaceQueryItems(spaceID),
            as: FinanceBootstrapEnvelope.self
        ).finance
        let profile = payload.nativeProfile.map(Self.mapProfile) ?? .default
        let monthlyIncome = payload.nativeProfile.map { Self.decimal(fromCents: $0.monthlyIncomeCents) } ?? 0
        let monthlyBudget = payload.nativeProfile.map { Self.decimal(fromCents: $0.monthlyBudgetCents) }
            ?? Self.decimal(fromCents: (payload.budget?.categoryBudgetsCents.values.reduce(0, +)) ?? 0)

        return CloudFinanceSnapshot(
            spaceID: payload.spaceId,
            role: payload.role,
            pulledAt: Self.parseDate(payload.pulledAt),
            monthlyIncome: monthlyIncome,
            monthlyBudget: monthlyBudget,
            profile: profile,
            expenses: payload.expenses.map(Self.mapExpense),
            accounts: payload.accounts.map(Self.mapAccount),
            bills: payload.bills.filter(\.active).map(Self.mapBill),
            rules: payload.rules.map(Self.mapRule)
        )
    }

    func createExpense(_ draft: ExpenseDraft, spaceID: String?) async throws -> CloudExpenseMirror {
        let requestBody = ExpenseRequestBody(
            type: "expense",
            amountCents: Self.cents(from: draft.amount),
            currency: Self.currencyCode(),
            merchant: draft.merchant,
            category: Self.backendCategory(for: draft.category),
            occurredAt: Self.isoDate(draft.date),
            paymentMethod: nil,
            locationLabel: draft.locationLabel.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            notes: draft.note.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            source: Self.backendSource(for: draft.source)
        )
        let body = try CloudFinanceJSON.encoder.encode(requestBody)
        let response = try await requestJSON(
            path: "/expenses",
            method: "POST",
            body: body,
            queryItems: spaceQueryItems(spaceID),
            as: ExpenseEnvelope.self
        )
        return Self.mapExpense(response.expense)
    }

    func updateExpense(cloudID: String, draft: ExpenseDraft, spaceID: String?) async throws -> CloudExpenseMirror {
        let requestBody = ExpensePatchRequestBody(
            merchant: draft.merchant,
            category: Self.backendCategory(for: draft.category),
            amountCents: Self.cents(from: draft.amount),
            occurredAt: Self.isoDate(draft.date),
            locationLabel: draft.locationLabel.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            notes: draft.note.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            source: Self.backendSource(for: draft.source)
        )
        let body = try CloudFinanceJSON.encoder.encode(requestBody)
        let response = try await requestJSON(
            path: "/expenses/\(cloudID)",
            method: "PUT",
            body: body,
            queryItems: spaceQueryItems(spaceID),
            as: ExpenseEnvelope.self
        )
        return Self.mapExpense(response.expense)
    }

    func deleteExpense(cloudID: String, spaceID: String?) async throws {
        _ = try await request(path: "/expenses/\(cloudID)", method: "DELETE", queryItems: spaceQueryItems(spaceID))
    }

    func createAccount(_ draft: AccountDraft, spaceID: String?) async throws -> CloudAccountMirror {
        let requestBody = AccountRequestBody(
            name: draft.name,
            institution: draft.institution.nilIfEmpty,
            kind: Self.backendAccountKind(for: draft.kind),
            type: Self.backendAccountType(for: draft.kind),
            currentBalanceCents: Self.cents(from: draft.balance),
            currency: Self.currencyCode(),
            includeInNetWorth: true,
            active: true,
            notes: nil
        )
        let body = try CloudFinanceJSON.encoder.encode(requestBody)
        let response = try await requestJSON(
            path: "/accounts",
            method: "POST",
            body: body,
            queryItems: spaceQueryItems(spaceID),
            as: AccountEnvelope.self
        )
        return Self.mapAccount(response.account)
    }

    func updateAccount(cloudID: String, draft: AccountDraft, spaceID: String?) async throws -> CloudAccountMirror {
        let requestBody = AccountPatchRequestBody(
            name: draft.name,
            institution: draft.institution.nilIfEmpty,
            kind: Self.backendAccountKind(for: draft.kind),
            type: Self.backendAccountType(for: draft.kind),
            currentBalanceCents: Self.cents(from: draft.balance),
            currency: Self.currencyCode(),
            includeInNetWorth: true,
            active: true
        )
        let body = try CloudFinanceJSON.encoder.encode(requestBody)
        let response = try await requestJSON(
            path: "/accounts/\(cloudID)",
            method: "PUT",
            body: body,
            queryItems: spaceQueryItems(spaceID),
            as: AccountEnvelope.self
        )
        return Self.mapAccount(response.account)
    }

    func deleteAccount(cloudID: String, spaceID: String?) async throws {
        _ = try await request(path: "/accounts/\(cloudID)", method: "DELETE", queryItems: spaceQueryItems(spaceID))
    }

    func createBill(_ draft: BillDraft, spaceID: String?) async throws -> CloudBillMirror {
        let dueDate = Self.nextDueDate(for: draft)
        let requestBody = BillRequestBody(
            label: draft.title,
            merchant: draft.title.nilIfEmpty,
            category: Self.backendCategory(for: draft.category),
            expectedAmountCents: Self.cents(from: draft.amount),
            currency: Self.currencyCode(),
            cadence: draft.cadence == .yearly ? "monthly" : "monthly",
            intervalCount: draft.cadence == .yearly ? 12 : 1,
            nextDueAt: Self.isoDate(dueDate),
            reminderDaysBefore: [3],
            active: true,
            notes: draft.autopay ? "Autopay enabled locally on this device." : nil
        )
        let body = try CloudFinanceJSON.encoder.encode(requestBody)
        let response = try await requestJSON(
            path: "/recurring-bills",
            method: "POST",
            body: body,
            queryItems: spaceQueryItems(spaceID),
            as: BillEnvelope.self
        )
        return Self.mapBill(response.bill)
    }

    func updateBill(cloudID: String, draft: BillDraft, spaceID: String?) async throws -> CloudBillMirror {
        let dueDate = Self.nextDueDate(for: draft)
        let requestBody = BillPatchRequestBody(
            label: draft.title,
            merchant: draft.title.nilIfEmpty,
            category: Self.backendCategory(for: draft.category),
            expectedAmountCents: Self.cents(from: draft.amount),
            currency: Self.currencyCode(),
            cadence: draft.cadence == .yearly ? "monthly" : "monthly",
            intervalCount: draft.cadence == .yearly ? 12 : 1,
            nextDueAt: Self.isoDate(dueDate),
            reminderDaysBefore: [3],
            active: true,
            notes: draft.autopay ? "Autopay enabled locally on this device." : nil
        )
        let body = try CloudFinanceJSON.encoder.encode(requestBody)
        let response = try await requestJSON(
            path: "/recurring-bills/\(cloudID)",
            method: "PUT",
            body: body,
            queryItems: spaceQueryItems(spaceID),
            as: BillEnvelope.self
        )
        return Self.mapBill(response.bill)
    }

    func deleteBill(cloudID: String, spaceID: String?) async throws {
        _ = try await request(path: "/recurring-bills/\(cloudID)", method: "DELETE", queryItems: spaceQueryItems(spaceID))
    }

    func createRule(_ draft: RuleDraft, spaceID: String?) async throws -> CloudRuleMirror {
        let requestBody = RuleRequestBody(
            name: draft.merchantKeyword.nilIfEmpty ?? "Rule",
            merchantContains: draft.merchantKeyword,
            category: Self.backendCategory(for: draft.category),
            paymentMethod: draft.note.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            active: true
        )
        let body = try CloudFinanceJSON.encoder.encode(requestBody)
        let response = try await requestJSON(
            path: "/transaction-rules",
            method: "POST",
            body: body,
            queryItems: spaceQueryItems(spaceID),
            as: RuleEnvelope.self
        )
        return Self.mapRule(response.rule)
    }

    func updateRule(cloudID: String, draft: RuleDraft, isEnabled: Bool, spaceID: String?) async throws -> CloudRuleMirror {
        let body = try CloudFinanceJSON.encoder.encode(
            RulePatchRequestBody(
                name: draft.merchantKeyword.nilIfEmpty ?? "Rule",
                merchantContains: draft.merchantKeyword,
                category: Self.backendCategory(for: draft.category),
                paymentMethod: draft.note.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                active: isEnabled
            )
        )
        let response = try await requestJSON(
            path: "/transaction-rules/\(cloudID)",
            method: "PUT",
            body: body,
            queryItems: spaceQueryItems(spaceID),
            as: RuleEnvelope.self
        )
        return Self.mapRule(response.rule)
    }

    func deleteRule(cloudID: String, spaceID: String?) async throws {
        _ = try await request(path: "/transaction-rules/\(cloudID)", method: "DELETE", queryItems: spaceQueryItems(spaceID))
    }

    func upsertNativeProfile(monthlyIncome: Decimal, monthlyBudget: Decimal, profile: ProfileRecord) async throws {
        let body = try CloudFinanceJSON.encoder.encode(
            NativeProfileRequestBody(
                monthlyIncomeCents: Self.cents(from: monthlyIncome),
                monthlyBudgetCents: Self.cents(from: monthlyBudget),
                profile: .init(
                    fullName: profile.fullName,
                    householdName: profile.householdName,
                    email: profile.email,
                    countryCode: profile.countryCode,
                    marketingOptIn: profile.marketingOptIn
                )
            )
        )
        _ = try await request(path: "/me/native-profile", method: "PUT", body: body)
    }

    func claimTesterPlan(_ planID: InternalTesterPlanID) async throws -> BackendEntitlements {
        let body = try CloudFinanceJSON.encoder.encode(["planId": planID.rawValue])
        let response = try await requestJSON(path: "/billing/dev-tester-plan", method: "POST", body: body, as: EntitlementsEnvelope.self)
        return response.entitlements
    }

    private func requestJSON<Response: Decodable>(
        path: String,
        method: String,
        body: Data? = nil,
        queryItems: [URLQueryItem] = [],
        as responseType: Response.Type
    ) async throws -> Response {
        let data = try await request(path: path, method: method, body: body, queryItems: queryItems)
        return try decoder.decode(responseType, from: data)
    }

    private func request(
        path: String,
        method: String,
        body: Data? = nil,
        queryItems: [URLQueryItem] = []
    ) async throws -> Data {
        guard let idToken = await authService.currentIDToken(), !idToken.isEmpty else {
            throw BackendServiceError.configurationMissing
        }

        let normalizedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard var components = URLComponents(url: configuration.apiBaseURL.appendingPathComponent(normalizedPath), resolvingAgainstBaseURL: false) else {
            throw BackendServiceError.configurationMissing
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw BackendServiceError.configurationMissing
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendServiceError.invalidPayload
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw BackendServiceError.invalidResponse(statusCode: httpResponse.statusCode, body: bodyText)
        }
        return data
    }

    private func spaceQueryItems(_ spaceID: String?) -> [URLQueryItem] {
        guard let trimmed = spaceID?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return []
        }
        return [URLQueryItem(name: "spaceId", value: trimmed)]
    }

    private static func mapProfile(_ payload: FinanceBootstrapPayload.NativeProfilePayload) -> ProfileRecord {
        ProfileRecord(
            fullName: payload.profile.fullName,
            householdName: payload.profile.householdName,
            email: payload.profile.email,
            countryCode: payload.profile.countryCode,
            marketingOptIn: payload.profile.marketingOptIn
        )
    }

    private static func mapExpense(_ payload: FinanceBootstrapPayload.ExpensePayload) -> CloudExpenseMirror {
        CloudExpenseMirror(
            cloudID: payload.id,
            merchant: payload.merchant?.nilIfEmpty ?? "Cloud expense",
            category: localCategory(for: payload.category),
            amount: decimal(fromCents: payload.amountCents),
            date: parseDate(payload.occurredAt),
            locationLabel: payload.locationLabel?.nilIfEmpty,
            note: payload.notes?.nilIfEmpty,
            source: localSource(for: payload.source)
        )
    }

    private static func mapExpense(_ payload: ExpenseEnvelope.Payload) -> CloudExpenseMirror {
        CloudExpenseMirror(
            cloudID: payload.id,
            merchant: payload.merchant?.nilIfEmpty ?? "Cloud expense",
            category: localCategory(for: payload.category),
            amount: decimal(fromCents: payload.amountCents),
            date: parseDate(payload.occurredAt),
            locationLabel: payload.locationLabel?.nilIfEmpty,
            note: payload.notes?.nilIfEmpty,
            source: localSource(for: payload.source)
        )
    }

    private static func mapAccount(_ payload: FinanceBootstrapPayload.AccountPayload) -> CloudAccountMirror {
        CloudAccountMirror(
            cloudID: payload.id,
            name: payload.name,
            institution: payload.institution ?? "",
            balance: decimal(fromCents: payload.currentBalanceCents),
            kind: localAccountKind(kind: payload.kind, type: payload.type)
        )
    }

    private static func mapAccount(_ payload: AccountEnvelope.Payload) -> CloudAccountMirror {
        CloudAccountMirror(
            cloudID: payload.id,
            name: payload.name,
            institution: payload.institution ?? "",
            balance: decimal(fromCents: payload.currentBalanceCents),
            kind: localAccountKind(kind: payload.kind, type: payload.type)
        )
    }

    private static func mapBill(_ payload: FinanceBootstrapPayload.BillPayload) -> CloudBillMirror {
        let dueDate = parseDate(payload.nextDueAt)
        let calendar = Calendar.autoupdatingCurrent
        return CloudBillMirror(
            cloudID: payload.id,
            title: payload.label,
            amount: decimal(fromCents: payload.expectedAmountCents),
            dueDay: min(max(calendar.component(.day, from: dueDate), 1), 28),
            category: localCategory(for: payload.category),
            cadence: payload.cadence == "monthly" ? .monthly : .yearly,
            renewalMonth: payload.cadence == "monthly" ? nil : calendar.component(.month, from: dueDate)
        )
    }

    private static func mapBill(_ payload: BillEnvelope.Payload) -> CloudBillMirror {
        let dueDate = parseDate(payload.nextDueAt)
        let calendar = Calendar.autoupdatingCurrent
        return CloudBillMirror(
            cloudID: payload.id,
            title: payload.label,
            amount: decimal(fromCents: payload.expectedAmountCents),
            dueDay: min(max(calendar.component(.day, from: dueDate), 1), 28),
            category: localCategory(for: payload.category),
            cadence: payload.cadence == "monthly" ? .monthly : .yearly,
            renewalMonth: payload.cadence == "monthly" ? nil : calendar.component(.month, from: dueDate)
        )
    }

    private static func mapRule(_ payload: FinanceBootstrapPayload.RulePayload) -> CloudRuleMirror {
        CloudRuleMirror(
            cloudID: payload.id,
            merchantKeyword: payload.merchantContains,
            category: localCategory(for: payload.category),
            note: payload.paymentMethod,
            isEnabled: payload.active
        )
    }

    private static func mapRule(_ payload: RuleEnvelope.Payload) -> CloudRuleMirror {
        CloudRuleMirror(
            cloudID: payload.id,
            merchantKeyword: payload.merchantContains,
            category: localCategory(for: payload.category),
            note: payload.paymentMethod,
            isEnabled: payload.active
        )
    }

    private static func localCategory(for backendCategory: String) -> ExpenseCategory {
        switch backendCategory {
        case "Housing":
            return .home
        case "Transportation", "Travel":
            return .transport
        case "Food":
            return .groceries
        case "Utilities", "Insurance", "Debt":
            return .bills
        case "Healthcare":
            return .health
        case "Shopping":
            return .shopping
        case "Education":
            return .education
        case "Entertainment":
            return .subscriptions
        default:
            return .other
        }
    }

    private static func backendCategory(for localCategory: ExpenseCategory) -> String {
        switch localCategory {
        case .groceries, .dining, .coffee:
            return "Food"
        case .transport:
            return "Transportation"
        case .bills:
            return "Utilities"
        case .shopping:
            return "Shopping"
        case .health:
            return "Healthcare"
        case .home:
            return "Housing"
        case .subscriptions:
            return "Entertainment"
        case .education:
            return "Education"
        case .other:
            return "Other"
        }
    }

    private static func backendSource(for localSource: ExpenseEntrySource) -> String {
        switch localSource {
        case .manual, .email, .subscriptionAutomation:
            return "manual"
        case .receiptScan:
            return "invoice-scan"
        }
    }

    private static func localSource(for backendSource: String) -> ExpenseEntrySource {
        switch backendSource {
        case "invoice-scan":
            return .receiptScan
        default:
            return .manual
        }
    }

    private static func backendAccountKind(for localKind: AccountKind) -> String {
        localKind == .creditCard ? "liability" : "asset"
    }

    private static func backendAccountType(for localKind: AccountKind) -> String {
        switch localKind {
        case .checking:
            return "bank"
        case .savings:
            return "savings"
        case .cash:
            return "cash"
        case .creditCard:
            return "credit_card"
        case .investment:
            return "investment"
        }
    }

    private static func localAccountKind(kind: String, type: String) -> AccountKind {
        if type == "credit_card" || kind == "liability" {
            return .creditCard
        }
        switch type {
        case "savings":
            return .savings
        case "cash":
            return .cash
        case "investment":
            return .investment
        default:
            return .checking
        }
    }

    private static func currencyCode() -> String {
        UserDefaults.standard.string(forKey: AppCurrencyFormat.defaultsKey) ?? "USD"
    }

    private static func cents(from decimal: Decimal) -> Int {
        NSDecimalNumber(decimal: decimal * 100).intValue
    }

    private static func decimal(fromCents cents: Int) -> Decimal {
        Decimal(cents) / 100
    }

    private static func parseDate(_ raw: String) -> Date {
        CloudFinanceJSON.makeFractionalISO8601Formatter().date(from: raw)
            ?? CloudFinanceJSON.makeInternetISO8601Formatter().date(from: raw)
            ?? .now
    }

    private static func isoDate(_ date: Date) -> String {
        CloudFinanceJSON.makeInternetISO8601Formatter().string(from: date)
    }

    private static func nextDueDate(for draft: BillDraft) -> Date {
        let calendar = Calendar.autoupdatingCurrent
        let referenceDate = Date()
        let safeDay = min(max(draft.dueDay, 1), 28)
        if draft.cadence == .yearly {
            let currentYear = calendar.component(.year, from: referenceDate)
            let month = min(max(draft.renewalMonth ?? calendar.component(.month, from: referenceDate), 1), 12)
            let thisYear = calendar.date(from: DateComponents(year: currentYear, month: month, day: safeDay)) ?? referenceDate
            if thisYear >= calendar.startOfDay(for: referenceDate) {
                return thisYear
            }
            return calendar.date(byAdding: .year, value: 1, to: thisYear) ?? thisYear
        }

        let components = calendar.dateComponents([.year, .month], from: referenceDate)
        let thisMonth = calendar.date(from: DateComponents(year: components.year, month: components.month, day: safeDay)) ?? referenceDate
        if thisMonth >= calendar.startOfDay(for: referenceDate) {
            return thisMonth
        }
        return calendar.date(byAdding: .month, value: 1, to: thisMonth) ?? thisMonth
    }
}

@MainActor
struct PreviewCloudFinanceClient: CloudFinanceSyncing {
    let isConfigured = false

    func fetchFinanceSnapshot(spaceID: String?) async throws -> CloudFinanceSnapshot {
        CloudFinanceSnapshot(
            spaceID: "preview",
            role: "owner",
            pulledAt: .now,
            monthlyIncome: 0,
            monthlyBudget: 0,
            profile: .default,
            expenses: [],
            accounts: [],
            bills: [],
            rules: []
        )
    }

    func createExpense(_ draft: ExpenseDraft, spaceID: String?) async throws -> CloudExpenseMirror {
        throw BackendServiceError.configurationMissing
    }

    func updateExpense(cloudID: String, draft: ExpenseDraft, spaceID: String?) async throws -> CloudExpenseMirror {
        throw BackendServiceError.configurationMissing
    }

    func deleteExpense(cloudID: String, spaceID: String?) async throws {}

    func createAccount(_ draft: AccountDraft, spaceID: String?) async throws -> CloudAccountMirror {
        throw BackendServiceError.configurationMissing
    }

    func updateAccount(cloudID: String, draft: AccountDraft, spaceID: String?) async throws -> CloudAccountMirror {
        throw BackendServiceError.configurationMissing
    }

    func deleteAccount(cloudID: String, spaceID: String?) async throws {}

    func createBill(_ draft: BillDraft, spaceID: String?) async throws -> CloudBillMirror {
        throw BackendServiceError.configurationMissing
    }

    func updateBill(cloudID: String, draft: BillDraft, spaceID: String?) async throws -> CloudBillMirror {
        throw BackendServiceError.configurationMissing
    }

    func deleteBill(cloudID: String, spaceID: String?) async throws {}

    func createRule(_ draft: RuleDraft, spaceID: String?) async throws -> CloudRuleMirror {
        throw BackendServiceError.configurationMissing
    }

    func updateRule(cloudID: String, draft: RuleDraft, isEnabled: Bool, spaceID: String?) async throws -> CloudRuleMirror {
        throw BackendServiceError.configurationMissing
    }

    func deleteRule(cloudID: String, spaceID: String?) async throws {}

    func upsertNativeProfile(monthlyIncome: Decimal, monthlyBudget: Decimal, profile: ProfileRecord) async throws {}

    func claimTesterPlan(_ planID: InternalTesterPlanID) async throws -> BackendEntitlements {
        throw BackendServiceError.configurationMissing
    }
}

private struct ExpenseRequestBody: Encodable {
    let type: String
    let amountCents: Int
    let currency: String
    let merchant: String
    let category: String
    let occurredAt: String
    let paymentMethod: String?
    let locationLabel: String?
    let notes: String?
    let source: String
}

private struct ExpensePatchRequestBody: Encodable {
    let merchant: String
    let category: String
    let amountCents: Int
    let occurredAt: String
    let locationLabel: String?
    let notes: String?
    let source: String
}

private struct AccountRequestBody: Encodable {
    let name: String
    let institution: String?
    let kind: String
    let type: String
    let currentBalanceCents: Int
    let currency: String
    let includeInNetWorth: Bool
    let active: Bool
    let notes: String?
}

private struct AccountPatchRequestBody: Encodable {
    let name: String
    let institution: String?
    let kind: String
    let type: String
    let currentBalanceCents: Int
    let currency: String
    let includeInNetWorth: Bool
    let active: Bool
}

private struct BillRequestBody: Encodable {
    let label: String
    let merchant: String?
    let category: String
    let expectedAmountCents: Int
    let currency: String
    let cadence: String
    let intervalCount: Int
    let nextDueAt: String
    let reminderDaysBefore: [Int]
    let active: Bool
    let notes: String?
}

private struct BillPatchRequestBody: Encodable {
    let label: String
    let merchant: String?
    let category: String
    let expectedAmountCents: Int
    let currency: String
    let cadence: String
    let intervalCount: Int
    let nextDueAt: String
    let reminderDaysBefore: [Int]
    let active: Bool
    let notes: String?
}

private struct RuleRequestBody: Encodable {
    let name: String
    let merchantContains: String
    let category: String
    let paymentMethod: String?
    let active: Bool
}

private struct RulePatchRequestBody: Encodable {
    let name: String
    let merchantContains: String
    let category: String
    let paymentMethod: String?
    let active: Bool
}

private struct NativeProfileRequestBody: Encodable {
    struct ProfileBody: Encodable {
        let fullName: String
        let householdName: String
        let email: String
        let countryCode: String
        let marketingOptIn: Bool
    }

    let monthlyIncomeCents: Int
    let monthlyBudgetCents: Int
    let profile: ProfileBody
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private enum CloudFinanceJSON {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    static func makeFractionalISO8601Formatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    static func makeInternetISO8601Formatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }
}
