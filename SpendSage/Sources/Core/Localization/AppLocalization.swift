import Foundation
import SwiftUI

enum AppLocalization {
    static let languageDefaultsKey = "native.settings.language"

    static func locale(for rawValue: String?) -> Locale {
        Locale(identifier: resolvedLanguageCode(from: rawValue))
    }

    static func resolvedLanguageCode(from rawValue: String?) -> String {
        let normalized = (rawValue ?? "auto").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "en", "en-us", "en-gb":
            return "en"
        case "es", "es-es", "es-mx", "es-419":
            return "es"
        case "auto", "":
            return deviceLanguageCode()
        default:
            return deviceLanguageCode()
        }
    }

    static func menuLabel(for rawValue: String?) -> String {
        switch resolvedLanguageCode(from: rawValue) {
        case "es":
            return rawValue == "auto" ? "Auto" : "ES"
        default:
            return rawValue == "auto" ? "Auto" : "EN"
        }
    }

    static func localized(_ key: String, rawValue: String? = nil) -> String {
        let languageCode = resolvedLanguageCode(from: rawValue ?? UserDefaults.standard.string(forKey: languageDefaultsKey))
        guard let bundle = bundle(for: languageCode) else {
            return key
        }

        let localized = NSLocalizedString(key, tableName: "Localizable", bundle: bundle, value: key, comment: "")
        return localized
    }

    static func localized(_ key: String, arguments: CVarArg..., rawValue: String? = nil) -> String {
        localized(key, arguments: arguments, rawValue: rawValue)
    }

    static func localized(_ key: String, arguments: [CVarArg], rawValue: String? = nil) -> String {
        let languageCode = resolvedLanguageCode(from: rawValue ?? UserDefaults.standard.string(forKey: languageDefaultsKey))
        guard let bundle = bundle(for: languageCode) else {
            return key
        }

        let format = NSLocalizedString(key, tableName: "Localizable", bundle: bundle, value: key, comment: "")
        guard !arguments.isEmpty else {
            return format
        }
        return String(format: format, locale: locale(for: languageCode), arguments: arguments)
    }

    private static func deviceLanguageCode() -> String {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
        if preferred.hasPrefix("es") {
            return "es"
        }
        return "en"
    }

    private static func bundle(for languageCode: String) -> Bundle? {
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return Bundle.main
        }
        return bundle
    }
}

extension String {
    var appLocalized: String {
        AppLocalization.localized(self)
    }
}
