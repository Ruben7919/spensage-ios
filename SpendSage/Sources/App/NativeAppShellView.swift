import SwiftUI
import UIKit

struct NativeAppShellView: View {
    @ObservedObject var viewModel: AppViewModel

    private let leadingTabs: [AppViewModel.AppTab] = [.dashboard, .expenses]
    private let trailingTabs: [AppViewModel.AppTab] = [.insights, .settings]

    var body: some View {
        VStack(spacing: 0) {
            currentTabContent
                .tint(BrandTheme.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomNavigation
        }
        .background(BrandTheme.background.ignoresSafeArea())
            .sheet(isPresented: Binding(
                get: { viewModel.isPresentingAddExpense },
                set: { viewModel.isPresentingAddExpense = $0 }
            )) {
                AddExpenseView(viewModel: viewModel)
            }
            .sheet(isPresented: Binding(
                get: { viewModel.isPresentingBudgetWizard },
                set: { viewModel.isPresentingBudgetWizard = $0 }
            )) {
                BudgetWizardView(viewModel: viewModel)
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
            TopRoundedTabBarShape(radius: 30)
                .fill(.ultraThinMaterial)
                .overlay(
                    TopRoundedTabBarShape(radius: 30)
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
                    TopRoundedTabBarShape(radius: 30)
                        .stroke(BrandTheme.line.opacity(0.22), lineWidth: 0.8)
                )
                .shadow(color: BrandTheme.shadow.opacity(0.04), radius: 10, x: 0, y: -1)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func select(_ tab: AppViewModel.AppTab) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            viewModel.selectedTab = tab
        }
    }

    private func navigationShell<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content()
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(BrandTheme.background.opacity(0.92), for: .navigationBar)
        }
    }
}

private struct TopRoundedTabBarShape: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let bezier = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(bezier.cgPath)
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
        }
        .buttonStyle(.plain)
    }
}

private struct ReceiptScanDockButton: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
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
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}
