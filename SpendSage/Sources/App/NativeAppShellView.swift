import SwiftUI

struct NativeAppShellView: View {
    @ObservedObject var viewModel: AppViewModel

    private let leadingTabs: [AppViewModel.AppTab] = [.dashboard, .expenses]
    private let trailingTabs: [AppViewModel.AppTab] = [.insights, .settings]

    var body: some View {
        GeometryReader { proxy in
            let deviceBottomInset = proxy.safeAreaInsets.bottom
            let bottomNavigationContentPadding = max(deviceBottomInset - 14, 2)
            let bottomNavigationInset = ShellBarMetrics.backgroundHeight + bottomNavigationContentPadding + 12

            currentTabContent
                .tint(BrandTheme.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .environment(\.shellBottomInset, bottomNavigationInset)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomNavigation(
                        deviceBottomInset: deviceBottomInset,
                        bottomNavigationContentPadding: bottomNavigationContentPadding
                    )
                }
            .background(BrandTheme.background.ignoresSafeArea())
            .overlay(alignment: .topLeading) {
                AccessibilityProbe(identifier: "shell.current.\(viewModel.selectedTab.rawValue)")
            }
        }
        .sheet(item: $viewModel.activeSheet) { sheet in
            switch sheet {
            case .addExpense:
                SheetPresentationProbe(identifier: "addExpense.presented") {
                    AddExpenseView(viewModel: viewModel)
                }
            case .budgetWizard:
                SheetPresentationProbe(identifier: "budgetWizard.presented") {
                    BudgetWizardView(viewModel: viewModel)
                }
            }
        }
        .task {
            if viewModel.dashboardState == nil {
                await viewModel.refreshDashboard()
            }
        }
    }

    @ViewBuilder
    private var currentTabContent: some View {
        switch viewModel.selectedTab {
        case .dashboard:
            navigationShell {
                DashboardView(viewModel: viewModel)
            }
        case .expenses:
            navigationShell {
                ExpensesCenterView(viewModel: viewModel)
            }
        case .scan:
            navigationShell {
                FinanceReceiptScanToolView(viewModel: viewModel)
                    .id(viewModel.scanFlowID)
            }
        case .insights:
            navigationShell {
                InsightsView(viewModel: viewModel)
            }
        case .settings:
            navigationShell {
                SettingsView(viewModel: viewModel)
            }
        }
    }

    private func bottomNavigation(deviceBottomInset: CGFloat, bottomNavigationContentPadding: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            ShellNavigationBackground(bottomInset: deviceBottomInset)

            HStack(alignment: .center, spacing: 10) {
                ForEach(leadingTabs) { tab in
                    ShellNavigationButton(
                        tab: tab,
                        isSelected: viewModel.selectedTab == tab
                    ) {
                        select(tab)
                    }
                }

                ReceiptScanDockButton(isSelected: viewModel.selectedTab == .scan) {
                    viewModel.startScanFlow()
                }

                ForEach(trailingTabs) { tab in
                    ShellNavigationButton(
                        tab: tab,
                        isSelected: viewModel.selectedTab == tab
                    ) {
                        select(tab)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)
            .padding(.bottom, bottomNavigationContentPadding)
        }
        .frame(maxWidth: .infinity)
    }

    private func select(_ tab: AppViewModel.AppTab) {
        viewModel.selectedTab = tab
    }

    private func navigationShell<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content()
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(BrandTheme.background.opacity(0.92), for: .navigationBar)
        }
    }
}

private enum ShellBarMetrics {
    static let backgroundHeight: CGFloat = 66
}

private struct ShellBottomInsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var shellBottomInset: CGFloat {
        get { self[ShellBottomInsetKey.self] }
        set { self[ShellBottomInsetKey.self] = newValue }
    }
}

private struct ShellNavigationButton: View {
    let tab: AppViewModel.AppTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 17, weight: isSelected ? .bold : .semibold))
                    .frame(width: 36, height: 32)
                    .symbolRenderingMode(.hierarchical)

                Text(tab.title)
                    .font(.caption2.weight(isSelected ? .bold : .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? BrandTheme.primary : BrandTheme.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    BrandTheme.surface.opacity(0.98),
                                    BrandTheme.accent.opacity(0.16)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(BrandTheme.line.opacity(0.85), lineWidth: 1)
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("shell.tab.\(tab.rawValue)")
    }
}

private struct ReceiptScanDockButton: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    BrandTheme.primary,
                                    BrandTheme.glow,
                                    BrandTheme.accent
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .padding(3)
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(Color.white)
                }
                .frame(width: 56, height: 56)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(isSelected ? 0.72 : 0.34), lineWidth: isSelected ? 2 : 1)
                )
                .shadow(color: BrandTheme.primary.opacity(0.18), radius: 14, x: 0, y: 8)
                .shadow(color: BrandTheme.shadow.opacity(0.12), radius: 10, x: 0, y: 5)

                Text("Escanear")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isSelected ? BrandTheme.primary : BrandTheme.ink)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("shell.tab.scan")
    }
}

private struct ShellNavigationBackground: View {
    let bottomInset: CGFloat

    var body: some View {
        TopRoundedRectangle(cornerRadius: 30)
            .fill(
                LinearGradient(
                    colors: [
                        BrandTheme.surface.opacity(1),
                        BrandTheme.surfaceTint.opacity(0.98),
                        BrandTheme.surfaceTint.opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(alignment: .top) {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.56))
                    .frame(height: 1)
                    .padding(.horizontal, 32)
                    .padding(.top, 1.5)
            }
            .overlay {
                TopRoundedRectangle(cornerRadius: 30)
                    .fill(
                        LinearGradient(
                            colors: [
                                BrandTheme.glow.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .overlay {
                TopRoundedRectangle(cornerRadius: 30)
                    .stroke(BrandTheme.line.opacity(0.74), lineWidth: 1)
            }
            .shadow(color: BrandTheme.shadow.opacity(0.12), radius: 18, x: 0, y: -2)
            .frame(height: ShellBarMetrics.backgroundHeight + bottomInset, alignment: .top)
    }
}

private struct SheetPresentationProbe<Content: View>: View {
    let identifier: String
    @ViewBuilder let content: Content

    init(identifier: String, @ViewBuilder content: () -> Content) {
        self.identifier = identifier
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            content
            Text(identifier)
                .font(.system(size: 1))
                .foregroundStyle(Color.white.opacity(0.01))
                .padding(.leading, 2)
                .padding(.top, 2)
                .accessibilityIdentifier(identifier)
        }
    }
}

private struct TopRoundedRectangle: Shape {
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let radius = min(cornerRadius, min(rect.width / 2, rect.height))
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}
