//
//  BlockOperationTests.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
@testable import OperationKit

class BlockOperationTests: XCTestCase {
    
    func testRunBlock() {
        let operationQueue = createOperationQueue()
        
        var wasRun = false
        let expectation = expectationWithDescription("operation")
        let operation = BlockOperation {
            wasRun = true
        }
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            expectation.fulfill()
            })
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(1, handler: nil)
        
        XCTAssertTrue(wasRun)
        XCTAssertFalse(operation.ready)
        XCTAssertFalse(operation.executing)
        XCTAssertTrue(operation.finished)
        XCTAssertFalse(operation.cancelled)
    }
    
    func testCancelBeforeStart() {
        let operationQueue = createOperationQueue()
        
        var wasRun = false
        let expectation = expectationWithDescription("operation")
        let operation = BlockOperation {
            wasRun = true
        }
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            expectation.fulfill()
            })
        operation.cancel()
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(1, handler: nil)
        
        XCTAssertFalse(wasRun)
        XCTAssertFalse(operation.ready)
        XCTAssertFalse(operation.executing)
        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
    }
    
}
