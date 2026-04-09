import Foundation

struct BackendCapabilities: Codable, Equatable {
    struct FeatureFlags: Codable, Equatable {
        let expenses: Bool
        let budgets: Bool
        let spaces: Bool
        let invoiceScan: Bool
        let csvImport: Bool
        let aiInsights: Bool
        let promoCodes: Bool
        let webhooks: Bool
        let pushRegistration: Bool
        let billing: Bool
        let gamification: Bool?
        let coach: Bool?
        let importsEnabled: Bool?
    }

    struct SecurityFlags: Codable, Equatable {
        let waf: Bool
        let kmsAtRest: Bool
        let cognitoAuth: Bool
        let webhookSignatureValidation: Bool
        let rateLimits: Bool
    }

    let mode: String
    let mocked: Bool
    let features: FeatureFlags
    let security: SecurityFlags
}

struct BackendEntitlements: Codable, Equatable {
    let userId: String
    let planId: String
    let features: [String]
    let updatedAt: String

    var planDisplayName: String {
        switch planId.lowercased() {
        case "free":
            return "Gratis"
        case "personal", "pro":
            return "Pro"
        case "family":
            return "Family"
        case "enterprise":
            return "Enterprise"
        default:
            return planId
        }
    }

    var featuresDisplayLine: String {
        if features.isEmpty {
            return "Sin extras cloud"
        }
        return features
            .sorted()
            .joined(separator: ", ")
    }
}

struct BackendRuntimeStatus: Equatable {
    let capabilities: BackendCapabilities
    let entitlements: BackendEntitlements?
}

enum APNSEnvironment: String, Codable, Equatable {
    case sandbox
    case production

    static var current: APNSEnvironment {
        #if DEBUG
        return .sandbox
        #else
        return .production
        #endif
    }
}

struct BackendDeviceRegistrationRequest: Encodable, Equatable {
    let platform: String
    let provider: String
    let token: String
    let apnsEnvironment: APNSEnvironment

    private enum CodingKeys: String, CodingKey {
        case platform
        case provider
        case token
        case apnsEnvironment = "environment"
    }
}

struct BackendDeviceTestPushRequest: Encodable, Equatable {
    let platform: String
    let provider: String
    let token: String
    let apnsEnvironment: APNSEnvironment
    let title: String?
    let body: String?

    private enum CodingKeys: String, CodingKey {
        case platform
        case provider
        case token
        case apnsEnvironment = "environment"
        case title
        case body
    }
}

struct BackendDeviceRecord: Codable, Equatable {
    let userId: String
    let platform: String
    let provider: String?
    let tokenHash: String
    let endpointArn: String?
    let createdAt: String
    let updatedAt: String
}

struct BackendDeviceRegistrationResult: Codable, Equatable {
    let registered: Bool
    let device: BackendDeviceRecord
}

struct BackendDeviceUnregistrationResult: Codable, Equatable {
    let unregistered: Bool
    let existed: Bool
}

struct BackendDeviceTestPushResult: Codable, Equatable {
    let sent: Bool
    let endpointArn: String?
    let messageId: String?
}

struct BackendSpaceMemberDeleteResult: Codable, Equatable {
    let removed: Bool?
    let left: Bool?
}

@MainActor
protocol BackendServicing {
    var configuration: BackendConfiguration? { get }
    func fetchStatus(idToken: String?) async throws -> BackendRuntimeStatus
    func registerDevice(idToken: String, request: BackendDeviceRegistrationRequest) async throws -> BackendDeviceRegistrationResult
    func sendTestPush(idToken: String, request: BackendDeviceTestPushRequest) async throws -> BackendDeviceTestPushResult
    func unregisterDevice(idToken: String, request: BackendDeviceRegistrationRequest) async throws -> BackendDeviceUnregistrationResult
    func listSpaces(idToken: String) async throws -> [SpaceSummary]
    func getFamilySharingModel(idToken: String, spaceID: String) async throws -> FamilySharingModel
    func listInvites(idToken: String) async throws -> [SpaceInvite]
    func createInvite(idToken: String, input: CreateInviteInput) async throws -> CreateInviteResult
    func acceptInvite(idToken: String, code: String) async throws -> AcceptInviteResult
    func listSpaceMembers(idToken: String, spaceID: String) async throws -> [SpaceMember]
    func listSpaceInvites(idToken: String, spaceID: String) async throws -> [SpaceInvite]
    func getSpaceMember(idToken: String, spaceID: String, memberUserID: String) async throws -> SpaceMember
    func updateSpaceMember(idToken: String, spaceID: String, memberUserID: String, patch: UpdateSpaceMemberPatch) async throws
    func removeSpaceMember(idToken: String, spaceID: String, memberUserID: String) async throws -> BackendSpaceMemberDeleteResult
    func revokeSpaceInvite(idToken: String, spaceID: String, code: String) async throws
}

