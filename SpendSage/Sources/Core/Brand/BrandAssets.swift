import Foundation
import SwiftUI
import UIKit

enum BrandSeasonID: String, CaseIterable, Codable, Hashable {
    case halloween
    case winterHolidays
    case newYear
}

struct BrandSeasonWindow: Hashable {
    let startMonth: Int
    let startDay: Int
    let endMonth: Int
    let endDay: Int

    func contains(_ date: Date, calendar: Calendar = .autoupdatingCurrent) -> Bool {
        let components = calendar.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else { return false }
        let current = month * 100 + day
        let start = startMonth * 100 + startDay
        let end = endMonth * 100 + endDay

        if start <= end {
            return current >= start && current <= end
        }

        return current >= start || current <= end
    }

    func nextStart(after date: Date, calendar: Calendar = .autoupdatingCurrent) -> Date? {
        let year = calendar.component(.year, from: date)
        let candidateYears = [year, year + 1]

        return candidateYears
            .compactMap { candidateYear in
                var components = DateComponents()
                components.year = candidateYear
                components.month = startMonth
                components.day = startDay
                return calendar.date(from: components)
            }
            .first(where: { $0 >= calendar.startOfDay(for: date) })
    }
}

struct BrandSeasonDefinition: Hashable, Identifiable {
    let id: BrandSeasonID
    let title: String
    let summary: String
    let badgeText: String
    let badgeAsset: String
    let spotlightGuideKey: String
    let guideOverrides: [String: String]
    let windows: [BrandSeasonWindow]
    let priority: Int

    func isActive(on date: Date, calendar: Calendar = .autoupdatingCurrent) -> Bool {
        windows.contains { $0.contains(date, calendar: calendar) }
    }

    func nextStart(after date: Date, calendar: Calendar = .autoupdatingCurrent) -> Date? {
        windows
            .compactMap { $0.nextStart(after: date, calendar: calendar) }
            .sorted()
            .first
    }
}

enum BrandSeasonCatalog {
    static let seasons: [BrandSeasonDefinition] = [
        BrandSeasonDefinition(
            id: .halloween,
            title: "Halloween Hunt",
            summary: "Spooky mission art, event badges, and a short questline show up around the dashboard loop.",
            badgeText: "Halloween live",
            badgeAsset: "badge_event_halloween_v2.png",
            spotlightGuideKey: "guide_01_dashboard_game_manchas",
            guideOverrides: [
                "guide_01_dashboard_game_manchas": "guide_01_dashboard_game_manchas_halloween",
                "guide_25_splash_team": "guide_25_splash_team_halloween",
                "guide_26_loading_yarn_team": "guide_26_loading_yarn_team_halloween"
            ],
            windows: [
                BrandSeasonWindow(startMonth: 10, startDay: 20, endMonth: 11, endDay: 2)
            ],
            priority: 0
        ),
        BrandSeasonDefinition(
            id: .winterHolidays,
            title: "Holiday Gift Guard",
            summary: "Festive splash art, cozy loading scenes, and spending guardrails keep December feeling intentional.",
            badgeText: "Holiday live",
            badgeAsset: "badge_event_holiday_v2.png",
            spotlightGuideKey: "guide_25_splash_team",
            guideOverrides: [
                "guide_01_dashboard_game_manchas": "guide_01_dashboard_game_manchas_holiday",
                "guide_25_splash_team": "guide_25_splash_team_holiday",
                "guide_26_loading_yarn_team": "guide_26_loading_yarn_team_holiday"
            ],
            windows: [
                BrandSeasonWindow(startMonth: 12, startDay: 1, endMonth: 12, endDay: 28)
            ],
            priority: 1
        ),
        BrandSeasonDefinition(
            id: .newYear,
            title: "New Year Reset",
            summary: "The festive art stays warm while the mission board shifts into reset, fresh-start, and cleanup goals.",
            badgeText: "Reset live",
            badgeAsset: "badge_event_new_year_v2.png",
            spotlightGuideKey: "guide_26_loading_yarn_team",
            guideOverrides: [
                "guide_01_dashboard_game_manchas": "guide_01_dashboard_game_manchas_holiday",
                "guide_25_splash_team": "guide_25_splash_team_holiday",
                "guide_26_loading_yarn_team": "guide_26_loading_yarn_team_holiday"
            ],
            windows: [
                BrandSeasonWindow(startMonth: 12, startDay: 29, endMonth: 1, endDay: 14)
            ],
            priority: 2
        )
    ]

