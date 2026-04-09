import Foundation
import Testing
@testable import SpendSage

struct GrowthSnapshotCatalogTests {
    @Test
    func missionTracksSplitLocalCloudAndSpecial() {
        let context = GrowthMissionEvaluationContext(
            transactionCount: 10,
            streakDays: 4,
            uniqueExpenseDays: 5,
            accounts: 2,
            bills: 1,
            rules: 1,
            budgetHealthy: true,
            seasonalTransactionCount: 0,
            seasonalUniqueDayCount: 0,
            isAuthenticated: true,
            cloudSyncReady: true,
            sharedSpaceCount: 1,
            sharedMemberCount: 2,
            pendingInviteCount: 1,
            canInviteMembers: true
        )

        let local = GrowthMissionCatalog.localBlueprints.compactMap { $0.evaluate(in: context) }
        let cloud = GrowthMissionCatalog.cloudBlueprints.compactMap { $0.evaluate(in: context) }
        let special = GrowthMissionCatalog.specialBlueprints.compactMap { $0.evaluate(in: context) }

        #expect(local.count == 6)
        #expect(cloud.count == 4)
        #expect(special.count == 2)
        #expect(local.allSatisfy { $0.track == .local })
        #expect(cloud.allSatisfy { $0.track == .cloud })
        #expect(special.allSatisfy { $0.track == .special })
        #expect(cloud.first(where: { $0.id == "cloud-backup-awake" })?.status == .completed)
        #expect(special.first(where: { $0.id == "savings-foundation" })?.status == .completed)
    }

    @Test
    func inviteMissionStaysHiddenWithoutPermissions() {
        let context = GrowthMissionEvaluationContext(
            transactionCount: 5,
            streakDays: 2,
            uniqueExpenseDays: 2,
            accounts: 1,
            bills: 0,
            rules: 0,
            budgetHealthy: true,
            seasonalTransactionCount: 0,
            seasonalUniqueDayCount: 0,
            isAuthenticated: true,
            cloudSyncReady: false,
            sharedSpaceCount: 0,
            sharedMemberCount: 0,
            pendingInviteCount: 0,
            canInviteMembers: false
        )

        let cloud = GrowthMissionCatalog.cloudBlueprints.compactMap { $0.evaluate(in: context) }

        #expect(cloud.contains(where: { $0.id == "invite-on-the-way" }) == false)
        #expect(cloud.contains(where: { $0.id == "family-seat-filled" }) == false)
    }

    @Test
    func eventCalendarShowsActiveSeasonFirstAndIncludesMissionTitles() throws {
        let date = try #require(Calendar.autoupdatingCurrent.date(from: DateComponents(year: 2026, month: 12, day: 10)))

        let calendar = GrowthSnapshotBuilder.buildEventCalendar(referenceDate: date, calendar: .autoupdatingCurrent)

        #expect(calendar.first?.title == "Holiday Gift Guard")
        #expect(calendar.first?.isActive == true)
        #expect(calendar.first?.featuredMissionTitles.isEmpty == false)
    }
}
