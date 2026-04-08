import XCTest

final class SpendSageTutorialUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTutorial01OnboardingFirstWin() {
        let app = makeApp(screen: "onboarding")
        app.launch()

        XCTAssertTrue(app.buttons["onboarding.action.continueToGoal"].firstMatch.waitForExistence(timeout: 10))
        pause(1.0)

        type("3200", into: app.textFields["onboarding.field.monthlyIncome"].firstMatch)
        type("1250", into: app.textFields["onboarding.field.fixedBills"].firstMatch)
        type("840", into: app.textFields["onboarding.field.currentBalance"].firstMatch)

        tap(app.buttons["onboarding.action.continueToGoal"].firstMatch)
        type("1500", into: app.textFields["onboarding.field.goalTarget"].firstMatch)

        tap(app.buttons["onboarding.action.showPreview"].firstMatch)
        pause(1.8)

        tap(app.buttons["onboarding.action.getStarted"].firstMatch)
        pause(1.4)
    }

    @MainActor
    func testTutorial02DashboardAndAddExpense() {
        let app = makeApp(startingTab: "dashboard")
        app.launch()

        XCTAssertTrue(app.navigationBars["Inicio"].firstMatch.waitForExistence(timeout: 10))
        pause(1.2)

        tap(app.buttons["shell.tab.expenses"].firstMatch)
        XCTAssertTrue(app.navigationBars["Gastos"].firstMatch.waitForExistence(timeout: 8))
        pause(0.8)

        tap(app.buttons["expenses.action.add"].firstMatch)
        XCTAssertTrue(app.buttons["addExpense.action.save"].firstMatch.waitForExistence(timeout: 8))
        pause(0.8)

        type("Supermaxi", into: app.textFields["addExpense.field.merchant"].firstMatch)
        type("42.80", into: app.textFields["addExpense.field.amount"].firstMatch)
        pause(0.6)

        tap(app.buttons["addExpense.action.save"].firstMatch)
        XCTAssertTrue(app.navigationBars["Gastos"].firstMatch.waitForExistence(timeout: 8))
        pause(1.4)
    }

    @MainActor
    func testTutorial03ScanReceiptReviewAndSave() {
        let app = makeApp(route: "scan")
        app.launchEnvironment["SPENDSAGE_DEBUG_SCAN_STATE"] = "review"
        app.launch()

        XCTAssertTrue(app.buttons["scan.action.backToAutofill"].firstMatch.waitForExistence(timeout: 10))
        pause(1.2)

        tap(app.buttons["scan.action.backToAutofill"].firstMatch)
        pause(0.8)

        tap(app.buttons["scan.action.review"].firstMatch)
        pause(0.8)

        tap(app.buttons["scan.action.save"].firstMatch)
        XCTAssertTrue(app.buttons["scan.action.openCamera"].firstMatch.waitForExistence(timeout: 8))
        pause(1.4)
    }

    @MainActor
    func testTutorial04InsightsAndBudgetWizard() {
        let app = makeApp(startingTab: "insights")
        app.launch()

        XCTAssertTrue(app.buttons["insights.link.trend"].firstMatch.waitForExistence(timeout: 10))
        pause(1.0)

        tap(app.buttons["insights.chart.bar.3"].firstMatch)
        XCTAssertTrue(element("insights.chart.selection", in: app).waitForExistence(timeout: 4))
        pause(1.0)

        tap(app.buttons["insights.link.trend"].firstMatch)
        XCTAssertTrue(app.navigationBars["Tendencia"].firstMatch.waitForExistence(timeout: 8))
        pause(1.0)
        back(app)

        tap(app.buttons["shell.tab.dashboard"].firstMatch)
        XCTAssertTrue(app.navigationBars["Inicio"].firstMatch.waitForExistence(timeout: 8))
        pause(0.8)

        tap(app.buttons["dashboard.action.budgetWizard"].firstMatch)
        XCTAssertTrue(element("budget.screen", in: app).waitForExistence(timeout: 8))
        pause(0.8)

        type("4200", into: app.textFields["budget.field.income"].firstMatch)
        tap(app.buttons["budget.action.next"].firstMatch)
        type("2800", into: app.textFields["budget.field.target"].firstMatch)
        tap(app.buttons["budget.action.next"].firstMatch)
        pause(1.0)
        tap(app.buttons["budget.action.save"].firstMatch)

        XCTAssertTrue(app.navigationBars["Inicio"].firstMatch.waitForExistence(timeout: 8))
        pause(1.4)
    }

    @MainActor
    func testTutorial05AccountsBillsAndRules() {
        let scenes: [(route: String, title: String)] = [
            ("accounts", "Cuentas"),
            ("bills", "Facturas"),
            ("rules", "Reglas")
        ]

        for (index, scene) in scenes.enumerated() {
            let app = makeApp(route: scene.route)
            app.launch()

            XCTAssertTrue(app.navigationBars[scene.title].firstMatch.waitForExistence(timeout: 10))
            pause(0.8)
            app.swipeUp()
            pause(index == scenes.count - 1 ? 1.4 : 1.0)

            if index < scenes.count - 1 {
                app.terminate()
                pause(0.6)
            }
        }
    }

    @MainActor
    func testTutorial06SettingsHelpSupportAndPlans() {
        let app = makeApp(startingTab: "settings")
        app.launch()

        XCTAssertTrue(app.buttons["settings.link.profile"].firstMatch.waitForExistence(timeout: 10))
        pause(1.0)

        tap(app.buttons["settings.link.profile"].firstMatch)
        XCTAssertTrue(app.navigationBars["Perfil"].firstMatch.waitForExistence(timeout: 8))
        pause(0.9)
        back(app)

        tap(app.buttons["settings.link.help"].firstMatch)
        XCTAssertTrue(app.navigationBars["Centro de ayuda"].firstMatch.waitForExistence(timeout: 8))
        pause(0.9)
        back(app)

        tap(app.buttons["settings.link.support"].firstMatch)
        XCTAssertTrue(app.navigationBars["Centro de soporte"].firstMatch.waitForExistence(timeout: 8))
        pause(0.9)
        back(app)

        reveal(app.buttons["settings.link.legal"].firstMatch, in: app, maxSwipes: 1)
        tap(app.buttons["settings.link.legal"].firstMatch)
        XCTAssertTrue(element("legal.screen", in: app).waitForExistence(timeout: 8))
        pause(0.9)
        back(app)

        tap(app.buttons["settings.link.plans"].firstMatch)
        XCTAssertTrue(app.navigationBars["Planes"].firstMatch.waitForExistence(timeout: 8))
        pause(1.4)
    }

    @MainActor
    func testTutorial07CelebrationShare() {
        let app = makeApp(startingTab: "dashboard")
        app.launchEnvironment["SPENDSAGE_DEBUG_CELEBRATION"] = "trophy"
        app.launch()

        let shareButton = app.buttons["celebration.action.share"].firstMatch
        XCTAssertTrue(shareButton.waitForExistence(timeout: 8))
        pause(1.0)

        tap(shareButton, postPause: 0.8)
        XCTAssertTrue(element("celebration.share.presented", in: app).waitForExistence(timeout: 5))
        pause(1.6)
    }

    @MainActor
    private func makeApp(
        screen: String? = nil,
        startingTab: String? = nil,
        route: String? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SPENDSAGE_DEBUG_SKIP_SPLASH"] = "1"
        app.launchEnvironment["SPENDSAGE_DEBUG_HIDE_GUIDES"] = "1"
        app.launchEnvironment["SPENDSAGE_DEBUG_EXPAND_EXPENSES_TOOLS"] = "1"
        app.launchEnvironment["SPENDSAGE_DEBUG_DISABLE_PERMISSION_BOOTSTRAP"] = "1"
        app.launchEnvironment["SPENDSAGE_DEBUG_DISABLE_AUTO_CAMERA"] = "1"
        app.launchEnvironment["SPENDSAGE_DEBUG_DISABLE_SHARE_SHEET"] = "1"

        if let screen {
            app.launchEnvironment["SPENDSAGE_DEBUG_SCREEN"] = screen
        }

        if let startingTab {
            app.launchEnvironment["SPENDSAGE_DEBUG_TAB"] = startingTab
        }

        if let route {
            app.launchEnvironment["SPENDSAGE_DEBUG_ROUTE"] = route
        }

        return app
    }

    @MainActor
    private func tap(_ element: XCUIElement, timeout: TimeInterval = 8, postPause: Double = 0.7) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        element.tap()
        pause(postPause)
    }

    @MainActor
    private func type(_ text: String, into element: XCUIElement, clear: Bool = true, timeout: TimeInterval = 8, postPause: Double = 0.6) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        focus(element)

        if clear {
            let existingValue = (element.value as? String) ?? ""
            if !existingValue.isEmpty, existingValue != element.label {
                let deleteCount = min(existingValue.count, 32)
                XCUIApplication().typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: deleteCount))
            }
        }

        XCUIApplication().typeText(text)
        pause(postPause)
    }

    @MainActor
    private func focus(_ element: XCUIElement) {
        let coordinate = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))

        element.tap()
        pause(0.15)

        if !(element.value(forKey: "hasKeyboardFocus") as? Bool ?? false) {
            coordinate.tap()
            pause(0.15)
        }

        if !(element.value(forKey: "hasKeyboardFocus") as? Bool ?? false) {
            element.tap()
            pause(0.2)
        }
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
        guard maxSwipes > 0 else { return }

        for _ in 0..<maxSwipes where !element.isHittable {
            app.swipeUp()
            pause(0.5)
        }
    }

    @MainActor
    private func back(_ app: XCUIApplication, postPause: Double = 0.7) {
        let button = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 8))
        button.tap()
        pause(postPause)
    }

    @MainActor
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func pause(_ seconds: Double) {
        usleep(useconds_t(seconds * 1_000_000))
    }
}
