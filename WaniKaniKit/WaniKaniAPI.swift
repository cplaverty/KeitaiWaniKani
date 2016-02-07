//
//  WaniKaniAPI.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import CocoaLumberjack
import FMDB

private let currentDatabaseVersion = 1

private struct DatabaseMetadata {
    var databaseVersion: Int {
        get {
            do {
                return try database.longForQuery("SELECT value FROM \(tableName) where name = ?", "version") ?? 0
            } catch {
                return 0
            }
        }
        set {
            do {
                try database.executeUpdate("INSERT OR REPLACE INTO \(tableName)(name, value) VALUES (?, ?)", "version", newValue)
            } catch {
                DDLogWarn("Failed to update database version: \(error)")
            }
        }
    }
    
    private let tableName = "kwk_metadata"
    private let database: FMDatabase
    
    init(database: FMDatabase) throws {
        self.database = database
        try database.executeUpdate("CREATE TABLE IF NOT EXISTS \(self.tableName)(name TEXT PRIMARY KEY, value TEXT)")
    }
}

public struct WaniKaniDarwinNotificationCenter {
    public static let modelUpdateNotificationName = "uk.me.laverty.KeitaiWaniKani.ModelUpdate"
    
    public static func notificationNameForModelObjectType(modelObjectType: String) -> String {
        return "\(modelUpdateNotificationName).\(modelObjectType)"
    }
    
    public static func postModelUpdateMessage(modelObjectType: String) {
        let nc = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(nc, notificationNameForModelObjectType(modelObjectType), nil, nil, true)
    }
}

public struct WaniKaniAPI {
    public static let updateMinuteCount = 15
    public static let refreshTimeOffsetSeconds = Int(arc4random_uniform(25)) + 5
    
    public static func isAcceleratedLevel(level: Int) -> Bool {
        return level <= 2
    }
    
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
    
    public static func needsRefresh(lastRefreshTime: NSDate) -> Bool {
        let mostRecentAPIDataChangeTime = WaniKaniAPI.lastRefreshTimeFromNow()
        let secondsSinceLastRefreshTime = lastRefreshTime.timeIntervalSinceDate(mostRecentAPIDataChangeTime)
        // Only update if we haven't updated since the last refresh time
        return secondsSinceLastRefreshTime <= 0
    }
    
    public static func databaseIsCurrentVersion(database: FMDatabase) throws -> Bool {
        let metadata = try DatabaseMetadata(database: database)
        return metadata.databaseVersion == currentDatabaseVersion
    }
    
    public static func createTablesInDatabase(database: FMDatabase) throws {
        var metadata = try DatabaseMetadata(database: database)
        
        let shouldDropTable = metadata.databaseVersion != currentDatabaseVersion
        
        DDLogInfo("Database at version \(metadata.databaseVersion)")
        if shouldDropTable {
            DDLogInfo("Upgrading database from version \(metadata.databaseVersion) to \(currentDatabaseVersion)")
        }
        try UserInformation.coder.createTable(database, dropFirst: shouldDropTable)
        try StudyQueue.coder.createTable(database, dropFirst: shouldDropTable)
        try LevelProgression.coder.createTable(database, dropFirst: shouldDropTable)
        try SRSDistribution.coder.createTable(database, dropFirst: shouldDropTable)
        try Radical.coder.createTable(database, dropFirst: shouldDropTable)
        try Kanji.coder.createTable(database, dropFirst: shouldDropTable)
        try Vocabulary.coder.createTable(database, dropFirst: shouldDropTable)
        metadata.databaseVersion = currentDatabaseVersion
        
        DDLogInfo("Vacuuming database")
        try database.executeUpdate("VACUUM")
        
//        database.setShouldCacheStatements(true)
    }
    
    public static func resourceResolverForAPIKey(apiKey: String) -> ResourceResolver {
        return WaniKaniAPIResourceResolver(forAPIKey: apiKey)
    }
    
    public static func minimumTimeFromSRSLevel(initialLevel: Int, toSRSLevel finalLevel: Int, fromDate baseDate: NSDate, isRadical: Bool, isAccelerated: Bool) -> NSDate? {
        var guruDate = baseDate
        let calendar = NSCalendar.autoupdatingCurrentCalendar()
        for level in initialLevel..<finalLevel {
            guard let timeForLevel = timeToNextReviewForSRSLevel(level, isRadical: isRadical, isAccelerated: isAccelerated) else { return nil }
            guruDate = calendar.dateByAddingComponents(timeForLevel, toDate: guruDate, options: [])!
        }
        
        return guruDate
    }
    
    private static func timeToNextReviewForSRSLevel(srsLevelNumeric: Int, isRadical: Bool, isAccelerated: Bool) -> NSDateComponents? {
        switch srsLevelNumeric {
        case 1 where isAccelerated:
            let dc = NSDateComponents()
            dc.hour = 2
            return dc
        case 1, 2 where isAccelerated:
            let dc = NSDateComponents()
            dc.hour = 4
            return dc
        case 2, 3 where isAccelerated:
            let dc = NSDateComponents()
            dc.hour = 8
            return dc
        case 3, 4 where isAccelerated:
            let dc = NSDateComponents()
            dc.day = 1
            dc.hour = -1
            return dc
        case 4:
            let dc = NSDateComponents()
            dc.day = isRadical ? 2 : 3
            dc.hour = -1
            return dc
        case 5: // -> 6
            let dc = NSDateComponents()
            dc.day = 7
            dc.hour = -1
            return dc
        case 6: // -> 7
            let dc = NSDateComponents()
            dc.day = 14
            dc.hour = -1
            return dc
        case 7: // -> 8
            let dc = NSDateComponents()
            dc.month = 1
            dc.hour = -1
            return dc
        case 8: // -> 9
            let dc = NSDateComponents()
            dc.month = 4
            dc.hour = -1
            return dc
        default: return nil
        }
    }

}