enum DefaultBackendService {
    @MainActor
    static func make() -> BackendServicing {
        if let configuration = BackendConfiguration.liveFromBundle() {
            return LiveBackendService(configuration: configuration)
        }
        return PreviewBackendService()
    }
}

enum BackendServiceError: LocalizedError, Equatable {
    case configurationMissing
    case invalidResponse(statusCode: Int, body: String)
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .configurationMissing:
            return "Cloud backend is not configured in the app bundle."
        case let .invalidResponse(statusCode, body):
            let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedBody.isEmpty {
                return AppLocalization.localized("Cloud backend returned HTTP %d.", arguments: statusCode)
            }
            return AppLocalization.localized("Cloud backend returned HTTP %d: %@", arguments: statusCode, trimmedBody)
        case .invalidPayload:
            return "Cloud backend returned an unexpected payload."
        }
    }
}

private struct BackendCapabilitiesEnvelope: Decodable {
    let capabilities: BackendCapabilities
}

private struct BackendEntitlementsEnvelope: Decodable {
    let entitlements: BackendEntitlements
}

private struct BackendDeviceRegistrationEnvelope: Decodable {
    let registered: Bool
    let device: BackendDeviceRecord
}

private struct BackendDeviceUnregistrationEnvelope: Decodable {
    let unregistered: Bool
    let existed: Bool
}

private struct BackendDeviceTestPushEnvelope: Decodable {
    let sent: Bool
    let endpointArn: String?
    let messageId: String?
}

private struct BackendSpacesEnvelope: Decodable {
    let spaces: [SpaceSummary]
}

private struct BackendFamilyModelEnvelope: Decodable {
    let model: FamilySharingModel
}

private struct BackendInvitesEnvelope: Decodable {
    let invites: [SpaceInvite]
}

private struct BackendInviteCreateEnvelope: Decodable {
    let invite: SpaceInvite
    let deepLink: String
    let webLink: String?
    let emailDelivery: InviteEmailDelivery?
}

private struct BackendInviteAcceptEnvelope: Decodable {
    let accepted: Bool
    let spaceId: String
    let role: SpaceRole
}

private struct BackendMembersEnvelope: Decodable {
    let members: [SpaceMember]
}

private struct BackendMemberEnvelope: Decodable {
    let member: SpaceMember
}

private struct BackendUpdatedEnvelope: Decodable {
    let updated: Bool
}

private struct BackendRevokedEnvelope: Decodable {
    let revoked: Bool
}

private struct BackendRemovedEnvelope: Decodable {
    let removed: Bool?
    let left: Bool?
}

@MainActor
final class LiveBackendService: BackendServicing {
    let configuration: BackendConfiguration?

    init(configuration: BackendConfiguration) {
        self.configuration = configuration
    }

    func fetchStatus(idToken: String?) async throws -> BackendRuntimeStatus {
        let capabilities = try await fetchCapabilities(idToken: idToken)
        let entitlements = try await fetchEntitlements(idToken: idToken)
        return BackendRuntimeStatus(capabilities: capabilities, entitlements: entitlements)
    }

    func registerDevice(
        idToken: String,
        request registrationRequest: BackendDeviceRegistrationRequest
    ) async throws -> BackendDeviceRegistrationResult {
        let body = try BackendJSON.encoder.encode(registrationRequest)
        let request = try makeRequest(
            path: "/devices/register",
            method: "POST",
            idToken: idToken,
            body: body
        )
        let response = try await perform(request, as: BackendDeviceRegistrationEnvelope.self)
        return BackendDeviceRegistrationResult(registered: response.registered, device: response.device)
    }

    func sendTestPush(
        idToken: String,
        request testPushRequest: BackendDeviceTestPushRequest
    ) async throws -> BackendDeviceTestPushResult {
        let body = try BackendJSON.encoder.encode(testPushRequest)
        let request = try makeRequest(
            path: "/devices/test-push",
            method: "POST",
            idToken: idToken,
            body: body
        )
        let response = try await perform(request, as: BackendDeviceTestPushEnvelope.self)
        return BackendDeviceTestPushResult(sent: response.sent, endpointArn: response.endpointArn, messageId: response.messageId)
    }

