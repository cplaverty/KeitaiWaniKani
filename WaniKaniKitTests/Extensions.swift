//
//  Extensions.swift
//  WaniKaniKitTests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import XCTest

let utcTimeZone = TimeZone(identifier: "UTC")!

extension XCTestCase {
    func makeUTCDate(year: Int? = nil, month: Int? = nil, day: Int? = nil, hour: Int? = nil, minute: Int? = nil, second: Int? = nil) -> Date {
        let calendar = Calendar.current
        return DateComponents(calendar: calendar, timeZone: utcTimeZone, year: year, month: month, day: day, hour: hour, minute: minute, second: second).date!
    }
}
