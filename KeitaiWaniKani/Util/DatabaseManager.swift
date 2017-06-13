//
//  DatabaseManager.swift
//  AlliCrab
//
//  Copyright © 2016 Chris Laverty. All rights reserved.
//

import CocoaLumberjack
import FMDB
import WaniKaniKit

public class DatabaseManager {
    var databaseQueue: FMDatabaseQueue
    
    init() {
        databaseQueue = DatabaseManager.createDatabaseQueue()
    }
    
    static var secureAppGroupPersistentStoreURL: URL = {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("Can't find bundle identifier")
        }
        let groupIdentifier = "group.\(bundleIdentifier)"
        let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)!
        return directory.appendingPathComponent("WaniKaniData.sqlite")
    }()
    
    func recreateDatabase() {
        ApplicationSettings.purgeDatabase = true
        databaseQueue = DatabaseManager.createDatabaseQueue()
    }
    
    func clearCachedStatements() {
        databaseQueue.inDatabase { $0.clearCachedStatements() }
    }
    
    private static func createDatabaseQueue() -> FMDatabaseQueue {
        DDLogInfo("Creating database queue using SQLite \(FMDatabase.sqliteLibVersion()) and FMDB \(FMDatabase.fmdbUserVersion())")
        let storeURL = secureAppGroupPersistentStoreURL
        
        if ApplicationSettings.purgeDatabase {
            DDLogInfo("Database purge requested.  Deleting database file at \(storeURL)")
            do {
                try FileManager.default.removeItem(at: storeURL)
            } catch {
                DDLogWarn("Ignoring error when trying to remove store at \(storeURL): \(error)")
            }
            ApplicationSettings.purgeDatabase = false
        }
        
        var databaseQueue = createDatabaseQueue(url: storeURL)
        if databaseQueue == nil || !isValidDatabaseQueue(databaseQueue!) {
            // Our persistent store does not contain irreplaceable data. If we fail to add it, we can delete it and try again.
            DDLogWarn("Failed to create FMDatabaseQueue.  Deleting and trying again.")
            do {
                try FileManager.default.removeItem(at: storeURL)
            } catch {
                DDLogWarn("Ignoring error when trying to remove store at \(storeURL): \(error)")
            }
            databaseQueue = self.createDatabaseQueue(url: storeURL)
        }
        
        if let queue = databaseQueue {
            return queue
        }
        
        ApplicationSettings.purgeDatabase = true
        fatalError("Failed to create database at \(storeURL)")
    }
    
    private static func isValidDatabaseQueue(_ databaseQueue: FMDatabaseQueue) -> Bool {
        return (try? databaseQueue.withDatabase { $0.goodConnection }) ?? false
    }
    
    private static func createDatabaseQueue(url: URL) -> FMDatabaseQueue? {
        assert(url.isFileURL, "createDatabaseQueueAtURL requires a file URL")
        var url = url
        DDLogInfo("Creating FMDatabaseQueue at \(url)")
        let databaseQueue = FMDatabaseQueue(url: url)
        var successful = false
        databaseQueue.inDatabase { database in
            do {
                try WaniKaniAPI.createTables(in: database)
                successful = true
            } catch {
                DDLogError("Failed to create schema due to error: \(error)")
            }
        }
        
        if successful {
            do {
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = true
                try url.setResourceValues(resourceValues)
            } catch {
                DDLogWarn("Ignoring error when trying to exclude store at \(url) from backup: \(error)")
            }
            return databaseQueue
        }
        return nil
    }
}