    func unregisterDevice(
        idToken: String,
        request registrationRequest: BackendDeviceRegistrationRequest
    ) async throws -> BackendDeviceUnregistrationResult {
        let body = try BackendJSON.encoder.encode(registrationRequest)
        let request = try makeRequest(
            path: "/devices/unregister",
            method: "POST",
            idToken: idToken,
            body: body
        )
        let response = try await perform(request, as: BackendDeviceUnregistrationEnvelope.self)
        return BackendDeviceUnregistrationResult(unregistered: response.unregistered, existed: response.existed)
    }

    func listSpaces(idToken: String) async throws -> [SpaceSummary] {
        let response = try await requestJSON(path: "/spaces", idToken: idToken, as: BackendSpacesEnvelope.self)
        return response.spaces
    }

    func getFamilySharingModel(idToken: String, spaceID: String) async throws -> FamilySharingModel {
        let response = try await requestJSON(
            path: "/spaces/\(spaceID)/family-model",
            idToken: idToken,
            as: BackendFamilyModelEnvelope.self
        )
        return response.model
    }

    func listInvites(idToken: String) async throws -> [SpaceInvite] {
        let response = try await requestJSON(path: "/spaces/invites", idToken: idToken, as: BackendInvitesEnvelope.self)
        return response.invites
    }

    func createInvite(idToken: String, input: CreateInviteInput) async throws -> CreateInviteResult {
        let body = try BackendJSON.encoder.encode(input)
        let request = try makeRequest(
            path: "/spaces/invites",
            method: "POST",
            idToken: idToken,
            body: body
        )
        let response = try await perform(request, as: BackendInviteCreateEnvelope.self)
        return CreateInviteResult(
            invite: response.invite,
            deepLink: response.deepLink,
            webLink: response.webLink,
            emailDelivery: response.emailDelivery
        )
    }

    func acceptInvite(idToken: String, code: String) async throws -> AcceptInviteResult {
        let body = try BackendJSON.encoder.encode(["code": code])
        let request = try makeRequest(
            path: "/spaces/invites/accept",
            method: "POST",
            idToken: idToken,
            body: body
        )
        let response = try await perform(request, as: BackendInviteAcceptEnvelope.self)
        return AcceptInviteResult(accepted: response.accepted, spaceId: response.spaceId, role: response.role)
    }

    func listSpaceMembers(idToken: String, spaceID: String) async throws -> [SpaceMember] {
        let response = try await requestJSON(
            path: "/spaces/\(spaceID)/members",
            idToken: idToken,
            as: BackendMembersEnvelope.self
        )
        return response.members
    }

    func listSpaceInvites(idToken: String, spaceID: String) async throws -> [SpaceInvite] {
        let response = try await requestJSON(
            path: "/spaces/\(spaceID)/invites",
            idToken: idToken,
            as: BackendInvitesEnvelope.self
        )
        return response.invites
    }

    func getSpaceMember(idToken: String, spaceID: String, memberUserID: String) async throws -> SpaceMember {
        let response = try await requestJSON(
            path: "/spaces/\(spaceID)/members/\(memberUserID)",
            idToken: idToken,
            as: BackendMemberEnvelope.self
        )
        return response.member
    }

    func updateSpaceMember(
        idToken: String,
        spaceID: String,
        memberUserID: String,
        patch: UpdateSpaceMemberPatch
    ) async throws {
        let body = try BackendJSON.encoder.encode(patch)
        let request = try makeRequest(
            path: "/spaces/\(spaceID)/members/\(memberUserID)",
            method: "PATCH",
            idToken: idToken,
            body: body
        )
        _ = try await perform(request, as: BackendUpdatedEnvelope.self)
    }

    func removeSpaceMember(
        idToken: String,
        spaceID: String,
        memberUserID: String
    ) async throws -> BackendSpaceMemberDeleteResult {
        let request = try makeRequest(
            path: "/spaces/\(spaceID)/members/\(memberUserID)",
            method: "DELETE",
            idToken: idToken
        )
        let response = try await perform(request, as: BackendRemovedEnvelope.self)
        return BackendSpaceMemberDeleteResult(removed: response.removed, left: response.left)
    }

    func revokeSpaceInvite(idToken: String, spaceID: String, code: String) async throws {
        let request = try makeRequest(
            path: "/spaces/\(spaceID)/invites/\(code)",
            method: "DELETE",
            idToken: idToken
        )
        _ = try await perform(request, as: BackendRevokedEnvelope.self)
    }

