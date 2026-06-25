import XCTest

final class ScreenWritterUITests: XCTestCase {
    func testLaunchShowsEmptyState() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["ScreenWritter"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Sin sesiones"].exists || app.staticTexts["Nada importado"].exists)
    }
}
