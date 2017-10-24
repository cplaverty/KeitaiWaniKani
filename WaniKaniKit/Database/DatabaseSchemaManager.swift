//
//  DatabaseSchemaManager.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB
import os

enum DatabaseSchemaManagerError: Error {
    case invalidSchemaVersion(UInt32)
}

public class DatabaseSchemaManager {
    public let expectedSchemaVersion: UInt32 = 3
    
    public func version(of database: FMDatabase) -> UInt32 {
        return database.userVersion
    }
    
    private func setVersion(of database: FMDatabase, to version: UInt32) {
        database.userVersion = version
    }
    
    public func createSchema(in database: FMDatabase) throws {
        let schemaVersion = version(of: database)
        if schemaVersion == expectedSchemaVersion {
            return
        }
        
        guard schemaVersion == 0 else {
            throw DatabaseSchemaManagerError.invalidSchemaVersion(schemaVersion)
        }
        
        // Set version to an invalid version so that, if something fails while we're creating the schema, it will delete and retry on next launch
        setVersion(of: database, to: .max)
        
        try database.executeUpdate("PRAGMA auto_vacuum = FULL", values: nil)
        
        for table in Tables.all {
            try table.create(in: database)
        }
        
        if #available(iOS 10.0, *) {
            os_log("Setting database version %u", type: .debug, expectedSchemaVersion)
        }
        setVersion(of: database, to: expectedSchemaVersion)
    }
}

private extension TableProtocol {
    func create(in database: FMDatabase) throws {
        if #available(iOS 10.0, *) {
            os_log("Creating table %@", type: .debug, name)
        }
        if !database.executeStatements(sqlStatement) {
            throw database.lastError()
        }
    }
}
