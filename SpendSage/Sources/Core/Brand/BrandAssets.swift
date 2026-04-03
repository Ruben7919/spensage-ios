import Foundation
import SwiftUI
import UIKit

enum BrandVersion: String, CaseIterable, Codable {
    case v1
    case v2
}

enum BrandCharacterID: String, CaseIterable, Codable, Hashable {
    case tikki
    case mei
    case manchas
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
        guard let fileName = manifest.guides[key] ?? fallback else { return nil }
        return BrandAssetSource(category: .guides, fileName: fileName, version: version)
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
