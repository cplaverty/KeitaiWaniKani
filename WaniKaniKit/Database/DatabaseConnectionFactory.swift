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

open class DefaultDatabaseConnectionFactory: DatabaseConnectionFactory {
    public let url: URL
    
    public init(url: URL) {
        self.url = url
    }
    
    public func makeDatabaseQueue() -> FMDatabaseQueue? {
        os_log("Creating database queue using SQLite %@ and FMDB %@ at %@", type: .info, FMDatabase.sqliteLibVersion(), FMDatabase.fmdbUserVersion(), url.path)
        return FMDatabaseQueue(url: url)
    }
    
    public func destroyDatabase() throws {
        os_log("Removing database at %@", type: .info, url.path)
        try FileManager.default.removeItem(at: url)
    }
}

public class AppGroupDatabaseConnectionFactory: DefaultDatabaseConnectionFactory {
    public init() {
        let groupIdentifier = "group.uk.me.laverty.KeitaiWaniKani"
        guard let appGroupContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) else {
            os_log("Can't find group shared directory for group identifier %@", type: .fault, groupIdentifier)
            fatalError("Can't find group shared directory for group identifier \(groupIdentifier)")
        }
        
        super.init(url: appGroupContainerURL.appendingPathComponent("WaniKaniData-v2.db"))
        
        let legacyPersistentStoreURL = appGroupContainerURL.appendingPathComponent("WaniKaniData.sqlite")
        if FileManager.default.fileExists(atPath: legacyPersistentStoreURL.path) {
            os_log("Trying to remove legacy store at %@", type: .debug, legacyPersistentStoreURL.path)
            try? FileManager.default.removeItem(at: legacyPersistentStoreURL)
        }
    }
    
    public override func makeDatabaseQueue() -> FMDatabaseQueue? {
        let databaseQueue = super.makeDatabaseQueue()
        excludeStoreFromBackup()
        
        return databaseQueue
    }
    
    private func excludeStoreFromBackup() {
        var url = super.url
        do {
            var resourceValues = try url.resourceValues(forKeys: [.isExcludedFromBackupKey])
            if resourceValues.isExcludedFromBackup != true {
                os_log("Excluding store at %@ from backup", type: .debug, url.path)
                resourceValues.isExcludedFromBackup = true
                try url.setResourceValues(resourceValues)
            }
        } catch {
            os_log("Ignoring error when trying to exclude store at %@ from backup: %@", type: .error, url.path, error as NSError)
        }
    }
}
