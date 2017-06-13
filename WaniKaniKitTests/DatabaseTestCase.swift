//
//  DatabaseTestCase.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
import FMDB
import OHHTTPStubs
@testable import WaniKaniKit

class DatabaseTestCase: XCTestCase {
    
    var useDatabaseFile: Bool {
        return false
    }
    
    lazy var stubDownloadStrategy: DownloadStrategy = {
        var strategy = DownloadStrategy(databaseQueue: self.databaseQueue, batchSizes: BatchSizes(radicals: 100, kanji: 100, vocabulary: 100))
        strategy.maxLevel = 100
        return strategy
    }()
    
    var databaseQueue: FMDatabaseQueue! = nil
    var databasePath: URL? = nil
    
    override func setUp() {
        super.setUp()
        
        if useDatabaseFile {
            let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            databasePath = tempDirectory.appendingPathComponent("\(UUID().uuidString).sqlite")
            print("Using file-based SQLite store: \(databasePath!)")
        } else {
            print("Using in-memory SQLite store")
        }
        
        databaseQueue = FMDatabaseQueue(path: databasePath?.path)
        
        databaseQueue.inDatabase { database in
            XCTAssertNotNil(database, "Database is nil!")
            do {
                try WaniKaniAPI.createTables(in: database)
            } catch {
                XCTFail("Could not create tables in database due to error: \(error)")
            }
        }
    }
    
    override func tearDown() {
        super.tearDown()
        databaseQueue = nil
        
        if let databasePath = databasePath?.path {
            print("Deleting file-based SQLite store")
            _ = try? FileManager.default.removeItem(atPath: databasePath)
        }
        databasePath = nil
        
        OHHTTPStubs.removeAllStubs()
    }
    
}
