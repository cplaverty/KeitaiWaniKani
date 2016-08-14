//
//  UtilityFunctions.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ second: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    components.second = second
    
    let calendar = Calendar.autoupdatingCurrent
    guard let date = calendar.date(from: components) else {
        fatalError("Invalid date components specified: \(components)")
    }
    
    return date
}
