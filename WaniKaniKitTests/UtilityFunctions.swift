//
//  UtilityFunctions.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

func date(year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ second: Int) -> NSDate {
    let components = NSDateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    components.second = second
    
    let calendar = NSCalendar.autoupdatingCurrentCalendar()
    guard let date = calendar.dateFromComponents(components) else {
        fatalError("Invalid date components specified: \(components)")
    }
    
    return date
}
