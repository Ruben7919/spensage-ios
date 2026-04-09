import XCTest

final class SpendSageUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testShellTabsNavigateAcrossPrimarySections() {
        let app = makeApp(startingTab: "dashboard")
        app.launch()

        assertElement("dashboard.screen", in: app)
        XCTAssertTrue(app.buttons["dashboard.action.budgetWizard"].firstMatch.waitForExistence(timeout: 8))

        tap(app.buttons["shell.tab.expenses"].firstMatch, in: app)
        assertElement("expenses.screen", in: app)
        XCTAssertTrue(app.buttons["expenses.action.add"].firstMatch.waitForExistence(timeout: 8))

        tap(app.buttons["shell.tab.insights"].firstMatch, in: app)
        assertElement("insights.screen", in: app)
        XCTAssertTrue(app.buttons["insights.link.trend"].firstMatch.waitForExistence(timeout: 8))

        tap(app.buttons["shell.tab.settings"].firstMatch, in: app)
        assertElement("settings.screen", in: app)
        XCTAssertTrue(app.buttons["settings.link.profile"].firstMatch.waitForExistence(timeout: 8))

        tap(app.buttons["shell.tab.dashboard"].firstMatch, in: app)
        assertElement("dashboard.screen", in: app)
        XCTAssertTrue(app.buttons["dashboard.action.budgetWizard"].firstMatch.waitForExistence(timeout: 8))

