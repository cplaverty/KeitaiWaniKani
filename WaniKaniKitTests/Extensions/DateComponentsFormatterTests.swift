//
//  DateComponentsFormatterTests.swift
//  WaniKaniKitTests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import XCTest
@testable import WaniKaniKit

class DateComponentsFormatterTests: XCTestCase {
    
    private var formatter: DateComponentsFormatter!
    
    override func setUp() {
        super.setUp()
        
        formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.year, .month, .weekOfMonth, .day, .hour, .minute]
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
    }
    
    override func tearDown() {
        formatter = nil
        
        super.tearDown()
    }
    
    func testZero() {
        let formatted = formatter.string(from: 0, roundingUpwardToNearest: .oneMinute)
        XCTAssertEqual(formatted, "0m")
    }
    
    func testPositive_ToHour() {
        let timeInterval = TimeInterval(29 * .oneMinute)
        let formatted = formatter.string(from: timeInterval)
        let truncated = formatter.string(from: timeInterval, roundingUpwardToNearest: .oneHour)
        XCTAssertEqual(formatted, "29m")
        XCTAssertEqual(truncated, "1h")
        
        let timeInterval2 = TimeInterval(89 * .oneMinute)
        let formatted2 = formatter.string(from: timeInterval2)
        let truncated2 = formatter.string(from: timeInterval2, roundingUpwardToNearest: .oneHour)
        XCTAssertEqual(formatted2, "1h 29m")
        XCTAssertEqual(truncated2, "2h")
    }
    
    func testNegative_ToHour() {
        let timeInterval = TimeInterval(-29 * .oneMinute)
        let formatted = formatter.string(from: timeInterval)
        let truncated = formatter.string(from: timeInterval, roundingUpwardToNearest: .oneHour)
        XCTAssertEqual(formatted, "-29m")
        XCTAssertEqual(truncated, "0m")
        
        let timeInterval2 = TimeInterval(-89 * .oneMinute)
        let formatted2 = formatter.string(from: timeInterval2)
        let truncated2 = formatter.string(from: timeInterval2, roundingUpwardToNearest: .oneHour)
        XCTAssertEqual(formatted2, "-1h 29m")
        XCTAssertEqual(truncated2, "-1h")
    }
    
    func testPositive_ToMinute() {
        let timeInterval = TimeInterval(29)
        let formatted = formatter.string(from: timeInterval)
        let truncated = formatter.string(from: timeInterval, roundingUpwardToNearest: .oneMinute)
        XCTAssertEqual(formatted, "0m")
        XCTAssertEqual(truncated, "1m")
        
        let timeInterval2 = TimeInterval(89)
        let formatted2 = formatter.string(from: timeInterval2)
        let truncated2 = formatter.string(from: timeInterval2, roundingUpwardToNearest: .oneMinute)
        XCTAssertEqual(formatted2, "1m")
        XCTAssertEqual(truncated2, "2m")
    }
    
    func testNegative_ToMinute() {
        let timeInterval = TimeInterval(-29)
        let formatted = formatter.string(from: timeInterval)
        let truncated = formatter.string(from: timeInterval, roundingUpwardToNearest: .oneMinute)
        XCTAssertEqual(formatted, "0m")
        XCTAssertEqual(truncated, "0m")
        
        let timeInterval2 = TimeInterval(-89)
        let formatted2 = formatter.string(from: timeInterval2)
        let truncated2 = formatter.string(from: timeInterval2, roundingUpwardToNearest: .oneMinute)
        XCTAssertEqual(formatted2, "-1m")
        XCTAssertEqual(truncated2, "-1m")
    }
    
}
