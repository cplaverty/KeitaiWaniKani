//
//  KeitaiWaniKaniSnapshotUITests.swift
//  KeitaiWaniKaniUITests
//
//  Copyright © 2016 Chris Laverty. All rights reserved.
//

import XCTest

class KeitaiWaniKaniSnapshotUITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }
    
    func testScreenshot() {
        let app = XCUIApplication()
        sleep(2)
        XCTAssert(app.navigationBars["Dashboard"].exists)
        
        snapshot("dashboard", waitForLoadingIndicator: true)
        let tablesQuery = app.tables

        print("Showing review timeline")
        tablesQuery.staticTexts["All Upcoming Reviews"].tap()
        sleep(2)
        print("Performing snapshot of review timeline")
        snapshot("review-timeline", waitForLoadingIndicator: false)
        app.navigationBars["Review Timeline"].buttons["Dashboard"].tap()

        // Find Radical
        tablesQuery.staticTexts["Radicals"].tap()
        sleep(2)
        snapshot("radicals", waitForLoadingIndicator: false)
        app.navigationBars["Radicals"].buttons["Dashboard"].tap()
    }
    
}
