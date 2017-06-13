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
                return try database.longForQuery("SELECT value FROM \(tableName) where name = ?", "version" as NSString) ?? 0
            } catch {
                return 0
            }
        }
        set {
            do {
                try database.executeUpdate("INSERT OR REPLACE INTO \(tableName)(name, value) VALUES (?, ?)", "version" as NSString, newValue as NSNumber)
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
    
    public static func notificationNameForModelObjectType(_ modelObjectType: String) -> NSString {
        return "\(modelUpdateNotificationName).\(modelObjectType)" as NSString
    }
    
    public static func postModelUpdateMessage(_ modelObjectType: String) {
        let nc = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(nc, CFNotificationName(notificationNameForModelObjectType(modelObjectType)), nil, nil, true)
    }
}

public struct WaniKaniAPI {
    public static let updateMinuteCount = 15
    public static let refreshTimeOffsetSeconds = Int(arc4random_uniform(25)) + 5
    
    public static func isAccelerated(level: Int) -> Bool {
        return level <= 2
    }
    
    public static func lastRefreshTimeFromNow() -> Date {
        return lastRefreshTime(from: Date())
    }
    
    public static func lastRefreshTime(from baseDate: Date) -> Date {
        let calendar = Calendar.autoupdatingCurrent
        let currentTimeComponents = calendar.dateComponents([.minute, .second], from: baseDate)
        var offsetComponents = DateComponents()
        offsetComponents.minute = -(currentTimeComponents.minute! % updateMinuteCount)
        offsetComponents.second = -currentTimeComponents.second!
        return calendar.date(byAdding: offsetComponents, to: baseDate)!
    }
    
    public static func nextRefreshTimeFromNow() -> Date {
        return nextRefreshTime(from: Date())
    }
    
    public static func nextRefreshTime(from baseDate: Date) -> Date {
        let lastRefreshTime = self.lastRefreshTime(from: baseDate)
        
        let calendar = Calendar.autoupdatingCurrent
        // To allow for any kind of difference in time between local and the server, wait 'refreshTimeOffsetSeconds' past the "ideal" refresh time
        var offsetComponents = DateComponents()
        offsetComponents.minute = updateMinuteCount
        offsetComponents.second = refreshTimeOffsetSeconds
        return calendar.date(byAdding: offsetComponents, to: lastRefreshTime)!
    }
    
    public static func needsRefresh(since lastRefreshTime: Date) -> Bool {
        let mostRecentAPIDataChangeTime = WaniKaniAPI.lastRefreshTimeFromNow()
        let secondsSinceLastRefreshTime = lastRefreshTime.timeIntervalSince(mostRecentAPIDataChangeTime)
        // Only update if we haven't updated since the last refresh time
        return secondsSinceLastRefreshTime <= 0
    }
    
    public static func databaseIsCurrentVersion(_ database: FMDatabase) throws -> Bool {
        let metadata = try DatabaseMetadata(database: database)
        return metadata.databaseVersion == currentDatabaseVersion
    }
    
    public static func createTables(in database: FMDatabase) throws {
        #if DEBUG
            database.crashOnErrors = true
        #endif
        
        var metadata = try DatabaseMetadata(database: database)
        
        let shouldDropTable = metadata.databaseVersion != currentDatabaseVersion
        
        DDLogInfo("Database at version \(metadata.databaseVersion)")
        if shouldDropTable {
            DDLogInfo("Upgrading database from version \(metadata.databaseVersion) to \(currentDatabaseVersion)")
        }
        try UserInformation.coder.createTable(in: database, dropExisting: shouldDropTable)
        try StudyQueue.coder.createTable(in: database, dropExisting: shouldDropTable)
        try LevelProgression.coder.createTable(in: database, dropExisting: shouldDropTable)
        try SRSDistribution.coder.createTable(in: database, dropExisting: shouldDropTable)
        try Radical.coder.createTable(in: database, dropExisting: shouldDropTable)
        try Kanji.coder.createTable(in: database, dropExisting: shouldDropTable)
        try Vocabulary.coder.createTable(in: database, dropExisting: shouldDropTable)
        metadata.databaseVersion = currentDatabaseVersion
        
        DDLogInfo("Vacuuming database")
        try database.executeUpdate("VACUUM")
        
        database.shouldCacheStatements = true
    }
    
    public static func resourceResolverForAPIKey(_ apiKey: String) -> ResourceResolver {
        return WaniKaniAPIResourceResolver(apiKey: apiKey)
    }
    
    public static func minimumTime(fromSRSLevel initialLevel: Int, to finalLevel: Int, fromDate baseDate: Date, isAcceleratedLevel: Bool) -> Date? {
        var guruDate = baseDate
        let calendar = Calendar.autoupdatingCurrent
        for level in initialLevel..<finalLevel {
            guard let timeForLevel = timeToNextReview(forSRSLevel: level, isAcceleratedLevel: isAcceleratedLevel) else { return nil }
            guruDate = calendar.date(byAdding: timeForLevel, to: guruDate)!
        }
        
        return guruDate
    }
    
    private static func timeToNextReview(forSRSLevel srsLevelNumeric: Int, isAcceleratedLevel: Bool) -> DateComponents? {
        switch srsLevelNumeric {
        case 1 where isAcceleratedLevel:
            var dc = DateComponents()
            dc.hour = 2
            return dc
        case 1,
             2 where isAcceleratedLevel:
            var dc = DateComponents()
            dc.hour = 4
            return dc
        case 2,
             3 where isAcceleratedLevel:
            var dc = DateComponents()
            dc.hour = 8
            return dc
        case 3,
             4 where isAcceleratedLevel:
            var dc = DateComponents()
            dc.day = 1
            dc.hour = -1
            return dc
        case 4:
            var dc = DateComponents()
            dc.day = 2
            dc.hour = -1
            return dc
        case 5:
            var dc = DateComponents()
            dc.day = 7
            dc.hour = -1
            return dc
        case 6:
            var dc = DateComponents()
            dc.day = 14
            dc.hour = -1
            return dc
        case 7:
            var dc = DateComponents()
            dc.month = 1
            dc.hour = -1
            return dc
        case 8:
            var dc = DateComponents()
            dc.month = 4
            dc.hour = -1
            return dc
        default: return nil
        }
    }
    
}
