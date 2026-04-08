import XCTest

final class SpendSageUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testShellTabsNavigateAcrossPrimarySections() {
        let app = makeApp(startingTab: "dashboard")
        app.launch()

        assertNavigationTitle("Inicio", in: app)

        app.buttons["shell.tab.expenses"].firstMatch.tap()
        assertNavigationTitle("Gastos", in: app)

        app.buttons["shell.tab.insights"].firstMatch.tap()
        assertNavigationTitle("Análisis", in: app)

        app.buttons["shell.tab.settings"].firstMatch.tap()
        assertNavigationTitle("Ajustes", in: app)

        app.buttons["shell.tab.dashboard"].firstMatch.tap()
        assertNavigationTitle("Inicio", in: app)

        app.buttons["shell.tab.scan"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Guía"].firstMatch.waitForExistence(timeout: 8))
    }

    @MainActor
    func testSettingsProfileNavigationOpensDestination() {
        assertSettingsRoute(
            triggerID: "settings.link.profile",
            destinationTitle: "Perfil"
        )
    }

    @MainActor
    func testSettingsPreferencesNavigationOpensDestination() {
        assertSettingsRoute(
            triggerID: "settings.link.preferences",
            destinationTitle: "Apariencia y región"
        )
    }

    @MainActor
    func testSettingsNotificationsNavigationOpensDestination() {
        assertSettingsRoute(
            triggerID: "settings.link.notifications",
            destinationTitle: "Notificaciones y calma"
        )
    }

    @MainActor
    func testSettingsHelpNavigationOpensDestination() {
        assertSettingsRoute(
            triggerID: "settings.link.help",
            destinationTitle: "Centro de ayuda"
        )
    }

    @MainActor
    func testSettingsSupportNavigationOpensDestination() {
        assertSettingsRoute(
            triggerID: "settings.link.support",
            destinationTitle: "Centro de soporte"
        )
    }

    @MainActor
    func testSettingsLegalNavigationOpensDestination() {
        assertSettingsRoute(
            triggerID: "settings.link.legal",
            destinationTitle: "Centro legal"
        )
    }

    @MainActor
    func testSettingsAdvancedNavigationOpensDestination() {
        assertSettingsRoute(
            triggerID: "settings.link.advanced",
            destinationTitle: "Avanzado",
            maxSwipes: 2
        )
    }

