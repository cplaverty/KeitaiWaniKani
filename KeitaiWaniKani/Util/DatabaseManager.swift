//
//  DatabaseManager.swift
//  KeitaiWaniKani
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
    
    static var secureAppGroupPersistentStoreURL: NSURL = {
        let fm = NSFileManager.defaultManager()
        let directory = fm.containerURLForSecurityApplicationGroupIdentifier("group.uk.me.laverty.KeitaiWaniKani")!
        return directory.URLByAppendingPathComponent("WaniKaniData.sqlite")
    }()
    
    func recreateDatabase() {
        ApplicationSettings.purgeDatabase = true
        databaseQueue = DatabaseManager.createDatabaseQueue()
    }
    
    private static func createDatabaseQueue() -> FMDatabaseQueue {
        DDLogInfo("Creating database queue using SQLite \(FMDatabase.sqliteLibVersion()) and FMDB \(FMDatabase.FMDBUserVersion())")
        let storeURL = secureAppGroupPersistentStoreURL
        
        if ApplicationSettings.purgeDatabase {
            DDLogInfo("Database purge requested.  Deleting database file at \(storeURL)")
            do {
                try NSFileManager.defaultManager().removeItemAtURL(storeURL)
            } catch {
                DDLogWarn("Ignoring error when trying to remove store at \(storeURL): \(error)")
            }
            ApplicationSettings.purgeDatabase = false
        }
        
        var databaseQueue = createDatabaseQueueAtURL(storeURL)
        if databaseQueue == nil || !isValidDatabaseQueue(databaseQueue!) {
            // Our persistent store does not contain irreplaceable data. If we fail to add it, we can delete it and try again.
            DDLogWarn("Failed to create FMDatabaseQueue.  Deleting and trying again.")
            do {
                try NSFileManager.defaultManager().removeItemAtURL(storeURL)
            } catch {
                DDLogWarn("Ignoring error when trying to remove store at \(storeURL): \(error)")
            }
            databaseQueue = self.createDatabaseQueueAtURL(storeURL)
        }
        
        if let queue = databaseQueue {
            return queue
        }
        
        ApplicationSettings.purgeDatabase = true
        fatalError("Failed to create database at \(storeURL)")
    }
    
    private static func isValidDatabaseQueue(databaseQueue: FMDatabaseQueue) -> Bool {
        return try! databaseQueue.withDatabase { $0.goodConnection() }
    }
    
    private static func createDatabaseQueueAtURL(URL: NSURL) -> FMDatabaseQueue? {
        assert(URL.fileURL, "createDatabaseQueueAtURL requires a file URL")
        let path = URL.path!
        DDLogInfo("Creating FMDatabaseQueue at \(path)")
        if let databaseQueue = FMDatabaseQueue(path: path) {
            var successful = false
            databaseQueue.inDatabase { database in
                do {
                    try WaniKaniAPI.createTablesInDatabase(database)
                    successful = true
                } catch {
                    DDLogError("Failed to create schema due to error: \(error)")
                }
            }
            
            if successful {
                do {
                    try URL.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
                } catch {
                    DDLogWarn("Ignoring error when trying to exclude store at \(URL) from backup: \(error)")
                }
                return databaseQueue
            }
        }
        return nil
    }
}