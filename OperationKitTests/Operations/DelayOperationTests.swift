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
        
        let interval: TimeInterval = 0.5
        let start = Date()
        var delay: TimeInterval? = nil
        let operation = DelayOperation(interval: interval)
        keyValueObservingExpectation(for: operation, keyPath: "isFinished", expectedValue: true)
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            delay = -start.timeIntervalSinceNow
            })
        operationQueue.addOperation(operation)
        waitForExpectations(timeout: interval + 0.5, handler: nil)
        
        XCTAssertGreaterThanOrEqual(delay!, interval)
        XCTAssertFalse(operation.isReady)
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
        XCTAssertFalse(operation.isCancelled)
    }
    
    func testRunWithDate() {
        let operationQueue = createOperationQueue()
        
        let interval: TimeInterval = 0.5
        let start = Date()
        let end = Date().addingTimeInterval(interval)
        var delay: TimeInterval? = nil
        let operation = DelayOperation(until: end)
        keyValueObservingExpectation(for: operation, keyPath: "isFinished", expectedValue: true)
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            delay = -start.timeIntervalSinceNow
            })
        operationQueue.addOperation(operation)
        waitForExpectations(timeout: interval + 0.5, handler: nil)
        
        XCTAssertGreaterThanOrEqual(delay!, interval)
        XCTAssertFalse(operation.isReady)
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
        XCTAssertFalse(operation.isCancelled)
    }
    
    func testCancelBeforeStart() {
        let operationQueue = createOperationQueue()
        
        let interval: TimeInterval = 0.5
        let start = Date()
        var delay: TimeInterval? = nil
        let operation = DelayOperation(interval: interval)
        keyValueObservingExpectation(for: operation, keyPath: "isFinished", expectedValue: true)
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            delay = -start.timeIntervalSinceNow
            })
        operation.cancel()
        operationQueue.addOperation(operation)
        waitForExpectations(timeout: interval + 0.5, handler: nil)
        
        XCTAssertLessThan(delay!, interval)
        XCTAssertFalse(operation.isReady)
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
        XCTAssertTrue(operation.isCancelled)
    }
    
    func testCancelAfterStart() {
        let operationQueue = createOperationQueue()
        
        let interval: TimeInterval = 0.5
        let start = Date()
        var delay: TimeInterval? = nil
        let operation = DelayOperation(interval: interval)
        keyValueObservingExpectation(for: operation, keyPath: "isFinished", expectedValue: true)
        operation.addObserver(BlockObserver(
            startHandler: { _ in
                let when = DispatchTime.now() + interval / 2
                DispatchQueue.global(qos: DispatchQoS.QoSClass.default).asyncAfter(deadline: when) {
                    print("Cancelling operation")
                    delay = -start.timeIntervalSinceNow
                    operation.cancel()
                }
            },
            finishHandler: { _, errors in
                XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
        }))
        operationQueue.addOperation(operation)
        waitForExpectations(timeout: interval + 0.5, handler: nil)
        
        XCTAssertLessThan(delay!, interval)
        XCTAssertFalse(operation.isReady)
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
        XCTAssertTrue(operation.isCancelled)
    }
    
}
