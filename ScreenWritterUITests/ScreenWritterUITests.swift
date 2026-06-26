import XCTest

final class ScreenWritterUITests: XCTestCase {
    func testLaunchShowsEmptyState() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["ScreenWritter"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Sin sesiones"].exists || app.staticTexts["Nada importado"].exists)
    }

    func testWorkspaceShowsFloatingModePickerAfterAddingWebSession() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["ScreenWritter"].waitForExistence(timeout: 5))
        app.buttons["Web"].tap()

        let urlField = app.textFields["URL"]
        XCTAssertTrue(urlField.waitForExistence(timeout: 5))
        urlField.tap()
        urlField.typeText("example.com")

        app.buttons["Abrir"].tap()

        let modePicker = app.segmentedControls["modePicker"]
        XCTAssertTrue(modePicker.waitForExistence(timeout: 5))

        let clearButton = app.buttons["clearAnnotationsButton"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 5))
    }
}
