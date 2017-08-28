//
//  DatabaseManagerTests.swift
//  WaniKaniKitTests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB
import XCTest
@testable import WaniKaniKit

class DatabaseManagerTests: XCTestCase {
    
    private var databaseManager: DatabaseManager!
    
    override func setUp() {
        super.setUp()
        
        databaseManager = DatabaseManager(factory: EphemeralDatabaseConnectionFactory())
    }
    
    override func tearDown() {
        databaseManager.close()
        databaseManager = nil
        
        super.tearDown()
    }
    
    func testCreateSchema() {
        guard databaseManager.open() else {
            XCTFail("Failed to open database queue")
            return
        }
        
        guard let databaseQueue = databaseManager.databaseQueue else {
            XCTFail("Database queue opened successfully but databaseQueue nil?")
            return
        }
        
        databaseQueue.inDatabase { database in
            for table in Tables.all {
                do {
                    let name = try database.stringForQuery("SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?;", values: [table.name])
                    XCTAssertEqual(name, table.name)
                } catch {
                    XCTFail("Failed to query for table '\(table)': \(error)")
                }
            }
        }
    }
    
    func testEmptyReadOnlyDatabase() {
        XCTAssertFalse(databaseManager.open(readOnly: true))
    }
    
}
