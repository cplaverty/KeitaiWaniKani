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
            return database.longForQuery("SELECT value FROM \(tableName) where name = ?", "version") ?? 0
        }
        set {
            if !database.executeUpdate("INSERT OR REPLACE INTO \(tableName)(name, value) VALUES (?, ?)", "version", newValue) {
                DDLogWarn("Failed to update database version: \(self.database.lastError())")
            }
        }
    }
    
    private let tableName = "kwk_metadata"
    private let database: FMDatabase
    
    init(database: FMDatabase) throws {
        self.database = database
        guard database.executeUpdate("CREATE TABLE IF NOT EXISTS \(self.tableName)(name TEXT PRIMARY KEY, value TEXT)") else {
            throw database.lastError()
        }
    }
}

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
        database.executeUpdate("VACUUM")
        
        database.setShouldCacheStatements(true)
    }
    
    public static func resourceResolverForAPIKey(apiKey: String) -> ResourceResolver {
        return WaniKaniAPIResourceResolver(forAPIKey: apiKey)
    }
}
