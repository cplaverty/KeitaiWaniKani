//
//  SnapshotUITests.swift
//  AlliCrabUITests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import SimulatorStatusMagic
import XCTest

class SnapshotUITests: XCTestCase {
    
    let apiKey = "8888ca94-9a79-48cc-b628-5d938259e469"
    
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        
        SDStatusBarManager.sharedInstance()?.enableOverrides()
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }
    
    override func tearDown() {
        super.tearDown()
        
        SDStatusBarManager.sharedInstance()?.disableOverrides()
    }
    
    func testScreenshot() {
        let app = XCUIApplication()
        let tablesQuery = app.tables
        
        let exists = NSPredicate(format: "exists == YES")
        
        app.buttons["ManualAPIKeyEntry"].tap()
        
        app.textFields["EnterAPIKey"].typeText(apiKey)
        app.navigationBars["Enter API Key"].buttons["Done"].tap()
        
        // Dashboard
        let dashboard = app.navigationBars["Dashboard"]
        expectation(for: exists, evaluatedWith: dashboard, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
        XCTAssert(dashboard.exists, "Dashboard not loaded")
        
        snapshot("1 dashboard", timeWaitingForIdle: 120)
        
        // Review Timeline
        let reviewTimelineText = tablesQuery.cells.staticTexts["ReviewTimeline"]
        expectation(for: exists, evaluatedWith: reviewTimelineText, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
        XCTAssert(reviewTimelineText.exists, "All Upcoming Reviews link not found")
        reviewTimelineText.tap()
        
        let reviewTimeline = app.navigationBars["Review Timeline"]
        expectation(for: exists, evaluatedWith: reviewTimeline, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
        XCTAssert(reviewTimeline.exists, "Review Timeline not loaded")
        snapshot("2 review-timeline")
        
        // Back to Dashboard
        reviewTimeline.buttons["Dashboard"].tap()
        expectation(for: exists, evaluatedWith: dashboard, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
        XCTAssert(dashboard.exists, "Dashboard not loaded")
        
        // Kanji Progress
        let kanjiText = tablesQuery.cells.staticTexts["Kanji"]
        XCTAssert(kanjiText.exists, "Kanji level progress link not found")
        kanjiText.tap()
        
        let kanji = app.navigationBars["Kanji"]
        expectation(for: exists, evaluatedWith: kanji, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
        XCTAssert(kanji.exists, "Kanji progress not loaded")
        snapshot("3 kanji-progress")
        
        // Subject Detail
        let subjectCharacter = "右"
        let subjectText = app.collectionViews.staticTexts[subjectCharacter]
        XCTAssert(subjectText.exists, "Subject from Kanji level progress link not found")
        subjectText.tap()
        
        let subject = app.navigationBars[subjectCharacter]
        expectation(for: exists, evaluatedWith: subject, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
        XCTAssert(subject.exists, "Subject detail not loaded")
        snapshot("4 subject-detail")
        
        subject.buttons["Kanji"].tap()
        kanji.buttons["Dashboard"].tap()
    }
    
}
