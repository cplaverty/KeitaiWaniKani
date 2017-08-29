//
//  Calendar.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

extension Calendar {
    public func startOfHour(for date: Date) -> Date {
        let dateComponents = DateComponents(minute: 0, second: 0, nanosecond: 0)
        if self.date(date, matchesComponents: dateComponents) {
            return date
        }
        return nextDate(after: date, matching: dateComponents, matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .backward)!
    }
}