    @MainActor
    func testSettingsBudgetWizardOpensSheet() {
        let app = makeApp(startingTab: "settings")
        app.launch()

        let button = app.buttons["settings.action.budgetWizard"].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 8))

        button.tap()

        XCTAssertTrue(app.buttons["Cerrar"].firstMatch.waitForExistence(timeout: 8))
    }

    @MainActor
    func testInsightsTrendNavigationOpensDestination() {
        let app = makeApp(startingTab: "insights")
        app.launch()

        let trendLink = app.buttons["insights.link.trend"].firstMatch
        XCTAssertTrue(trendLink.waitForExistence(timeout: 10))

        trendLink.tap()

        assertNavigationTitle("Tendencia", in: app)
    }

    @MainActor
    func testInsightsChartTapShowsSelectionState() {
        let app = makeApp(startingTab: "insights")
        app.launch()

        let chart = app.otherElements["insights.mainChart"].firstMatch
        XCTAssertTrue(chart.waitForExistence(timeout: 10))

        let selectedText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] %@", "seleccionado")
        ).firstMatch

        let bar = app.buttons["insights.chart.bar.3"].firstMatch
        XCTAssertTrue(bar.waitForExistence(timeout: 5))
        bar.tap()

        XCTAssertTrue(selectedText.waitForExistence(timeout: 2), "Expected the chart to expose a selected point after tapping a bar.")
    }

    @MainActor
    func testExpensesAddExpenseCTAOpensSheet() {
        let app = makeApp(startingTab: "expenses")
        app.launch()

        let button = app.buttons["expenses.action.add"].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 8))

        button.tap()

        XCTAssertTrue(element("addExpense.presented", in: app).waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["addExpense.action.cancel"].firstMatch.waitForExistence(timeout: 5))
    }

    @MainActor
    func testExpensesScanCTAOpensScanFlow() {
        let app = makeApp(startingTab: "expenses")
        app.launch()

        let button = app.buttons["expenses.action.scan"].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 8))

        button.tap()

        XCTAssertTrue(app.buttons["Guía"].firstMatch.waitForExistence(timeout: 8))
    }

    @MainActor
    func testExpensesToolsAccountsNavigationOpensDestination() {
        assertExpensesToolRoute(
            triggerID: "expenses.tool.accounts",
            destinationTitle: "Accounts"
        )
    }

    @MainActor
    func testExpensesToolsBillsNavigationOpensDestination() {
        assertExpensesToolRoute(
            triggerID: "expenses.tool.bills",
            destinationTitle: "Bills"
        )
    }

    @MainActor
    func testExpensesToolsRulesNavigationOpensDestination() {
        assertExpensesToolRoute(
            triggerID: "expenses.tool.rules",
            destinationTitle: "Reglas"
        )
    }

    @MainActor
    func testExpensesToolsCsvNavigationOpensDestination() {
        assertExpensesToolRoute(
            triggerID: "expenses.tool.csv",
            destinationTitle: "CSV Import"
        )
    }

    @MainActor
    func testExpensesBudgetWizardOpensSheet() {
        let app = makeApp(startingTab: "expenses")
        app.launch()

        let button = element("expenses.action.budgetWizard", in: app)
        XCTAssertTrue(button.waitForExistence(timeout: 8))
        reveal(button, in: app, maxSwipes: 2)

        button.tap()

        XCTAssertTrue(app.buttons["Cerrar"].firstMatch.waitForExistence(timeout: 8))
    }

    @MainActor
    func testCelebrationOverlayShowsShareOption() {
        let app = makeApp(startingTab: "dashboard")
        app.launchEnvironment["SPENDSAGE_DEBUG_CELEBRATION"] = "trophy"
        app.launch()

        let shareButton = app.buttons["celebration.action.share"].firstMatch
        XCTAssertTrue(shareButton.waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["celebration.share.hint"].firstMatch.waitForExistence(timeout: 5))
        shareButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        XCTAssertTrue(element("celebration.share.presented", in: app).waitForExistence(timeout: 5))

        let closeButton = app.buttons["celebration.action.close"].firstMatch
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
    }

    @MainActor
    private func assertSettingsRoute(triggerID: String, destinationTitle: String, maxSwipes: Int = 0) {
        let app = makeApp(startingTab: "settings")
        app.launch()

        let trigger = app.buttons[triggerID].firstMatch
        XCTAssertTrue(trigger.waitForExistence(timeout: 8))
        reveal(trigger, in: app, maxSwipes: maxSwipes)

        trigger.tap()

        assertNavigationTitle(destinationTitle, in: app)
    }

    @MainActor
    private func assertExpensesToolRoute(triggerID: String, destinationTitle: String) {
        let app = makeApp(startingTab: "expenses")
        app.launch()

        let trigger = element(triggerID, in: app)
        XCTAssertTrue(trigger.waitForExistence(timeout: 8))
        reveal(trigger, in: app, maxSwipes: 2)

        trigger.tap()

        assertNavigationTitle(destinationTitle, in: app)
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
        guard maxSwipes > 0 else { return }

        for _ in 0..<maxSwipes where !element.isHittable {
            app.swipeUp()
        }
    }

    @MainActor
    private func assertNavigationTitle(_ title: String, in app: XCUIApplication, timeout: TimeInterval = 8) {
        XCTAssertTrue(app.navigationBars[title].firstMatch.waitForExistence(timeout: timeout))
    }

    @MainActor
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    @MainActor
    private func makeApp(startingTab: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDSAGE_DEBUG_SCREEN"] = "shell"
        app.launchEnvironment["SPENDSAGE_DEBUG_TAB"] = startingTab
        app.launchEnvironment["SPENDSAGE_DEBUG_SKIP_SPLASH"] = "1"
        app.launchEnvironment["SPENDSAGE_DEBUG_EXPAND_EXPENSES_TOOLS"] = "1"
        return app
    }
}
