import Foundation
import Testing
@testable import SpendSage

@MainActor
struct CrashGuardTests {
    @Test
    func missingBrandManifestFallsBackInsteadOfCrashing() {
        let catalog = BrandAssetCatalog(version: .v1, bundle: .main)

        #expect(catalog.activeVersion == .v1)
        #expect(catalog.activeManifest.version == .v1)
        #expect(catalog.activeManifest.guides.isEmpty)
        #expect(catalog.logo(.appIcon).fileName == "app_icon_v1.png")
    }

    @Test
    func fallbackGuideProvidesSafePlaceholderContent() {
        let guide = GuideLibrary.fallbackGuide(for: .dashboard)

        #expect(guide.id == .dashboard)
        #expect(guide.slides.count == 1)
        #expect(guide.slides.first?.imageKey == "guide_25_splash_team")
        #expect(guide.slides.first?.character == .manchas)
    }
}
