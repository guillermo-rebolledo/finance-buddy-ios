import AppIntents
import XCTest

final class FinanceBuddyUITests: XCTestCase {
  @MainActor func testShell() {
    let app = XCUIApplication()
    app.launchArguments = ["-useFakeAPI"]
    app.launch()
    XCTAssertTrue(app.tabBars.buttons["Entries"].waitForExistence(timeout: 10))
  }

  @MainActor func testAddEditDeleteEntryAndPeriods() {
    let app = XCUIApplication()
    app.launchArguments = ["-useFakeAPI"]
    app.launch()
    let add = app.buttons["addEntry"]
    XCTAssertTrue(add.waitForExistence(timeout: 10))
    add.tap()
    let amount = app.textFields["entryAmount"]
    XCTAssertTrue(amount.waitForExistence(timeout: 5))
    amount.tap()
    amount.typeText("42.50")
    app.buttons["saveEntry"].tap()
    XCTAssertTrue(app.staticTexts["Entry saved."].waitForExistence(timeout: 5))
    let row = app.buttons.containing(.staticText, identifier: "MXN 42.50").firstMatch
    XCTAssertTrue(row.waitForExistence(timeout: 5))
    row.tap()
    XCTAssertTrue(amount.waitForExistence(timeout: 5))
    amount.tap()
    amount.press(forDuration: 1.2)
    if app.menuItems["Select All"].waitForExistence(timeout: 2) {
      app.menuItems["Select All"].tap()
      amount.typeText("51.25")
    } else {
      amount.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 5) + "51.25")
    }
    app.buttons["saveEntry"].tap()
    let edited = app.buttons.containing(.staticText, identifier: "MXN 51.25").firstMatch
    XCTAssertTrue(edited.waitForExistence(timeout: 5))
    edited.swipeLeft()
    app.buttons["Delete"].firstMatch.tap()
    XCTAssertTrue(app.buttons["Delete Permanently"].waitForExistence(timeout: 5))
    app.buttons["Delete Permanently"].tap()
    XCTAssertTrue(app.staticTexts["Entry deleted."].waitForExistence(timeout: 5))
    app.buttons["Previous period"].tap()
    XCTAssertTrue(app.buttons["Today"].waitForExistence(timeout: 5))
    app.buttons["Today"].tap()
    XCTAssertTrue(app.staticTexts["This week"].waitForExistence(timeout: 5))
  }

  @MainActor func testCategoryLifecycleAndSignOut() {
    let app = XCUIApplication()
    app.launchArguments = ["-useFakeAPI"]
    app.launch()
    XCTAssertTrue(app.tabBars.buttons["Categories"].waitForExistence(timeout: 10))
    app.tabBars.buttons["Categories"].tap()
    let add = app.buttons["add-income-category"]
    XCTAssertTrue(add.waitForExistence(timeout: 5))
    add.tap()
    let name = app.textFields["categoryName"]
    XCTAssertTrue(name.waitForExistence(timeout: 5))
    name.tap()
    name.typeText("Gifts")
    app.buttons["saveCategory"].tap()
    XCTAssertTrue(app.staticTexts["Category added."].waitForExistence(timeout: 5))
    let actions = app.buttons["Actions for Gifts"]
    XCTAssertTrue(actions.waitForExistence(timeout: 5))
    actions.tap()
    app.buttons["Archive"].tap()
    XCTAssertTrue(
      app.staticTexts["Category archived. Existing entries and totals keep it."].waitForExistence(
        timeout: 5))
    app.tabBars.buttons["Settings"].tap()
    app.buttons["Sign Out"].tap()
    XCTAssertTrue(app.buttons["Continue with Google"].waitForExistence(timeout: 5))
  }

  @MainActor func testCategorySwipeActions() {
    let app = XCUIApplication()
    app.launchArguments = ["-useFakeAPI"]
    app.launch()
    XCTAssertTrue(app.tabBars.buttons["Categories"].waitForExistence(timeout: 10))
    app.tabBars.buttons["Categories"].tap()
    let actions = app.buttons["Actions for Salary"]
    XCTAssertTrue(actions.waitForExistence(timeout: 5))
    XCTAssertFalse(app.staticTexts["Actions for Salary"].exists)
    app.cells.containing(.staticText, identifier: "Salary").firstMatch.swipeRight()
    let name = app.textFields["categoryName"]
    if app.buttons["Rename"].exists { app.buttons["Rename"].tap() }
    XCTAssertTrue(name.waitForExistence(timeout: 5))
    name.tap()
    name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 6) + "Wages")
    app.buttons["saveCategory"].tap()
    XCTAssertTrue(app.staticTexts["Category renamed."].waitForExistence(timeout: 5))
    app.cells.containing(.staticText, identifier: "Wages").firstMatch.swipeLeft()
    if app.buttons["Archive"].exists { app.buttons["Archive"].tap() }
    XCTAssertTrue(
      app.staticTexts["Category archived. Existing entries and totals keep it."].waitForExistence(
        timeout: 5))
  }

  @MainActor func testCategoryToasts() {
    let app = XCUIApplication()
    app.launchArguments = ["-useFakeAPI", "-dark"]
    app.launch()
    XCTAssertTrue(app.tabBars.buttons["Categories"].waitForExistence(timeout: 10))
    app.tabBars.buttons["Categories"].tap()
    app.buttons["add-income-category"].tap()
    app.buttons["saveCategory"].tap()
    let error = "Enter a name of 1 to 40 characters, without line breaks or control characters."
    XCTAssertTrue(app.staticTexts[error].waitForExistence(timeout: 5))
    XCTAssertEqual(app.cells.containing(.staticText, identifier: error).count, 0)
    app.buttons["Dismiss notification"].tap()
    XCTAssertFalse(app.staticTexts[error].exists)
    app.buttons["saveCategory"].tap()
    XCTAssertTrue(app.staticTexts[error].waitForExistence(timeout: 5))
    let failure = XCTAttachment(screenshot: app.screenshot())
    failure.name = "Category validation toast"
    failure.lifetime = .keepAlways
    add(failure)
    let name = app.textFields["categoryName"]
    name.tap()
    name.typeText("Gifts")
    app.buttons["saveCategory"].tap()
    let success = app.staticTexts["Category added."]
    XCTAssertTrue(success.waitForExistence(timeout: 5))
    XCTAssertEqual(app.cells.containing(.staticText, identifier: "Category added.").count, 0)
    let confirmation = XCTAttachment(screenshot: app.screenshot())
    confirmation.name = "Category success toast"
    confirmation.lifetime = .keepAlways
    add(confirmation)
    let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: success)
    XCTAssertEqual(XCTWaiter.wait(for: [gone], timeout: 8), .completed)
    XCTAssertTrue(app.buttons["Actions for Gifts"].exists)
  }

  @MainActor func testAccessibilityAndDashboardTables() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-useFakeAPI", "-light"]
    app.launch()
    XCTAssertTrue(app.buttons["addEntry"].waitForExistence(timeout: 10))
    try app.performAccessibilityAudit(for: [
      .dynamicType, .textClipped, .sufficientElementDescription, .hitRegion,
    ])
    app.tabBars.buttons["Dashboard"].tap()
    let table = app.buttons["Show Income and expenses as table"]
    for _ in 0..<8 {
      if table.isHittable { break }
      app.swipeUp()
    }
    XCTAssertTrue(table.isHittable)
    let chartImage = XCTAttachment(screenshot: app.screenshot())
    chartImage.name = "Dashboard charts – light"
    chartImage.lifetime = .keepAlways
    add(chartImage)
    table.tap()
    XCTAssertTrue(app.staticTexts["2026-06-29 – 2026-07-05"].waitForExistence(timeout: 5))
  }
  @MainActor func testLargestTypeScreens() {
    let app = XCUIApplication()
    app.launchArguments = ["-useFakeAPI", "-largestType", "-dark"]
    app.launch()
    XCTAssertTrue(app.buttons["addEntry"].waitForExistence(timeout: 10))
    for name in ["Entries", "Dashboard", "Categories", "Settings"] {
      app.tabBars.buttons[name].tap()
      let attachment = XCTAttachment(screenshot: app.screenshot())
      attachment.name = name + " – largest accessibility size, dark"
      attachment.lifetime = .keepAlways
      add(attachment)
      XCTAssertTrue(app.navigationBars[name].exists)
    }
  }
}
