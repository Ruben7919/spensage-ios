import Foundation
import Testing
@testable import SpendSage

@MainActor
struct BrandSeasonalAssetTests {
    @Test
    func halloweenMascotVariantResolvesFromCatalog() throws {
        let date = try #require(Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2026, month: 10, day: 31)))

        let source = BrandAssetCatalog.shared.character(.tikki, expression: .neutral, on: date)

        #expect(source?.fileName == "tikki_neutral_halloween_v2.png")
    }

    @Test
    func holidayMascotVariantResolvesFromCatalog() throws {
        let date = try #require(Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2026, month: 12, day: 12)))

        let source = BrandAssetCatalog.shared.character(.mei, expression: .happy, on: date)

        #expect(source?.fileName == "mei_happy_holiday_v2.png")
    }

    @Test
    func nonSeasonDateFallsBackToBaseSprite() throws {
        let date = try #require(Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2026, month: 4, day: 4)))

        let source = BrandAssetCatalog.shared.character(.manchas, expression: .proud, on: date)

        #expect(source?.fileName == "manchas_proud_v2.png")
    }

    @Test
    func liveEventPreviewStaysHiddenWhenSeasonIsStillFarAway() throws {
        let date = try #require(Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2026, month: 4, day: 5)))

        let liveEvent = GrowthSnapshotBuilder.buildLiveEvent(activeSeason: nil, referenceDate: date, calendar: .autoupdatingCurrent)

        #expect(liveEvent == nil)
    }

    @Test
    func liveEventPreviewAppearsInsideLeadWindow() throws {
        let date = try #require(Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2026, month: 10, day: 5)))

        let liveEvent = GrowthSnapshotBuilder.buildLiveEvent(activeSeason: nil, referenceDate: date, calendar: .autoupdatingCurrent)

        #expect(liveEvent?.isActive == false)
        #expect(liveEvent?.title == "Halloween Hunt")
    }
}
