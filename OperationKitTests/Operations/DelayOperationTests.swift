//
//  DelayOperationTests.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
@testable import OperationKit

class DelayOperationTests: XCTestCase {
    
    func testRunWithInterval() {
        let operationQueue = createOperationQueue()
        
        let interval: NSTimeInterval = 0.5
        let start = NSDate()
        var delay: NSTimeInterval? = nil
        let expectation = expectationWithDescription("operation")
        let operation = DelayOperation(interval: interval)
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            delay = -start.timeIntervalSinceNow
            expectation.fulfill()
            })
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(interval + 0.5, handler: nil)
        
        XCTAssertGreaterThanOrEqual(delay!, interval)
        XCTAssertFalse(operation.ready)
        XCTAssertFalse(operation.executing)
        XCTAssertTrue(operation.finished)
        XCTAssertFalse(operation.cancelled)
    }
    
    func testRunWithDate() {
        let operationQueue = createOperationQueue()
        
        let interval: NSTimeInterval = 0.5
        let start = NSDate()
        let end = NSDate().dateByAddingTimeInterval(interval)
        var delay: NSTimeInterval? = nil
        let expectation = expectationWithDescription("operation")
        let operation = DelayOperation(until: end)
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            delay = -start.timeIntervalSinceNow
            expectation.fulfill()
            })
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(interval + 0.5, handler: nil)
        
        XCTAssertGreaterThanOrEqual(delay!, interval)
        XCTAssertFalse(operation.ready)
        XCTAssertFalse(operation.executing)
        XCTAssertTrue(operation.finished)
        XCTAssertFalse(operation.cancelled)
    }
    
    func testCancelBeforeStart() {
        let operationQueue = createOperationQueue()
        
        let interval: NSTimeInterval = 0.5
        let start = NSDate()
        var delay: NSTimeInterval? = nil
        let expectation = expectationWithDescription("operation")
        let operation = DelayOperation(interval: interval)
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            delay = -start.timeIntervalSinceNow
            expectation.fulfill()
            })
        operation.cancel()
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(interval + 0.5, handler: nil)
        
        XCTAssertLessThan(delay!, interval)
        XCTAssertFalse(operation.ready)
        XCTAssertFalse(operation.executing)
        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
    }
    
    func testCancelAfterStart() {
        let operationQueue = createOperationQueue()
        
        let interval: NSTimeInterval = 0.5
        let start = NSDate()
        var delay: NSTimeInterval? = nil
        let expectation = expectationWithDescription("operation")
        let operation = DelayOperation(interval: interval)
        operation.addObserver(BlockObserver(
            startHandler: { _ in
                let when = dispatch_time(DISPATCH_TIME_NOW, Int64(interval / 2 * Double(NSEC_PER_SEC)))
                dispatch_after(when, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
                    print("Cancelling operation")
                    delay = -start.timeIntervalSinceNow
                    operation.cancel()
                }
            },
            finishHandler: { _, errors in
                XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
                expectation.fulfill()
        }))
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(interval + 0.5, handler: nil)
        
        XCTAssertLessThan(delay!, interval)
        XCTAssertFalse(operation.ready)
        XCTAssertFalse(operation.executing)
        XCTAssertTrue(operation.finished)
        XCTAssertFalse(operation.cancelled)
    }
    
}
