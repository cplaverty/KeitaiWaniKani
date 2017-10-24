//
//  DatabaseManager.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB
import os

public class DatabaseManager {
    private let factory: DatabaseConnectionFactory
    private let schemaManager = DatabaseSchemaManager()
    
    private var memoryWarningObserver: NSObjectProtocol?
    private var isReadOnlyConnection: Bool = true
    
    public var databaseQueue: FMDatabaseQueue? {
        didSet {
            if let memoryWarningObserver = memoryWarningObserver {
                if #available(iOS 10.0, *) {
                    os_log("Removing memory warning listener (databaseQueue didSet)", type: .debug)
                }
                NotificationCenter.default.removeObserver(memoryWarningObserver)
                self.memoryWarningObserver = nil
            }
            
            if let databaseQueue = databaseQueue {
                if #available(iOS 10.0, *) {
                    os_log("Adding memory warning listener", type: .debug)
                }
                memoryWarningObserver = NotificationCenter.default.addObserver(forName: .UIApplicationDidReceiveMemoryWarning, object: nil, queue: nil) { _ in
                    if #available(iOS 10.0, *) {
                        os_log("Memory warning.  Clearing cached statements.", type: .debug)
                    }
                    databaseQueue.inDatabase { database in
                        try? database.executeUpdate("PRAGMA shrink_memory", values: nil)
                        database.clearCachedStatements()
                    }
                }
            }
        }
    }
    
    public init(factory: DatabaseConnectionFactory) {
        self.factory = factory
    }
    
    deinit {
        if let memoryWarningObserver = memoryWarningObserver {
            if #available(iOS 10.0, *) {
                os_log("Removing memory warning listener (deinit)", type: .debug)
            }
            NotificationCenter.default.removeObserver(memoryWarningObserver)
            self.memoryWarningObserver = nil
        }
    }
    
    public func open(readOnly: Bool = false) -> Bool {
        guard databaseQueue == nil else {
            return true
        }
        
        isReadOnlyConnection = readOnly
        databaseQueue = makeDatabaseQueue()
        
        return databaseQueue != nil
    }
    
    public func close() {
        databaseQueue?.close()
        databaseQueue = nil
        isReadOnlyConnection = true
    }
    
    private func makeDatabaseQueue() -> FMDatabaseQueue? {
        return makeDatabaseQueue(attemptNumber: 1)
    }
    
    private func makeDatabaseQueue(attemptNumber: Int) -> FMDatabaseQueue? {
        guard let databaseQueue = factory.makeDatabaseQueue() else {
            return nil
        }
        
        var isGoodConnection = false
        var isCurrentSchemaVersion = false
        databaseQueue.inDatabase { database in
            #if DEBUG
                database.crashOnErrors = true
            #endif
            database.shouldCacheStatements = true
            
            guard database.goodConnection else {
                if #available(iOS 10.0, *) {
                    os_log("Can not initialise bad database connection", type: .error)
                }
                return
            }
            
            isGoodConnection = true
            
            var schemaVersion = schemaManager.version(of: database)
            if #available(iOS 10.0, *) {
                os_log("Database version %u (expected version is %u)", type: .info, schemaVersion, schemaManager.expectedSchemaVersion)
            }
            
            if schemaVersion == 0 && !isReadOnlyConnection {
                if #available(iOS 10.0, *) {
                    os_log("Creating database schema", type: .info)
                }
                do {
                    try schemaManager.createSchema(in: database)
                    schemaVersion = schemaManager.version(of: database)
                } catch {
                    if #available(iOS 10.0, *) {
                        os_log("Failed to create database schema: %@", type: .fault, error as NSError)
                    }
                    fatalError("Failed to create database schema: \(error)")
                }
            }
            
            isCurrentSchemaVersion = schemaVersion == schemaManager.expectedSchemaVersion
        }
        
        if isGoodConnection && isCurrentSchemaVersion {
            return databaseQueue
        }
        
        databaseQueue.close()
        if isReadOnlyConnection {
            if #available(iOS 10.0, *) {
                os_log("Not initialising read-only database", type: .info)
            }
            return nil
        }
        
        if attemptNumber >= 3 {
            if #available(iOS 10.0, *) {
                os_log("Too many attempts; giving up", type: .info)
            }
            return nil
        }
        
        if #available(iOS 10.0, *) {
            os_log("Deleting database and trying again", type: .info)
        }
        try! factory.destroyDatabase()
        return makeDatabaseQueue(attemptNumber: attemptNumber + 1)
    }
}
