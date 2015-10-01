//
//  WaniKaniAPI.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import FMDB

public struct WaniKaniAPI {
    public static let updateMinuteCount = 15
    public static let refreshTimeOffsetSeconds = Int(arc4random_uniform(25)) + 5
    
    public static func lastRefreshTimeFromNow() -> NSDate {
        return lastRefreshTimeFromDate(NSDate())
    }
    
    public static func lastRefreshTimeFromDate(baseDate: NSDate) -> NSDate {
        let calendar = NSCalendar.autoupdatingCurrentCalendar()
        let currentTimeComponents = calendar.components([.Minute, .Second], fromDate: baseDate)
        let offsetComponents = NSDateComponents()
        offsetComponents.minute = -(currentTimeComponents.minute % updateMinuteCount)
        offsetComponents.second = -currentTimeComponents.second
        return calendar.dateByAddingComponents(offsetComponents, toDate: baseDate, options: [])!
    }
    
    public static func nextRefreshTimeFromNow() -> NSDate {
        return nextRefreshTimeFromDate(NSDate())
    }
    
    public static func nextRefreshTimeFromDate(baseDate: NSDate) -> NSDate {
        let lastRefreshTime = self.lastRefreshTimeFromDate(baseDate)
        
        let calendar = NSCalendar.autoupdatingCurrentCalendar()
        // To allow for any kind of difference in time between local and the server, wait 'refreshTimeOffsetSeconds' past the "ideal" refresh time
        let offsetComponents = NSDateComponents()
        offsetComponents.minute = updateMinuteCount
        offsetComponents.second = refreshTimeOffsetSeconds
        return calendar.dateByAddingComponents(offsetComponents, toDate: lastRefreshTime, options: [])!
    }
    
    public static func createTablesInDatabase(database: FMDatabase) throws {
        try UserInformation.coder.createTable(database)
        try StudyQueue.coder.createTable(database)
        try LevelProgression.coder.createTable(database)
        try SRSDistribution.coder.createTable(database)
        try Radical.coder.createTable(database)
        try Kanji.coder.createTable(database)
        try Vocabulary.coder.createTable(database)
        
        database.setShouldCacheStatements(true)
    }
    
    public static func resourceResolverForAPIKey(apiKey: String) -> ResourceResolver {
        return WaniKaniAPIResourceResolver(forAPIKey: apiKey)
    }
}
