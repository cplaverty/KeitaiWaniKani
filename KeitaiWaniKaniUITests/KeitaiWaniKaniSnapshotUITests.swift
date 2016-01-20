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
        
        app.buttons["Log in to WaniKani"].tap()
        sleep(5)
        
        let exists = NSPredicate(format: "exists == YES")
        let hittable = NSPredicate(format: "hittable == YES")
        
        // Dashboard
        let dashboard = app.navigationBars["Dashboard"]
        expectationForPredicate(exists, evaluatedWithObject: dashboard, handler: nil)
        waitForExpectationsWithTimeout(15, handler: nil)
        XCTAssert(dashboard.exists, "Dashboard not loaded")
        
        sleep(10)
        snapshot("1 dashboard", waitForLoadingIndicator: false)
        
        let tablesQuery = app.tables
        
        // Review Timeline
        let allUpcomingReviewsText = tablesQuery.cells.staticTexts["All Upcoming Reviews"]
        expectationForPredicate(hittable, evaluatedWithObject: allUpcomingReviewsText, handler: nil)
        waitForExpectationsWithTimeout(15, handler: nil)
        XCTAssert(allUpcomingReviewsText.hittable, "All Upcoming Reviews link not hittable")
        tablesQuery.cells.staticTexts["All Upcoming Reviews"].tap()
        
        let reviewTimeline = app.navigationBars["Review Timeline"]
        expectationForPredicate(exists, evaluatedWithObject: reviewTimeline, handler: nil)
        waitForExpectationsWithTimeout(15, handler: nil)
        XCTAssert(reviewTimeline.exists, "Review Timeline not loaded")
        snapshot("3 review-timeline", waitForLoadingIndicator: false)
        reviewTimeline.buttons["Dashboard"].tap()
        
        // Kanji
        tablesQuery.cells.staticTexts["Kanji"].tap()
        let kanji = app.navigationBars["Kanji"]
        expectationForPredicate(exists, evaluatedWithObject: kanji, handler: nil)
        waitForExpectationsWithTimeout(15, handler: nil)
        XCTAssert(kanji.exists, "Kanji not loaded")
        snapshot("4 kanji", waitForLoadingIndicator: false)
        kanji.buttons["Dashboard"].tap()
        
        // Review Page
        tablesQuery.cells.staticTexts["Reviews"].tap()
        sleep(5)
        snapshot("2 review-page", waitForLoadingIndicator: false)
    }
    
}