        tap(app.buttons["shell.tab.scan"].firstMatch, in: app)
        assertElement("scan.screen", in: app)
        XCTAssertTrue(app.buttons["scan.action.importPhoto"].firstMatch.waitForExistence(timeout: 8))
    }

    @MainActor
    func testSettingsProfileNavigationOpensDestination() {
        assertSettingsRoute(
            triggerID: "settings.link.profile",
            destinationElementID: "profile.screen"
        )
    }

    @MainActor
    func testSettingsPreferencesNavigationOpensDestination() {
        assertSettingsRoute(
            triggerID: "settings.link.preferences",
            destinationElementID: "settingsPreferences.screen"
        )
    }

    @MainActor
    func testSettingsNotificationsNavigationOpensDestination() {
        assertSettingsRoute(
            triggerID: "settings.link.notifications",
            destinationElementID: "settingsNotifications.screen"
        )
    }

    @MainActor
    func testSettingsHelpNavigationOpensDestination() {
        assertSettingsRoute(
            triggerID: "settings.link.help",
            destinationElementID: "help.screen"
        )
    }

    @MainActor
    func testSettingsSupportNavigationOpensDestination() {
        assertSettingsRoute(
            triggerID: "settings.link.support",
            destinationElementID: "support.screen"
        )
    }

    @MainActor
    func testSettingsLegalNavigationOpensDestination() {
        assertSettingsRoute(
            triggerID: "settings.link.legal",
            destinationElementID: "legal.screen",
            maxSwipes: 2
        )
    }

    @MainActor
    func testSettingsAdvancedNavigationOpensDestination() {
        assertSettingsRoute(
            triggerID: "settings.link.advanced",
            destinationElementID: "advanced.screen",
            maxSwipes: 3
        )
    }

    @MainActor
    func testSettingsBudgetWizardOpensSheet() {
        let app = makeApp(startingTab: "settings")
        app.launch()

        let button = app.buttons["settings.action.budgetWizard"].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 8))

        tap(button, in: app)

        XCTAssertTrue(app.buttons["budget.action.close"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["budget.action.guide"].firstMatch.waitForExistence(timeout: 5))
    }

    @MainActor
    func testInsightsTrendNavigationOpensDestination() {
        let app = makeApp(startingTab: "insights")
        app.launch()

        let trendLink = app.buttons["insights.link.trend"].firstMatch
        XCTAssertTrue(trendLink.waitForExistence(timeout: 10))

        tap(trendLink, in: app)

        assertElement("insightsTrend.screen", in: app)
    }

    @MainActor
    func testInsightsChartTapShowsSelectionState() {
        let app = makeApp(startingTab: "insights")
        app.launchEnvironment["SPENDSAGE_DEBUG_INSIGHTS_SELECTION"] = "3"
        app.launch()

        let chart = app.otherElements["insights.mainChart"].firstMatch
        XCTAssertTrue(chart.waitForExistence(timeout: 10))

        let selectionSummary = element("insights.chart.selection", in: app)
        XCTAssertTrue(selectionSummary.waitForExistence(timeout: 2), "Expected the chart to expose a selected point after tapping a bar.")
    }

    @MainActor
    func testExpensesAddExpenseCTAOpensSheet() {
        let app = makeApp(startingTab: "expenses")
        app.launch()

        let button = app.buttons["expenses.action.add"].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 8))

        tap(button, in: app)

        XCTAssertTrue(app.buttons["addExpense.action.cancel"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["addExpense.action.save"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["addExpense.action.cancel"].firstMatch.waitForExistence(timeout: 5))
    }

    @MainActor
    func testExpensesScanCTAOpensScanFlow() {
        let app = makeApp(startingTab: "expenses")
        app.launch()

        let button = app.buttons["expenses.action.scan"].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 8))

        tap(button, in: app)

        XCTAssertTrue(app.buttons["scan.action.importPhoto"].firstMatch.waitForExistence(timeout: 8))
    }

    @MainActor
    func testExpensesToolsAccountsNavigationOpensDestination() {
        assertExpensesToolRoute(
            triggerID: "expenses.tool.accounts",
            destinationElementID: "accounts.screen"
        )
    }

    @MainActor
    func testExpensesToolsBillsNavigationOpensDestination() {
        assertExpensesToolRoute(
            triggerID: "expenses.tool.bills",
            destinationElementID: "bills.screen"
        )
    }

    @MainActor
    func testExpensesToolsRulesNavigationOpensDestination() {
        assertExpensesToolRoute(
            triggerID: "expenses.tool.rules",
            destinationElementID: "rules.screen"
        )
    }

    @MainActor
    func testExpensesToolsCsvNavigationOpensDestination() {
        assertExpensesToolRoute(
            triggerID: "expenses.tool.csv",
            destinationElementID: "csvImport.action.import"
        )
    }

    @MainActor
    func testExpensesBudgetWizardOpensSheet() {
        let app = makeApp(startingTab: "expenses")
        app.launch()

        prepareExpensesTools(in: app, targetID: "expenses.action.budgetWizard")

        let button = element("expenses.action.budgetWizard", in: app)
        XCTAssertTrue(button.waitForExistence(timeout: 8))
        reveal(button, in: app, maxSwipes: 4)

        tap(button, in: app)

        XCTAssertTrue(app.buttons["budget.action.close"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["budget.action.guide"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["budget.action.close"].firstMatch.waitForExistence(timeout: 8))
    }

    @MainActor
    func testCelebrationOverlayShowsShareOption() {
        let app = makeApp(startingTab: "dashboard")
        app.launchEnvironment["SPENDSAGE_DEBUG_CELEBRATION"] = "trophy"
        app.launch()

        let shareButton = app.buttons["celebration.action.share"].firstMatch
        XCTAssertTrue(shareButton.waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["celebration.share.hint"].firstMatch.waitForExistence(timeout: 5))
        tap(shareButton, postPause: 0.8)

        XCTAssertTrue(element("celebration.share.presented", in: app).waitForExistence(timeout: 5))

        let closeButton = app.buttons["celebration.action.close"].firstMatch
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
    }

    @MainActor
    func testTrophyHistoryShowsMissionTracksAndEventCalendar() {
        let app = makeApp(startingTab: "dashboard")
        app.launch()

        let trigger = app.otherElements["dashboard.link.trophies"].firstMatch
        XCTAssertTrue(trigger.waitForExistence(timeout: 8))
        reveal(trigger, in: app, maxSwipes: 4)
        tap(trigger, in: app)

        assertElement("trophies.screen", in: app)
        XCTAssertTrue(app.staticTexts["Local"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Cloud"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Especiales"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Calendario de eventos"].firstMatch.waitForExistence(timeout: 5))
    }

    @MainActor
    private func assertSettingsRoute(
        triggerID: String,
        destinationTitle: String? = nil,
        destinationElementID: String? = nil,
        maxSwipes: Int = 0
    ) {
        let app = makeApp(startingTab: "settings")
        app.launch()

        let trigger = app.buttons[triggerID].firstMatch
        XCTAssertTrue(trigger.waitForExistence(timeout: 8))
        reveal(trigger, in: app, maxSwipes: maxSwipes)

        tap(trigger, in: app)

        if let destinationTitle {
            assertNavigationTitle(destinationTitle, in: app)
        }

        if let destinationElementID {
            assertElement(destinationElementID, in: app)
        }
    }

    @MainActor
    private func assertExpensesToolRoute(triggerID: String, destinationElementID: String) {
        let app = makeApp(startingTab: "expenses")
        app.launch()

        prepareExpensesTools(in: app, targetID: triggerID)

        let trigger = element(triggerID, in: app)
        XCTAssertTrue(trigger.waitForExistence(timeout: 8))
        reveal(trigger, in: app, maxSwipes: 4)

        tap(trigger, in: app)

        assertElement(destinationElementID, in: app)
    }

    @MainActor
    private func prepareExpensesTools(in app: XCUIApplication, targetID: String) {
        let disclosure = app.buttons["expenses.disclosure.tools"].firstMatch
        XCTAssertTrue(disclosure.waitForExistence(timeout: 8))
        reveal(disclosure, in: app, maxSwipes: 5)

        let target = element(targetID, in: app)
        if target.exists { return }

        tap(disclosure, in: app, postPause: 0.9)

        if !target.exists {
            reveal(disclosure, in: app, maxSwipes: 2)
            tap(disclosure, in: app, postPause: 0.9)
        }
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
        guard maxSwipes > 0 else { return }
        let viewport = app.windows.firstMatch.frame

        for _ in 0..<maxSwipes where !element.isHittable {
            let frame = element.frame
            if !frame.isEmpty {
                if frame.maxY > viewport.maxY - 140 {
                    app.swipeUp()
                } else if frame.minY < viewport.minY + 140 {
                    app.swipeDown()
                } else {
                    usleep(250_000)
                }
            } else {
                app.swipeUp()
            }
            usleep(300_000)
        }
    }

    @MainActor
    private func tap(_ element: XCUIElement, in app: XCUIApplication? = nil, timeout: TimeInterval = 8, postPause: Double = 0.7) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        if let app {
            reveal(element, in: app, maxSwipes: 4)
        }
        XCTAssertTrue(waitUntilHittable(element, timeout: 4))
        element.tap()
        usleep(useconds_t(postPause * 1_000_000))
    }

    @MainActor
    private func waitUntilHittable(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.isHittable {
                return true
            }
            usleep(200_000)
        }
        return element.isHittable
    }

    @MainActor
    private func assertNavigationTitle(_ title: String, in app: XCUIApplication, timeout: TimeInterval = 8) {
        XCTAssertTrue(app.navigationBars[title].firstMatch.waitForExistence(timeout: timeout))
    }

    @MainActor
    private func assertElement(_ identifier: String, in app: XCUIApplication, timeout: TimeInterval = 8) {
        XCTAssertTrue(element(identifier, in: app).waitForExistence(timeout: timeout))
    }

    @MainActor
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    @MainActor
    private func makeApp(startingTab: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDSAGE_DEBUG_SCREEN"] = "shell"
        app.launchEnvironment["SPENDSAGE_DEBUG_TAB"] = startingTab
        app.launchEnvironment["SPENDSAGE_DEBUG_SKIP_SPLASH"] = "1"
        app.launchEnvironment["SPENDSAGE_DEBUG_HIDE_GUIDES"] = "1"
        app.launchEnvironment["SPENDSAGE_DEBUG_EXPAND_EXPENSES_TOOLS"] = "1"
        app.launchEnvironment["SPENDSAGE_DEBUG_DISABLE_PERMISSION_BOOTSTRAP"] = "1"
        app.launchEnvironment["SPENDSAGE_DEBUG_DISABLE_AUTO_CAMERA"] = "1"
        app.launchEnvironment["SPENDSAGE_DEBUG_DISABLE_SHARE_SHEET"] = "1"
        return app
    }
}
