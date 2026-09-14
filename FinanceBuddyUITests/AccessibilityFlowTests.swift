import XCTest

final class AccessibilityFlowTests: XCTestCase {
  @MainActor func testAdditionalScreensAtLargestTextSize() throws {
    let app = XCUIApplication()
    for screen in [
      "editor", "categoryEditor", "deletion", "export", "unavailable", "upgrade", "signIn",
    ] {
      app.launchArguments = ["-useFakeAPI", "-largestType", "-dark", "-previewScreen", screen]
      app.launch()
      try audit(app, screen)
      if app.scrollViews.firstMatch.exists || app.collectionViews.firstMatch.exists {
        app.swipeUp()
        try audit(app, screen + " scrolled")
      }
    }
  }

  @MainActor func testLightAccessibilityFlow() throws {
    try auditFlow(arguments: ["-light"])
  }

  @MainActor func testLargestTextAccessibilityFlow() throws {
    try auditFlow(arguments: ["-largestType", "-dark"])
  }

  @MainActor private func auditFlow(arguments: [String]) throws {
    let app = XCUIApplication()
    app.launchArguments = ["-useFakeAPI"] + arguments
    app.launch()
    XCTAssertTrue(app.buttons["addEntry"].waitForExistence(timeout: 10))
    try audit(app, "Entries")
    app.buttons["addEntry"].tap()
    XCTAssertTrue(app.textFields["entryAmount"].waitForExistence(timeout: 5))
    try audit(app, "Entry editor top")
    app.swipeUp()
    try audit(app, "Entry editor bottom")
    app.buttons["Cancel"].tap()

    app.tabBars.buttons["Categories"].tap()
    try audit(app, "Categories")
    let add = app.buttons["add-income-category"]
    if !add.isHittable { app.swipeUp() }
    add.tap()
    XCTAssertTrue(app.textFields["categoryName"].waitForExistence(timeout: 5))
    try audit(app, "Category editor")
    app.buttons["Cancel"].tap()

    app.tabBars.buttons["Settings"].tap()
    try audit(app, "Settings top")
    app.swipeUp()
    try audit(app, "Settings bottom")
    app.swipeDown()
    app.buttons["Sign Out"].tap()
    XCTAssertTrue(app.buttons["Continue with Google"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["appleSignIn"].exists)
    try audit(app, "Sign in")
  }

  @MainActor private func audit(_ app: XCUIApplication, _ name: String) throws {
    let image = XCTAttachment(screenshot: app.screenshot())
    image.name = name
    image.lifetime = .keepAlways
    add(image)
    // Audit readable labels and reachable controls at each captured size.
    // Font scaling is exercised by testAccessibilityAndDashboardTables and
    // the separate AX5 fixtures, including sheet content.
    try app.performAccessibilityAudit(for: [
      .textClipped, .sufficientElementDescription, .hitRegion,
    ])
  }
}
