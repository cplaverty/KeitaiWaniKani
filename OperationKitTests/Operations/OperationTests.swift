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
        
        let operation = StubOperation()
        keyValueObservingExpectation(for: operation, keyPath: "isFinished", expectedValue: true)
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        operationQueue.addOperation(operation)
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.Finished)
        
        XCTAssertFalse(operation.isReady)
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
        XCTAssertFalse(operation.isCancelled)
    }
    
    func testRunFailure() {
        let operationQueue = createOperationQueue()
        
        let operation = StubOperation(shouldFail: true)
        keyValueObservingExpectation(for: operation, keyPath: "isFinished", expectedValue: true)
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
            })
        operationQueue.addOperation(operation)
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.Finished)
        
        XCTAssertFalse(operation.isReady)
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
        XCTAssertFalse(operation.isCancelled)
    }
    
    func testRunSatisfiedCondition() {
        let operationQueue = createOperationQueue()
        
        let operation = StubOperation()
        keyValueObservingExpectation(for: operation, keyPath: "isFinished", expectedValue: true)
        operation.addCondition(AlwaysSatisfiedCondition())
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        operationQueue.addOperation(operation)
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.Finished)
        
        XCTAssertFalse(operation.isReady)
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
        XCTAssertFalse(operation.isCancelled)
    }
    
    func testRunFailedCondition() {
        let operationQueue = createOperationQueue()
        
        let operation = StubOperation()
        keyValueObservingExpectation(for: operation, keyPath: "isFinished", expectedValue: true)
        operation.addCondition(AlwaysFailedCondition())
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertFalse(errors.isEmpty, "Expected condition errors on operation finish")
            })
        operationQueue.addOperation(operation)
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.CancelledAfterReady)
        
        XCTAssertFalse(operation.isReady)
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
        XCTAssertTrue(operation.isCancelled)
    }
    
    func testCancelBeforeStart() {
        let operationQueue = createOperationQueue()
        
        let operation = StubOperation()
        keyValueObservingExpectation(for: operation, keyPath: "isFinished", expectedValue: true)
        operation.cancel()
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        operationQueue.addOperation(operation)
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        
        XCTAssertFalse(operation.isReady)
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
        XCTAssertTrue(operation.isCancelled)
    }
    
    func testCancelAfterStart() {
        let operationQueue = createOperationQueue()
        
        let operation = StubOperation(immediatelyFinish: false)
        keyValueObservingExpectation(for: operation, keyPath: "isFinished", expectedValue: true)
        operation.addObserver(BlockObserver(
            startHandler: { _ in
                let when = DispatchTime.now() + 0.5
                DispatchQueue.global(qos: DispatchQoS.QoSClass.default).asyncAfter(deadline: when) {
                    print("Cancelling operation")
                    operation.cancel()
                }
            },
            finishHandler: { _, errors in
                XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
        }))
        operationQueue.addOperation(operation)
        waitForExpectations(timeout: 5, handler: nil)
        
        Thread.sleep(forTimeInterval: 0.5)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.Finished)
        
        XCTAssertFalse(operation.isReady)
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
        XCTAssertTrue(operation.isCancelled)
    }
    
}
