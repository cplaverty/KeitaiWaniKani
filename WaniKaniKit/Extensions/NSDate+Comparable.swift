//
//  NSDate+Comparable.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

extension NSDate: Comparable {
}

public func <=(lhs: NSDate, rhs: NSDate) -> Bool {
    let res = lhs.compare(rhs)
    return res == .OrderedAscending || res == .OrderedSame
}
public func >=(lhs: NSDate, rhs: NSDate) -> Bool {
    let res = lhs.compare(rhs)
    return res == .OrderedDescending || res == .OrderedSame
}
public func >(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.compare(rhs) == .OrderedDescending
}
public func <(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.compare(rhs) == .OrderedAscending
}
