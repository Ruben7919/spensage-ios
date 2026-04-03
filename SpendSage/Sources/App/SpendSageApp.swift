import SwiftUI

@main
struct SpendSageApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            AppRootView(viewModel: viewModel)
        }
    }
}

