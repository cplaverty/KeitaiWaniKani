//
//  RetryOperationTests.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
@testable import OperationKit

class RetryOperationTests: XCTestCase {
    
    func testRunSuccessNoRetry() {
        let operationQueue = createOperationQueue()
        
        var operationsCreated: [StubOperation] = []
        let createOperation: () -> StubOperation = {
            let op = StubOperation(immediatelyFinish: true, shouldFail: false)
            operationsCreated.append(op)
            return op
        }
        let expectation = expectationWithDescription("operation")
        let operation = RetryOperation<StubOperation>(maximumRetryCount: 2, createOperation: createOperation()) { _, _ -> Bool in
            XCTFail("Did not expect shouldRetry closure to be called: operation was successful")
            return true
        }
        operation.addObserver(BlockObserver(
            produceHandler: { parent, child in
                XCTFail("Expected RetryOperation not to produce any children, but it produced \(child)")
            },
            finishHandler: { _, errors in
                XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
                expectation.fulfill()
            }
            ))
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertEqual(operationsCreated.count, 1)
        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operationsCreated.first!.finished)
    }
    
    func testRunFailureRetry() {
        let operationQueue = createOperationQueue()
        
        var operationsCreated: [StubOperation] = []
        let createOperation: () -> StubOperation = {
            let op = StubOperation(immediatelyFinish: true, shouldFail: true)
            operationsCreated.append(op)
            return op
        }
        let expectation = expectationWithDescription("operation")
        let operation = RetryOperation<StubOperation>(maximumRetryCount: 2, createOperation: createOperation()) { _, _ -> Bool in
            return true
        }
        operation.addObserver(BlockObserver(
            finishHandler: { _, errors in
                XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
                expectation.fulfill()
            }
            ))
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertEqual(operationsCreated.count, 3)
        XCTAssertTrue(operation.finished, "Expected retry operation to be finished")
        XCTAssertTrue(operationsCreated.reduce(true) { $0 && $1.finished }.boolValue, "Expected all child operations to be finished")
    }
    
    func testCancelBeforeStart() {
        let operationQueue = createOperationQueue()
        
        var operationsCreated: [StubOperation] = []
        let createOperation: () -> StubOperation = {
            let op = StubOperation(immediatelyFinish: true, shouldFail: false)
            operationsCreated.append(op)
            return op
        }
        let expectation = expectationWithDescription("operation")
        let operation = RetryOperation<StubOperation>(maximumRetryCount: 2, createOperation: createOperation()) { _, _ -> Bool in
            XCTFail("Did not expect shouldRetry closure to be called: operation was successful")
            return true
        }
        operation.addObserver(BlockObserver(
            produceHandler: { parent, child in
                XCTFail("Expected RetryOperation not to produce any children, but it produced \(child)")
            },
            finishHandler: { _, errors in
                XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
                expectation.fulfill()
            }
            ))
        operation.cancel()
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertEqual(operationsCreated.count, 1)

        XCTAssertFalse(operation.ready)
        XCTAssertFalse(operation.executing)
        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)

        XCTAssertFalse(operationsCreated.first!.ready)
        XCTAssertFalse(operationsCreated.first!.executing)
        XCTAssertTrue(operationsCreated.first!.finished)
        XCTAssertTrue(operationsCreated.first!.cancelled)
        XCTAssertFalse(operationsCreated.first!.wasRun)
    }
    
    func testCancelAfterStart() {
        let operationQueue = createOperationQueue()

        var operationsCreated: [StubOperation] = []
        let childOperation1 = StubOperation(immediatelyFinish: true, shouldFail: true)
        let childOperation2 = StubOperation(immediatelyFinish: false, shouldFail: true)
        let childOperation3 = StubOperation(immediatelyFinish: true, shouldFail: true)
        var operationsToProduce: [StubOperation] = [childOperation3, childOperation2, childOperation1]
        let createOperation: () -> StubOperation = {
            let op = operationsToProduce.popLast()!
            operationsCreated.append(op)
            return op
        }
        let expectation = expectationWithDescription("operation")
        let operation = RetryOperation<StubOperation>(maximumRetryCount: 2, createOperation: createOperation()) { _, _ -> Bool in
            return true
        }
        operation.addObserver(BlockObserver(
            startHandler: { _ in
                let when = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
                dispatch_after(when, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
                    print("Cancelling operation")
                    operation.cancel()
                }
            },
            finishHandler: { _, errors in
                XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
                expectation.fulfill()
        }))
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertEqual(operationsCreated.count, 2)
        
        XCTAssertEqual(childOperation1.stateTransitions, OperationWorkflows.Finished)
        XCTAssertEqual(childOperation2.stateTransitions, OperationWorkflows.Finished)
        XCTAssertEqual(childOperation3.stateTransitions, OperationWorkflows.New)
        
        XCTAssertFalse(operation.ready)
        XCTAssertFalse(operation.executing)
        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
        
        XCTAssertTrue(childOperation1.wasRun)
        XCTAssertFalse(childOperation1.ready)
        XCTAssertFalse(childOperation1.executing)
        XCTAssertTrue(childOperation1.finished)
        XCTAssertFalse(childOperation1.cancelled)
        
        XCTAssertTrue(childOperation2.wasRun)
        XCTAssertFalse(childOperation2.ready)
        XCTAssertFalse(childOperation2.executing)
        XCTAssertTrue(childOperation2.finished)
        XCTAssertTrue(childOperation2.cancelled)
        
        XCTAssertFalse(childOperation3.wasRun)
        XCTAssertFalse(childOperation3.ready)
        XCTAssertFalse(childOperation3.executing)
        XCTAssertFalse(childOperation3.finished)
        XCTAssertFalse(childOperation3.cancelled)
    }
    
}
