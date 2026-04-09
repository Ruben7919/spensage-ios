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

        tap(app.buttons["onboarding.action.continueToGoal"].firstMatch, in: app)
        type("1500", into: app.textFields["onboarding.field.goalTarget"].firstMatch)

        tap(app.buttons["onboarding.action.showPreview"].firstMatch, in: app)
        pause(1.8)

        tap(app.buttons["onboarding.action.getStarted"].firstMatch, in: app)
        pause(1.4)
    }

    @MainActor
    func testTutorial02DashboardAndAddExpense() {
        let app = makeApp(startingTab: "dashboard")
        app.launch()

        XCTAssertTrue(element("dashboard.screen", in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["dashboard.action.budgetWizard"].firstMatch.waitForExistence(timeout: 10))
        pause(1.2)

        tap(app.buttons["shell.tab.expenses"].firstMatch, in: app)
        XCTAssertTrue(element("expenses.screen", in: app).waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["expenses.action.add"].firstMatch.waitForExistence(timeout: 8))
        pause(0.8)

        tap(app.buttons["expenses.action.add"].firstMatch, in: app)
        XCTAssertTrue(app.buttons["addExpense.action.save"].firstMatch.waitForExistence(timeout: 8))
        pause(0.8)

        type("Supermaxi", into: app.textFields["addExpense.field.merchant"].firstMatch)
        type("42.80", into: app.textFields["addExpense.field.amount"].firstMatch)
        pause(0.6)

        tap(app.buttons["addExpense.action.save"].firstMatch, in: app)
        XCTAssertTrue(element("expenses.screen", in: app).waitForExistence(timeout: 8))
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

        XCTAssertTrue(element("insights.screen", in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["insights.link.trend"].firstMatch.waitForExistence(timeout: 10))
        pause(1.0)

        tap(app.buttons["insights.chart.bar.3"].firstMatch, in: app)
        pause(0.8)

        tap(app.buttons["insights.link.trend"].firstMatch, in: app)
        XCTAssertTrue(element("insightsTrend.screen", in: app).waitForExistence(timeout: 8))
        pause(1.0)
        back(app)

        tap(app.buttons["shell.tab.dashboard"].firstMatch, in: app)
        XCTAssertTrue(element("dashboard.screen", in: app).waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["dashboard.action.budgetWizard"].firstMatch.waitForExistence(timeout: 8))
        pause(0.8)

        tap(app.buttons["dashboard.action.budgetWizard"].firstMatch, in: app)
        XCTAssertTrue(element("budget.screen", in: app).waitForExistence(timeout: 8))
        pause(0.8)

        type("4200", into: app.textFields["budget.field.income"].firstMatch)
        tap(app.buttons["budget.action.next"].firstMatch, in: app)
        type("2800", into: app.textFields["budget.field.target"].firstMatch)
        tap(app.buttons["budget.action.next"].firstMatch, in: app)
        pause(1.0)
        tap(app.buttons["budget.action.save"].firstMatch, in: app)

        XCTAssertTrue(element("dashboard.screen", in: app).waitForExistence(timeout: 8))
        pause(1.4)
    }

    @MainActor
    func testTutorial05AccountsBillsAndRules() {
        let scenes: [(route: String, destinationID: String)] = [
            ("accounts", "accounts.screen"),
            ("bills", "bills.screen"),
            ("rules", "rules.screen")
        ]

        for (index, scene) in scenes.enumerated() {
            let app = makeApp(route: scene.route)
            app.launch()

            XCTAssertTrue(element(scene.destinationID, in: app).waitForExistence(timeout: 10))
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

        tap(app.buttons["settings.link.profile"].firstMatch, in: app)
        XCTAssertTrue(element("profile.screen", in: app).waitForExistence(timeout: 8))
        pause(0.9)
        back(app)

        tap(app.buttons["settings.link.help"].firstMatch, in: app)
        XCTAssertTrue(element("help.screen", in: app).waitForExistence(timeout: 8))
        pause(0.9)
        back(app)

        tap(app.buttons["settings.link.support"].firstMatch, in: app)
        XCTAssertTrue(element("support.screen", in: app).waitForExistence(timeout: 8))
        pause(0.9)
        back(app)
        pause(0.6)

        let legalButton = app.buttons["settings.link.legal"].firstMatch
        XCTAssertTrue(legalButton.waitForExistence(timeout: 8))
        reveal(legalButton, in: app, maxSwipes: 3)
        tap(legalButton, in: app, postPause: 1.0)
        XCTAssertTrue(element("legal.screen", in: app).waitForExistence(timeout: 8))
        pause(0.9)
        back(app)

        let plansButton = app.buttons["settings.link.plans"].firstMatch
        XCTAssertTrue(plansButton.waitForExistence(timeout: 8))
        reveal(plansButton, in: app, maxSwipes: 3)
        tap(plansButton, in: app)
        XCTAssertTrue(element("premium.screen", in: app).waitForExistence(timeout: 8))
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
    private func tap(_ element: XCUIElement, in app: XCUIApplication? = nil, timeout: TimeInterval = 8, postPause: Double = 0.7) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        if let app {
            reveal(element, in: app, maxSwipes: 4)
        }
        XCTAssertTrue(waitUntilHittable(element, timeout: 4))
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
        let viewport = app.windows.firstMatch.frame

        for _ in 0..<maxSwipes where !element.isHittable {
            let frame = element.frame
            if !frame.isEmpty {
                if frame.maxY > viewport.maxY - 140 {
                    app.swipeUp()
                } else if frame.minY < viewport.minY + 140 {
                    app.swipeDown()
                } else {
                    pause(0.25)
                }
            } else {
                app.swipeUp()
            }
            pause(0.5)
        }
    }

    @MainActor
    private func waitUntilHittable(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.isHittable {
                return true
            }
            pause(0.2)
        }
        return element.isHittable
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
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func pause(_ seconds: Double) {
        usleep(useconds_t(seconds * 1_000_000))
    }
}
