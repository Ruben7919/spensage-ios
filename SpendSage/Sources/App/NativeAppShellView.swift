import SwiftUI

struct NativeAppShellView: View {
    @ObservedObject var viewModel: AppViewModel

    private let leadingTabs: [AppViewModel.AppTab] = [.dashboard, .expenses]
    private let trailingTabs: [AppViewModel.AppTab] = [.insights, .settings]

    var body: some View {
        VStack(spacing: 0) {
            currentTabContent
                .tint(BrandTheme.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .environment(\.shellBottomInset, 0)

            bottomNavigation
        }
        .background(BrandTheme.background.ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            AccessibilityProbe(identifier: "shell.current.\(viewModel.selectedTab.rawValue)")
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

    private var bottomNavigation: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [BrandTheme.shadow.opacity(0.08), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 12)

            HStack(alignment: .bottom, spacing: 14) {
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
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
        .background(
            TopRoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
                .overlay(
                    TopRoundedRectangle(cornerRadius: 30)
                        .fill(BrandTheme.surface.opacity(0.26))
                )
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.22), Color.white.opacity(0.04)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 1)
                }
                .overlay(
                    TopRoundedRectangle(cornerRadius: 30)
                        .stroke(BrandTheme.line.opacity(0.22), lineWidth: 0.8)
                )
                .shadow(color: BrandTheme.shadow.opacity(0.04), radius: 10, x: 0, y: -1)
                .ignoresSafeArea(edges: .bottom)
        )
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
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isSelected ? BrandTheme.accent.opacity(0.26) : Color.clear)
                    )

                Text(tab.title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? BrandTheme.primary : BrandTheme.muted)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .padding(.bottom, 2)
            .contentShape(Rectangle())
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
                        .fill(BrandTheme.heroGlowGradient)
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                .frame(width: 58, height: 58)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.75), lineWidth: isSelected ? 2 : 0)
                )
                .shadow(color: BrandTheme.shadow.opacity(0.2), radius: 16, x: 0, y: 10)

                Text("Escanear")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BrandTheme.primary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("shell.tab.scan")
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
