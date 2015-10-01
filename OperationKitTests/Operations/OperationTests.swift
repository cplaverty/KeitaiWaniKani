//
//  OperationTests.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
@testable import OperationKit

class OperationTests: XCTestCase {
    
    func testRunNoConditions() {
        let operationQueue = createOperationQueue()
        
        let expectation = expectationWithDescription("operation")
        let operation = StubOperation()
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            expectation.fulfill()
            })
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.Finished)
        
        XCTAssertFalse(operation.ready)
        XCTAssertFalse(operation.executing)
        XCTAssertTrue(operation.finished)
        XCTAssertFalse(operation.cancelled)
    }
    
    func testRunFailure() {
        let operationQueue = createOperationQueue()
        
        let expectation = expectationWithDescription("operation")
        let operation = StubOperation(shouldFail: true)
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
            expectation.fulfill()
            })
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.Finished)
        
        XCTAssertFalse(operation.ready)
        XCTAssertFalse(operation.executing)
        XCTAssertTrue(operation.finished)
        XCTAssertFalse(operation.cancelled)
    }
    
    func testRunSatisfiedCondition() {
        let operationQueue = createOperationQueue()
        
        let expectation = expectationWithDescription("operation")
        let operation = StubOperation()
        operation.addCondition(AlwaysSatisfiedCondition())
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            expectation.fulfill()
            })
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.Finished)
        
        XCTAssertFalse(operation.ready)
        XCTAssertFalse(operation.executing)
        XCTAssertTrue(operation.finished)
        XCTAssertFalse(operation.cancelled)
    }
    
    func testRunFailedCondition() {
        let operationQueue = createOperationQueue()
        
        let expectation = expectationWithDescription("operation")
        let operation = StubOperation()
        operation.addCondition(AlwaysFailedCondition())
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertFalse(errors.isEmpty, "Expected condition errors on operation finish")
            expectation.fulfill()
            })
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.CancelledAfterReady)
        
        XCTAssertFalse(operation.ready)
        XCTAssertFalse(operation.executing)
        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
    }
    
    func testCancelBeforeStart() {
        let operationQueue = createOperationQueue()
        
        let expectation = expectationWithDescription("operation")
        let operation = StubOperation()
        operation.cancel()
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            expectation.fulfill()
            })
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        
        XCTAssertFalse(operation.ready)
        XCTAssertFalse(operation.executing)
        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
    }
    
    func testCancelAfterStart() {
        let operationQueue = createOperationQueue()
        
        let expectation = expectationWithDescription("operation")
        let operation = StubOperation(immediatelyFinish: false)
        operation.addObserver(BlockObserver(
            startHandler: { _ in
                let when = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
                dispatch_after(when, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
                    print("Cancelling operation")
                    operation.cancel()
                }
            },
            finishHandler: { _, errors in
                XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
                expectation.fulfill()
        }))
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        NSThread.sleepForTimeInterval(0.5)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.Finished)
        
        XCTAssertFalse(operation.ready)
        XCTAssertFalse(operation.executing)
        XCTAssertTrue(operation.finished)
        XCTAssertFalse(operation.cancelled)
    }
    
}
