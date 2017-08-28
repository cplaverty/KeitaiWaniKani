//
//  DateComponentsFormatter.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public extension DateComponentsFormatter {
    public func string(from ti: TimeInterval, roundingUpwardToNearest ti2: TimeInterval) -> String? {
        let roundedTimeInterval = ti + (ti2 - ti.truncatingRemainder(dividingBy: ti2)).truncatingRemainder(dividingBy: ti2)
        return string(from: roundedTimeInterval)
    }
}
