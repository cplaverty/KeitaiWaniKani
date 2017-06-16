//
//  BlockOperationTests.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
@testable import OperationKit

class BlockOperationTests: XCTestCase {
    typealias Operation = OperationKit.Operation
    
    func testRunBlock() {
        let operationQueue = makeOperationQueue()
        
        var wasRun = false
        let operation = OperationKit.BlockOperation {
            wasRun = true
        }
        keyValueObservingExpectation(for: operation, keyPath: "isFinished", expectedValue: true)
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        operationQueue.addOperation(operation)
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertTrue(wasRun)
        XCTAssertFalse(operation.isReady)
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
        XCTAssertFalse(operation.isCancelled)
    }
    
    func testCancelBeforeStart() {
        let operationQueue = makeOperationQueue()
        
        var wasRun = false
        let operation = OperationKit.BlockOperation {
            wasRun = true
        }
        keyValueObservingExpectation(for: operation, keyPath: "isFinished", expectedValue: true)
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        operation.cancel()
        operationQueue.addOperation(operation)
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertFalse(wasRun)
        XCTAssertFalse(operation.isReady)
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
        XCTAssertTrue(operation.isCancelled)
    }
    
}
