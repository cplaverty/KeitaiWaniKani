//
//  RetryOperationTests.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
@testable import OperationKit

class RetryOperationTests: XCTestCase {
    typealias Operation = OperationKit.Operation
    
    func testRunSuccessNoRetry() {
        let operationQueue = makeOperationQueue()
        
        var operationsCreated: [StubOperation] = []
        let createOperation: () -> StubOperation = {
            let op = StubOperation(immediatelyFinish: true, shouldFail: false)
            operationsCreated.append(op)
            return op
        }
        let operation = RetryOperation<StubOperation>(maximumRetryCount: 2, createOperation: createOperation()) { _, _ -> Bool in
            XCTFail("Did not expect shouldRetry closure to be called: operation was successful")
            return true
        }
        keyValueObservingExpectation(for: operation, keyPath: "isFinished", expectedValue: true)
        operation.addObserver(BlockObserver(
            produceHandler: { parent, child in
                XCTFail("Expected RetryOperation not to produce any children, but it produced \(child)")
            },
            finishHandler: { _, errors in
                XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            }
            ))
        operationQueue.addOperation(operation)
        waitForExpectations(timeout: 15, handler: nil)
        
        XCTAssertEqual(operationsCreated.count, 1)
        XCTAssertTrue(operation.isFinished)
        XCTAssertTrue(operationsCreated.first!.isFinished)
    }
    
    func testRunFailureRetry() {
        let operationQueue = makeOperationQueue()
        
        var operationsCreated: [StubOperation] = []
        let createOperation: () -> StubOperation = {
            let op = StubOperation(immediatelyFinish: true, shouldFail: true)
            operationsCreated.append(op)
            return op
        }
        let operation = RetryOperation<StubOperation>(maximumRetryCount: 2, createOperation: createOperation()) { _, _ -> Bool in
            return true
        }
        keyValueObservingExpectation(for: operation, keyPath: "isFinished", expectedValue: true)
        operation.addObserver(BlockObserver(
            finishHandler: { _, errors in
                XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
            }
            ))
        operationQueue.addOperation(operation)
        waitForExpectations(timeout: 15, handler: nil)
        
        XCTAssertEqual(operationsCreated.count, 3)
        XCTAssertTrue(operation.isFinished, "Expected retry operation to be finished")
        XCTAssertTrue(operationsCreated.reduce(true) { $0 && $1.isFinished }, "Expected all child operations to be finished")
    }
    
    func testCancelBeforeStart() {
        let operationQueue = makeOperationQueue()
        
        var operationsCreated: [StubOperation] = []
        let createOperation: () -> StubOperation = {
            let op = StubOperation(immediatelyFinish: true, shouldFail: false)
            operationsCreated.append(op)
            return op
        }
        let operation = RetryOperation<StubOperation>(maximumRetryCount: 2, createOperation: createOperation()) { _, _ -> Bool in
            XCTFail("Did not expect shouldRetry closure to be called: operation was successful")
            return true
        }
        keyValueObservingExpectation(for: operation, keyPath: "isFinished", expectedValue: true)
        operation.addObserver(BlockObserver(
            produceHandler: { parent, child in
                XCTFail("Expected RetryOperation not to produce any children, but it produced \(child)")
            },
            finishHandler: { _, errors in
                XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            }
            ))
        operation.cancel()
        operationQueue.addOperation(operation)
        waitForExpectations(timeout: 15, handler: nil)
        
        XCTAssertEqual(operationsCreated.count, 1)
        
        XCTAssertFalse(operation.isReady)
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
        XCTAssertTrue(operation.isCancelled)
        
        XCTAssertFalse(operationsCreated.first!.isReady)
        XCTAssertFalse(operationsCreated.first!.isExecuting)
        XCTAssertTrue(operationsCreated.first!.isFinished)
        XCTAssertTrue(operationsCreated.first!.isCancelled)
        XCTAssertFalse(operationsCreated.first!.wasRun)
    }
    
    func testCancelAfterStart() {
        let operationQueue = makeOperationQueue()
        
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
        let operation = RetryOperation<StubOperation>(maximumRetryCount: 2, createOperation: createOperation()) { _, _ -> Bool in
            return true
        }
        keyValueObservingExpectation(for: operation, keyPath: "isFinished", expectedValue: true)
        operation.addObserver(BlockObserver(
            startHandler: { _ in
                let when = DispatchTime.now() + 0.5
                DispatchQueue.global(qos: .default).asyncAfter(deadline: when) {
                    print("Cancelling operation")
                    operation.cancel()
                }
            },
            finishHandler: { _, errors in
                XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
        }))
        operationQueue.addOperation(operation)
        waitForExpectations(timeout: 15, handler: nil)
        
        XCTAssertEqual(operationsCreated.count, 2)
        
        XCTAssertEqual(childOperation1.stateTransitions, OperationWorkflows.finished)
        XCTAssertEqual(childOperation2.stateTransitions, OperationWorkflows.finished)
        XCTAssertEqual(childOperation3.stateTransitions, OperationWorkflows.new)
        
        XCTAssertFalse(operation.isReady)
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
        XCTAssertTrue(operation.isCancelled)
        
        XCTAssertTrue(childOperation1.wasRun)
        XCTAssertFalse(childOperation1.isReady)
        XCTAssertFalse(childOperation1.isExecuting)
        XCTAssertTrue(childOperation1.isFinished)
        XCTAssertFalse(childOperation1.isCancelled)
        
        XCTAssertTrue(childOperation2.wasRun)
        XCTAssertFalse(childOperation2.isReady)
        XCTAssertFalse(childOperation2.isExecuting)
        XCTAssertTrue(childOperation2.isFinished)
        XCTAssertTrue(childOperation2.isCancelled)
        
        XCTAssertFalse(childOperation3.wasRun)
        XCTAssertFalse(childOperation3.isReady)
        XCTAssertFalse(childOperation3.isExecuting)
        XCTAssertFalse(childOperation3.isFinished)
        XCTAssertFalse(childOperation3.isCancelled)
    }
    
}
