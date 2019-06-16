//
//  VirtualTableTests.swift
//  WaniKaniKitTests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import XCTest
@testable import WaniKaniKit

private class TestVirtualTableNoPrimaryKey: VirtualTable {
    let intColumn = Column(name: "int_column", rank: 10)
    let floatColumn = Column(name: "float_column")
    let numericColumn = Column(name: "numeric_column")
    
    init() {
        super.init(name: "test")
    }
}

private class TestVirtualTableMultipleIndexes: VirtualTable {
    let intColumn = Column(name: "int_column", rank: 10)
    let floatColumn = Column(name: "float_column")
    let numericColumn = Column(name: "numeric_column")
    
    init() {
        super.init(name: "test", prefixIndexes: [2, 4])
    }
}

class VirtualTableTests: XCTestCase {
    
    func testCreateVirtualTableStatement() {
        let expectedCreateStmt = """
            CREATE VIRTUAL TABLE test USING fts5(int_column, float_column, numeric_column, tokenize = porter);
            INSERT INTO test(test, rank) VALUES('rank', 'bm25(10.0, 1.0, 1.0)');
            """
        let createStmt = TestVirtualTableNoPrimaryKey().sqlStatement
        
        XCTAssertEqual(createStmt, expectedCreateStmt)
    }
    
    func testCreateVirtualTableStatementMultipleIndexes() {
        let expectedCreateStmt = """
            CREATE VIRTUAL TABLE test USING fts5(int_column, float_column, numeric_column, prefix = '2,4', tokenize = porter);
            INSERT INTO test(test, rank) VALUES('rank', 'bm25(10.0, 1.0, 1.0)');
            """
        let createStmt = TestVirtualTableMultipleIndexes().sqlStatement
        
        XCTAssertEqual(createStmt, expectedCreateStmt)
    }

}
