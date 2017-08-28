//
//  EphemeralDatabaseConnectionFactory.swift
//  WaniKaniKitTests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB
import WaniKaniKit

enum EphemeralDatabaseStorageType {
    case memory, file
}

class EphemeralDatabaseConnectionFactory: DatabaseConnectionFactory {
    private let path: String?
    
    init(databaseStorageType: EphemeralDatabaseStorageType = .memory) {
        switch databaseStorageType {
        case .memory:
            path = nil
        case .file:
            path = ""
        }
    }
    
    func makeDatabaseQueue() -> FMDatabaseQueue? {
        return FMDatabaseQueue(path: nil)
    }
    
    func destroyDatabase() throws {
        fatalError()
    }
}