    private func fetchCapabilities(idToken: String?) async throws -> BackendCapabilities {
        if let idToken, !idToken.isEmpty {
            do {
                let wrapped = try await requestJSON(
                    path: "/v1/app/capabilities",
                    idToken: idToken,
                    as: BackendCapabilitiesEnvelope.self
                )
                return wrapped.capabilities
            } catch let error as BackendServiceError {
                switch error {
                case let .invalidResponse(statusCode, _):
                    if [401, 403, 404].contains(statusCode) == false {
                        throw error
                    }
                default:
                    throw error
                }
            }
        }

        return try await requestJSON(path: "/public/capabilities", as: BackendCapabilities.self)
    }

    private func fetchEntitlements(idToken: String?) async throws -> BackendEntitlements? {
        guard let idToken, !idToken.isEmpty else { return nil }

        do {
            let wrapped = try await requestJSON(
                path: "/billing/entitlements",
                idToken: idToken,
                as: BackendEntitlementsEnvelope.self
            )
            return wrapped.entitlements
        } catch let error as BackendServiceError {
            switch error {
            case let .invalidResponse(statusCode, _):
                if [401, 403, 404].contains(statusCode) {
                    return nil
                }
            default:
                break
            }
            throw error
        }
    }

    private func requestJSON<Response: Decodable>(
        path: String,
        idToken: String? = nil,
        as responseType: Response.Type
    ) async throws -> Response {
        let request = try makeRequest(path: path, method: "GET", idToken: idToken)
        return try await perform(request, as: responseType)
    }

    private func makeRequest(
        path: String,
        method: String,
        idToken: String? = nil,
        body: Data? = nil
    ) throws -> URLRequest {
        guard let configuration else {
            throw BackendServiceError.configurationMissing
        }

        var request = URLRequest(url: configuration.url(for: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let idToken, !idToken.isEmpty {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func perform<Response: Decodable>(
        _ request: URLRequest,
        as responseType: Response.Type
    ) async throws -> Response {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendServiceError.invalidPayload
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw BackendServiceError.invalidResponse(statusCode: httpResponse.statusCode, body: body)
        }

        do {
            return try BackendJSON.decoder.decode(Response.self, from: data)
        } catch {
            throw BackendServiceError.invalidPayload
        }
    }
}

@MainActor
struct PreviewBackendService: BackendServicing {
    let configuration: BackendConfiguration? = nil

    func fetchStatus(idToken: String?) async throws -> BackendRuntimeStatus {
        throw BackendServiceError.configurationMissing
    }

    func registerDevice(idToken: String, request: BackendDeviceRegistrationRequest) async throws -> BackendDeviceRegistrationResult {
        throw BackendServiceError.configurationMissing
    }

    func sendTestPush(idToken: String, request: BackendDeviceTestPushRequest) async throws -> BackendDeviceTestPushResult {
        throw BackendServiceError.configurationMissing
    }

    func unregisterDevice(idToken: String, request: BackendDeviceRegistrationRequest) async throws -> BackendDeviceUnregistrationResult {
        throw BackendServiceError.configurationMissing
    }

    func listSpaces(idToken: String) async throws -> [SpaceSummary] {
        throw BackendServiceError.configurationMissing
    }

    func getFamilySharingModel(idToken: String, spaceID: String) async throws -> FamilySharingModel {
        throw BackendServiceError.configurationMissing
    }

    func listInvites(idToken: String) async throws -> [SpaceInvite] {
        throw BackendServiceError.configurationMissing
    }

    func createInvite(idToken: String, input: CreateInviteInput) async throws -> CreateInviteResult {
        throw BackendServiceError.configurationMissing
    }

    func acceptInvite(idToken: String, code: String) async throws -> AcceptInviteResult {
        throw BackendServiceError.configurationMissing
    }

    func listSpaceMembers(idToken: String, spaceID: String) async throws -> [SpaceMember] {
        throw BackendServiceError.configurationMissing
    }

    func listSpaceInvites(idToken: String, spaceID: String) async throws -> [SpaceInvite] {
        throw BackendServiceError.configurationMissing
    }

    func getSpaceMember(idToken: String, spaceID: String, memberUserID: String) async throws -> SpaceMember {
        throw BackendServiceError.configurationMissing
    }

    func updateSpaceMember(idToken: String, spaceID: String, memberUserID: String, patch: UpdateSpaceMemberPatch) async throws {
        throw BackendServiceError.configurationMissing
    }

    func removeSpaceMember(idToken: String, spaceID: String, memberUserID: String) async throws -> BackendSpaceMemberDeleteResult {
        throw BackendServiceError.configurationMissing
    }

    func revokeSpaceInvite(idToken: String, spaceID: String, code: String) async throws {
        throw BackendServiceError.configurationMissing
    }
}

private enum BackendJSON {
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static let encoder: JSONEncoder = {
        JSONEncoder()
    }()
}
