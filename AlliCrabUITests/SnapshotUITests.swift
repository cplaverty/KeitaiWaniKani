//
//  SnapshotUITests.swift
//  AlliCrabUITests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import XCTest

class SnapshotUITests: XCTestCase {
    
    let apiKey = "8888ca94-9a79-48cc-b628-5d938259e469"
    
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }
    
    func testScreenshot() {
        let app = XCUIApplication()
        
        app.buttons["ManualAPIKeyEntry"].tap()
        
        app.textFields["EnterAPIKey"].typeText(apiKey)
        app.navigationBars["Enter API Key"].buttons["Done"].tap()
        
        let exists = NSPredicate(format: "exists == YES")
        let hittable = NSPredicate(format: "hittable == YES")
        
        // Dashboard
        let dashboard = app.navigationBars["Dashboard"]
        expectation(for: exists, evaluatedWith: dashboard, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
        XCTAssert(dashboard.exists, "Dashboard not loaded")
        
        snapshot("1 dashboard")
        
        let tablesQuery = app.tables
        
        // Review Timeline
        let reviewTimelineText = tablesQuery.cells.staticTexts["ReviewTimeline"]
        expectation(for: hittable, evaluatedWith: reviewTimelineText, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
        XCTAssert(reviewTimelineText.isHittable, "All Upcoming Reviews link not hittable")
        reviewTimelineText.tap()
        
        let reviewTimeline = app.navigationBars["Review Timeline"]
        expectation(for: exists, evaluatedWith: reviewTimeline, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
        XCTAssert(reviewTimeline.exists, "Review Timeline not loaded")
        snapshot("2 review-timeline")
        reviewTimeline.buttons["Dashboard"].tap()
        
        // Kanji
        let kanjiText = tablesQuery.cells.staticTexts["Kanji"]
        expectation(for: hittable, evaluatedWith: kanjiText, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
        XCTAssert(kanjiText.isHittable, "Kanji level progress link not hittable")
        kanjiText.tap()
        
        let kanji = app.navigationBars["Kanji"]
        expectation(for: exists, evaluatedWith: kanji, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
        XCTAssert(kanji.exists, "Kanji not loaded")
        snapshot("3 kanji")
        kanji.buttons["Dashboard"].tap()
    }
    
}
