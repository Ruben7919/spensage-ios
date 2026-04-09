import SwiftUI
import UIKit

@main
struct SpendSageApp: App {
    @UIApplicationDelegateAdaptor(SpendSageAppDelegate.self) private var appDelegate
    @StateObject private var viewModel = AppViewModel()
    @AppStorage(AppLocalization.languageDefaultsKey) private var language = "auto"
    @AppStorage(AppAppearance.themeDefaultsKey) private var theme = "finance"

    init() {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            UIView.setAnimationsEnabled(false)
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(viewModel: viewModel)
                .environment(\.locale, AppLocalization.locale(for: language))
                .preferredColorScheme(AppAppearance.colorScheme(for: theme))
        }
    }
}
