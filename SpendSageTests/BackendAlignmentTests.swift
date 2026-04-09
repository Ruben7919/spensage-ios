import Foundation
import Testing
@testable import SpendSage

struct BackendAlignmentTests {
    @Test
    func backendConfigurationNormalizesBaseURL() {
        let configuration = BackendConfiguration.make(
            apiBaseURL: " https://api.spendsage.ai/dev ",
            environmentName: " dev "
        )

        #expect(configuration?.apiBaseURL.absoluteString == "https://api.spendsage.ai/dev/")
        #expect(configuration?.environmentName == "dev")
        #expect(configuration?.hostLabel == "api.spendsage.ai")
    }

    @Test
    func backendConfigurationRejectsInvalidValues() {
        #expect(BackendConfiguration.make(apiBaseURL: nil, environmentName: nil) == nil)
        #expect(BackendConfiguration.make(apiBaseURL: "", environmentName: "dev") == nil)
        #expect(BackendConfiguration.make(apiBaseURL: "spendsage-api", environmentName: "dev") == nil)
    }

    @Test
    func entitlementsExposeReadablePlanName() {
        let entitlements = BackendEntitlements(
            userId: "user-1",
            planId: "family",
            features: ["family_owner", "remove_ads"],
            updatedAt: "2026-04-06T20:00:00.000Z"
        )

        #expect(entitlements.planDisplayName == "Family")
        #expect(entitlements.featuresDisplayLine == "family_owner, remove_ads")
    }

    @Test
    func persistedAuthSessionDecodesLegacyPayloadWithoutBreaking() throws {
        let legacyPayload = """
        {
          "email": "legacy@spendsage.ai",
          "provider": "Email",
          "refreshToken": "refresh-token",
          "storedAt": "2026-04-06T20:00:00Z"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let session = try decoder.decode(PersistedAuthSession.self, from: Data(legacyPayload.utf8))

        #expect(session.email == "legacy@spendsage.ai")
        #expect(session.provider == "Email")
        #expect(session.refreshToken == "refresh-token")
    }

    @Test
    func pushUploadMarkerRequestsUploadWhenNoMarkerExists() {
        #expect(
            PushRegistrationPersistence.shouldUpload(
                token: "abc-token",
                email: "user@spendsage.ai",
                environmentName: "dev",
                apnsEnvironment: .sandbox
            )
        )
    }

    @Test
    func pushUploadMarkerRequestsUploadWhenApnsEnvironmentChanges() {
        PushRegistrationPersistence.recordUpload(
            token: "abc-token",
            email: "user@spendsage.ai",
            environmentName: "dev",
            apnsEnvironment: .sandbox
        )

        #expect(
            PushRegistrationPersistence.shouldUpload(
                token: "abc-token",
                email: "user@spendsage.ai",
                environmentName: "dev",
                apnsEnvironment: .production
            )
        )
    }

    @Test
    func deviceRegistrationRequestEncodesExpectedKeys() throws {
        let request = BackendDeviceRegistrationRequest(
            platform: "ios",
            provider: "apns",
            token: "abcd1234efgh5678",
            apnsEnvironment: .sandbox
        )

        let data = try JSONEncoder().encode(request)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])

        #expect(json["platform"] == "ios")
        #expect(json["provider"] == "apns")
        #expect(json["token"] == "abcd1234efgh5678")
        #expect(json["environment"] == "sandbox")
    }

    @Test
    func deviceRegistrationResponseDecodesBackendRecord() throws {
        let payload = """
        {
          "registered": true,
          "device": {
            "userId": "user-1",
            "platform": "ios",
            "provider": "apns",
            "tokenHash": "hash-1",
            "endpointArn": "arn:aws:sns:us-east-1:123456789012:endpoint/APNS_SANDBOX/app/endpoint",
            "createdAt": "2026-04-06T20:00:00.000Z",
            "updatedAt": "2026-04-06T20:00:00.000Z"
          }
        }
        """

        let decoded = try JSONDecoder().decode(BackendDeviceRegistrationResult.self, from: Data(payload.utf8))

        #expect(decoded.registered)
        #expect(decoded.device.platform == "ios")
        #expect(decoded.device.provider == "apns")
        #expect(decoded.device.tokenHash == "hash-1")
    }
}
