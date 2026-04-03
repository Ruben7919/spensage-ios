import SwiftUI

@main
struct SpendSageApp: App {
    @StateObject private var viewModel = AppViewModel()
    @AppStorage(AppLocalization.languageDefaultsKey) private var language = "auto"
    @AppStorage(AppAppearance.themeDefaultsKey) private var theme = "finance"

    var body: some Scene {
        WindowGroup {
            AppRootView(viewModel: viewModel)
                .environment(\.locale, AppLocalization.locale(for: language))
                .preferredColorScheme(AppAppearance.colorScheme(for: theme))
        }
    }
}