    static func activeSeason(on date: Date = .now, calendar: Calendar = .autoupdatingCurrent) -> BrandSeasonDefinition? {
        seasons
            .filter { $0.isActive(on: date, calendar: calendar) }
            .sorted { lhs, rhs in lhs.priority < rhs.priority }
            .first
    }

    static func nextSeason(after date: Date = .now, calendar: Calendar = .autoupdatingCurrent) -> (season: BrandSeasonDefinition, startDate: Date)? {
        let upcoming: [(season: BrandSeasonDefinition, startDate: Date)] = seasons.compactMap { season in
                guard let startDate = season.nextStart(after: date, calendar: calendar) else { return nil }
                return (season, startDate)
            }
        return upcoming
            .sorted { lhs, rhs in lhs.startDate < rhs.startDate }
            .first
    }

    static func season(for id: BrandSeasonID) -> BrandSeasonDefinition? {
        seasons.first { $0.id == id }
    }

    static func contains(_ date: Date, in season: BrandSeasonDefinition, calendar: Calendar = .autoupdatingCurrent) -> Bool {
        season.isActive(on: date, calendar: calendar)
    }

    static func resolvedGuideKey(_ key: String, on date: Date = .now, calendar: Calendar = .autoupdatingCurrent) -> String {
        activeSeason(on: date, calendar: calendar)?.guideOverrides[key] ?? key
    }
}

enum BrandVersion: String, CaseIterable, Codable {
    case v1
    case v2
}

enum BrandCharacterID: String, CaseIterable, Codable, Hashable {
    case tikki
    case mei
    case manchas

    var narrativeName: String {
        switch self {
        case .tikki:
            return "Tikki".appLocalized
        case .mei:
            return "Ludo".appLocalized
        case .manchas:
            return "Manchas".appLocalized
        }
    }
}

enum BrandExpression: String, CaseIterable, Codable, Hashable {
    case neutral
    case happy
    case thinking
    case warning
    case proud
    case shocked
    case sad
    case angry
    case excited
    case sleepy
    case confused
    case love
}

enum BrandLogoKind: String, CaseIterable, Hashable {
    case mark
    case appIcon
    case wordmark
}

enum BrandAssetCategory: String, Hashable {
    case characters
    case guides
    case badges
    case accessories
    case logo
}

struct BrandAssetSource: Hashable, Identifiable {
    let category: BrandAssetCategory
    let fileName: String
    let version: BrandVersion

    var id: String {
        "\(version.rawValue)-\(category.rawValue)-\(fileName)"
    }

    var subdirectory: String {
        "Brand/\(version.rawValue)/\(category.rawValue)"
    }
}

struct BrandAssetManifest: Decodable {
    struct CharacterAsset: Decodable {
        let base: String
        let expressions: [String: String]
    }

    struct LogoAsset: Decodable {
        let mark: String
        let appIcon: String
        let wordmark: String
    }

    let version: BrandVersion
    let characters: [String: CharacterAsset]
    let guides: [String: String]
    let badges: [String]
    let accessories: [String]
    let logo: LogoAsset
}

@MainActor
final class BrandAssetCatalog {
    static let shared = BrandAssetCatalog()

    private let version: BrandVersion
    private let bundle: Bundle
    private let manifest: BrandAssetManifest
    private let imageCache = NSCache<NSString, UIImage>()

    init(version: BrandVersion = .v2, bundle: Bundle = .main) {
        self.version = version
        self.bundle = bundle
        self.manifest = Self.loadManifest(version: version, bundle: bundle)
    }

