import Testing
@testable import SpendSage

struct ProfileCompletionTests {
    @Test
    func defaultProfileRequiresWelcomeSetupForSignedInUser() {
        let profile = ProfileRecord.default

        #expect(profile.needsWelcomeProfile(for: "ruben@spendsage.ai"))
    }

    @Test
    func customizedProfileDoesNotRequireWelcomeSetup() {
        let profile = ProfileRecord(
            fullName: "Ruben Lazaro",
            householdName: "Mi hogar",
            email: "ruben@spendsage.ai",
            countryCode: "EC",
            marketingOptIn: false
        )

        #expect(profile.needsWelcomeProfile(for: "ruben@spendsage.ai") == false)
    }
}
