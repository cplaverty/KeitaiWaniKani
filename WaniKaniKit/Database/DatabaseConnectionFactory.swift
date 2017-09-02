//
//  DatabaseConnectionFactory.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB
import os

public protocol DatabaseConnectionFactory {
    func makeDatabaseQueue() -> FMDatabaseQueue?
    func destroyDatabase() throws
}

public class AppGroupDatabaseConnectionFactory: DatabaseConnectionFactory {
    private let persistentStoreURL: URL
    
    public init() {
        let groupIdentifier = "group.uk.me.laverty.KeitaiWaniKani"
        guard let appGroupContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) else {
            if #available(iOS 10.0, *) {
                os_log("Can't find group shared directory for group identifier %@", type: .fault, groupIdentifier)
            }
            fatalError("Can't find group shared directory for group identifier \(groupIdentifier)")
        }
        
        self.persistentStoreURL = appGroupContainerURL.appendingPathComponent("WaniKaniData-v2.db")
        
        let legacyPersistentStoreURL = appGroupContainerURL.appendingPathComponent("WaniKaniData.sqlite")
        if FileManager.default.fileExists(atPath: legacyPersistentStoreURL.path) {
            if #available(iOS 10.0, *) {
                os_log("Trying to remove legacy store at %@", type: .debug, legacyPersistentStoreURL as NSURL)
            }
            try? FileManager.default.removeItem(at: legacyPersistentStoreURL)
        }
    }
    
    public func makeDatabaseQueue() -> FMDatabaseQueue? {
        let url = persistentStoreURL
        
        if #available(iOS 10.0, *) {
            os_log("Creating database queue using SQLite %@ and FMDB %@ at %@", type: .info, FMDatabase.sqliteLibVersion(), FMDatabase.fmdbUserVersion(), url.path)
        }
        
        let databaseQueue = FMDatabaseQueue(url: url)
        excludeStoreFromBackup()
        
        return databaseQueue
    }
    
    public func destroyDatabase() throws {
        try FileManager.default.removeItem(at: persistentStoreURL)
    }
    
    private func excludeStoreFromBackup() {
        var url = persistentStoreURL
        do {
            var resourceValues = try url.resourceValues(forKeys: [.isExcludedFromBackupKey])
            if resourceValues.isExcludedFromBackup != true {
                if #available(iOS 10.0, *) {
                    os_log("Excluding store at %@ from backup", type: .debug, url as NSURL)
                }
                resourceValues.isExcludedFromBackup = true
                try url.setResourceValues(resourceValues)
            }
        } catch {
            if #available(iOS 10.0, *) {
                os_log("Ignoring error when trying to exclude store at %@ from backup: %@", type: .error, url as NSURL, error as NSError)
            }
        }
    }
}