    var activeVersion: BrandVersion { version }
    var activeManifest: BrandAssetManifest { manifest }

    func character(_ id: BrandCharacterID, expression: BrandExpression = .neutral) -> BrandAssetSource? {
        guard let character = manifest.characters[id.rawValue] else { return nil }
        let fileName = character.expressions[expression.rawValue] ?? character.base
        return BrandAssetSource(category: .characters, fileName: fileName, version: version)
    }

    func guide(_ key: String) -> BrandAssetSource? {
        let fallback = manifest.guides.values.sorted().first
        let resolvedKey = BrandSeasonCatalog.resolvedGuideKey(key)
        guard let fileName = manifest.guides[resolvedKey] ?? manifest.guides[key] ?? fallback else { return nil }
        return BrandAssetSource(category: .guides, fileName: fileName, version: version)
    }

    func guideIfAvailable(_ key: String) -> BrandAssetSource? {
        let resolvedKey = BrandSeasonCatalog.resolvedGuideKey(key)
        guard let fileName = manifest.guides[resolvedKey] ?? manifest.guides[key] else { return nil }
        return BrandAssetSource(category: .guides, fileName: fileName, version: version)
    }

    func guide(fileName: String) -> BrandAssetSource {
        BrandAssetSource(category: .guides, fileName: fileName, version: version)
    }

    func logo(_ kind: BrandLogoKind) -> BrandAssetSource {
        let fileName: String
        switch kind {
        case .mark:
            fileName = manifest.logo.mark
        case .appIcon:
            fileName = manifest.logo.appIcon
        case .wordmark:
            fileName = manifest.logo.wordmark
        }
        return BrandAssetSource(category: .logo, fileName: fileName, version: version)
    }

    func badge(named fileName: String) -> BrandAssetSource {
        BrandAssetSource(category: .badges, fileName: fileName, version: version)
    }

    func accessory(named fileName: String) -> BrandAssetSource {
        BrandAssetSource(category: .accessories, fileName: fileName, version: version)
    }

    func allBadgeAssets() -> [BrandAssetSource] {
        manifest.badges.map(badge(named:))
    }

    func allAccessoryAssets() -> [BrandAssetSource] {
        manifest.accessories.map(accessory(named:))
    }

    func allGuideAssets() -> [(key: String, source: BrandAssetSource)] {
        manifest.guides.keys.sorted().compactMap { key in
            guard let source = guide(key) else { return nil }
            return (key, source)
        }
    }

    func image(for source: BrandAssetSource?) -> UIImage? {
        guard let source else { return nil }
        let cacheKey = source.id as NSString
        if let cached = imageCache.object(forKey: cacheKey) {
            return cached
        }
        guard let url = url(for: source), let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        imageCache.setObject(image, forKey: cacheKey)
        return image
    }

    func url(for source: BrandAssetSource?) -> URL? {
        guard let source else { return nil }
        let nsFile = source.fileName as NSString
        let name = nsFile.deletingPathExtension
        let ext = nsFile.pathExtension.isEmpty ? nil : nsFile.pathExtension
        if let nestedURL = bundle.url(forResource: name, withExtension: ext, subdirectory: source.subdirectory) {
            return nestedURL
        }
        return bundle.url(forResource: name, withExtension: ext)
    }

    private static func loadManifest(version: BrandVersion, bundle: Bundle) -> BrandAssetManifest {
        let nestedURL = bundle.url(
            forResource: "asset_manifest",
            withExtension: "json",
            subdirectory: "Brand/\(version.rawValue)"
        )
        let rootURL = bundle.url(forResource: "asset_manifest", withExtension: "json")

        guard let url = nestedURL ?? rootURL else {
            preconditionFailure("Missing Brand asset manifest for \(version.rawValue)")
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(BrandAssetManifest.self, from: data)
        } catch {
            preconditionFailure("Failed to decode Brand asset manifest: \(error)")
        }
    }
}
