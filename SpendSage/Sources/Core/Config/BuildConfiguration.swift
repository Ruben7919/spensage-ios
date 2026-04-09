import Foundation

enum BuildConfiguration {
    private static let internalTestingInfoKey = "SpendSageInternalTestingEnabled"

    static func internalTestingEnabled(bundle: Bundle = .main) -> Bool {
        if let value = bundle.object(forInfoDictionaryKey: internalTestingInfoKey) as? Bool {
            return value
        }

        let rawValue = (bundle.object(forInfoDictionaryKey: internalTestingInfoKey) as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch rawValue {
        case "1", "true", "yes":
            return true
        default:
            return false
        }
    }
}
