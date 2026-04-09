import Foundation

struct BackendConfiguration: Equatable {
    static let apiBaseURLInfoKey = "SpendSageAPIBaseURL"
    static let environmentNameInfoKey = "SpendSageEnvironmentName"

    let apiBaseURL: URL
    let environmentName: String

    static func liveFromBundle(_ bundle: Bundle = .main) -> BackendConfiguration? {
        let rawBaseURL = bundle.object(forInfoDictionaryKey: apiBaseURLInfoKey) as? String
        let rawEnvironment = bundle.object(forInfoDictionaryKey: environmentNameInfoKey) as? String
        return make(apiBaseURL: rawBaseURL, environmentName: rawEnvironment)
    }

    static func make(apiBaseURL rawBaseURL: String?, environmentName rawEnvironmentName: String?) -> BackendConfiguration? {
        let trimmedBaseURL = rawBaseURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedBaseURL.isEmpty else { return nil }

        let normalizedBaseURL = trimmedBaseURL.hasSuffix("/") ? trimmedBaseURL : trimmedBaseURL + "/"
        guard
            let apiBaseURL = URL(string: normalizedBaseURL),
            let scheme = apiBaseURL.scheme?.lowercased(),
            ["http", "https"].contains(scheme)
        else {
            return nil
        }

        let trimmedEnvironmentName = rawEnvironmentName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let environmentName = trimmedEnvironmentName.isEmpty
            ? (apiBaseURL.pathComponents.last(where: { $0 != "/" }) ?? "unknown")
            : trimmedEnvironmentName

        return BackendConfiguration(apiBaseURL: apiBaseURL, environmentName: environmentName)
    }

    var hostLabel: String {
        apiBaseURL.host ?? apiBaseURL.absoluteString
    }

    func url(for path: String) -> URL {
        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return apiBaseURL.appendingPathComponent(normalizedPath)
    }
}
