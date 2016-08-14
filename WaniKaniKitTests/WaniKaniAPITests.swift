//
//  WaniKaniAPITests.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
@testable import WaniKaniKit

class WaniKaniAPITests: XCTestCase {
    
    func testStandard() {
        let referenceDate = date(2015, 1, 1, 12, 34, 30)
        let expectedLastRefreshTime = date(2015, 1, 1, 12, 30, 0)
        let expectedNextRefreshTime = date(2015, 1, 1, 12, 45, WaniKaniAPI.refreshTimeOffsetSeconds)
        let lastRefreshTime = WaniKaniAPI.lastRefreshTime(from: referenceDate)
        let nextRefreshTime = WaniKaniAPI.nextRefreshTime(from: referenceDate)
        
        XCTAssertEqual(lastRefreshTime, expectedLastRefreshTime)
        XCTAssertEqual(nextRefreshTime, expectedNextRefreshTime)
    }
    
    func testMidnight() {
        let referenceDate = date(2015, 1, 1, 0, 0, 0)
        let expectedLastRefreshTime = date(2015, 1, 1, 0, 0, 0)
        let expectedNextRefreshTime = date(2015, 1, 1, 0, 15, WaniKaniAPI.refreshTimeOffsetSeconds)
        let lastRefreshTime = WaniKaniAPI.lastRefreshTime(from: referenceDate)
        let nextRefreshTime = WaniKaniAPI.nextRefreshTime(from: referenceDate)
        
        XCTAssertEqual(lastRefreshTime, expectedLastRefreshTime)
        XCTAssertEqual(nextRefreshTime, expectedNextRefreshTime)
    }
    
    func testJustBeforeMidnight() {
        let referenceDate = date(2014, 12, 31, 23, 59, 59)
        let expectedLastRefreshTime = date(2014, 12, 31, 23, 45, 0)
        let expectedNextRefreshTime = date(2015, 1, 1, 0, 0, WaniKaniAPI.refreshTimeOffsetSeconds)
        let lastRefreshTime = WaniKaniAPI.lastRefreshTime(from: referenceDate)
        let nextRefreshTime = WaniKaniAPI.nextRefreshTime(from: referenceDate)
        
        XCTAssertEqual(lastRefreshTime, expectedLastRefreshTime)
        XCTAssertEqual(nextRefreshTime, expectedNextRefreshTime)
    }
    
    func testJustAfterMidnight() {
        let referenceDate = date(2015, 1, 1, 0, 1, 0)
        let expectedLastRefreshTime = date(2015, 1, 1, 0, 0, 0)
        let expectedNextRefreshTime = date(2015, 1, 1, 0, 15, WaniKaniAPI.refreshTimeOffsetSeconds)
        let lastRefreshTime = WaniKaniAPI.lastRefreshTime(from: referenceDate)
        let nextRefreshTime = WaniKaniAPI.nextRefreshTime(from: referenceDate)
        
        XCTAssertEqual(lastRefreshTime, expectedLastRefreshTime)
        XCTAssertEqual(nextRefreshTime, expectedNextRefreshTime)
    }
    
}
