//
//  GroupOperationTests.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
@testable import OperationKit

class GroupOperationTests: XCTestCase {
    
    func testRunNoConditions() {
        let operationQueue = createOperationQueue()
        
        let childOperation1 = StubOperation()
        childOperation1.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        
        let childOperation2 = StubOperation()
        childOperation2.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        childOperation2.addDependency(childOperation1)
        
        let expectation = expectationWithDescription("operation")
        let operation = StubGroupOperation(operations: childOperation1, childOperation2)
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            expectation.fulfill()
            })
        
        NSThread.sleepForTimeInterval(0.5)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.New)
        XCTAssertEqual(childOperation1.stateTransitions, OperationWorkflows.Pending)
        XCTAssertEqual(childOperation2.stateTransitions, OperationWorkflows.Pending)
        
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.Finished)
        XCTAssertEqual(childOperation1.stateTransitions, OperationWorkflows.Finished)
        XCTAssertEqual(childOperation2.stateTransitions, OperationWorkflows.Finished)
        
        XCTAssertFalse(operation.ready)
        XCTAssertFalse(operation.executing)
        XCTAssertTrue(operation.finished)
        XCTAssertFalse(operation.cancelled)
        
        XCTAssertTrue(childOperation1.wasRun)
        XCTAssertFalse(childOperation1.ready)
        XCTAssertFalse(childOperation1.executing)
        XCTAssertTrue(childOperation1.finished)
        XCTAssertFalse(childOperation1.cancelled)
        
        XCTAssertTrue(childOperation2.wasRun)
        XCTAssertFalse(childOperation2.ready)
        XCTAssertFalse(childOperation2.executing)
        XCTAssertTrue(childOperation2.finished)
        XCTAssertFalse(childOperation2.cancelled)
    }
    
    func testCancelBeforeStart() {
        let operationQueue = createOperationQueue()
        
        let childOperation1 = StubOperation()
        childOperation1.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        
        let childOperation2 = StubOperation()
        childOperation2.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        childOperation2.addDependency(childOperation1)
        
        let expectation = expectationWithDescription("operation")
        let operation = StubGroupOperation(operations: childOperation1, childOperation2)
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            expectation.fulfill()
            })
        
        NSThread.sleepForTimeInterval(0.5)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.New)
        XCTAssertEqual(childOperation1.stateTransitions, OperationWorkflows.Pending)
        XCTAssertEqual(childOperation2.stateTransitions, OperationWorkflows.Pending)
        
        operation.cancel()
        
        NSThread.sleepForTimeInterval(0.5)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.New)
        XCTAssertEqual(childOperation1.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        XCTAssertEqual(childOperation2.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        XCTAssertEqual(childOperation1.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        XCTAssertEqual(childOperation2.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        
        XCTAssertFalse(operation.ready)
        XCTAssertFalse(operation.executing)
        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
        
        XCTAssertFalse(childOperation1.wasRun)
        XCTAssertFalse(childOperation1.ready)
        XCTAssertFalse(childOperation1.executing)
        XCTAssertTrue(childOperation1.finished)
        XCTAssertTrue(childOperation1.cancelled)
        
        XCTAssertFalse(childOperation2.wasRun)
        XCTAssertFalse(childOperation2.ready)
        XCTAssertFalse(childOperation2.executing)
        XCTAssertTrue(childOperation2.finished)
        XCTAssertTrue(childOperation2.cancelled)
    }
    
    func testCancelAfterStart() {
        let operationQueue = createOperationQueue()
        
        let childOperation1 = StubOperation()
        childOperation1.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        
        let childOperation2 = StubOperation(immediatelyFinish: false)
        childOperation2.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        childOperation2.addDependency(childOperation1)
        
        let childOperation3 = StubOperation()
        childOperation3.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        childOperation3.addDependency(childOperation2)
        
        let expectation = expectationWithDescription("operation")
        let operation = StubGroupOperation(operations: childOperation1, childOperation2, childOperation3)
        operation.addObserver(BlockObserver(
            startHandler: { _ in
                let when = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
                dispatch_after(when, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
                    XCTAssertEqual(operation.stateTransitions, OperationWorkflows.Executing)
                    XCTAssertEqual(childOperation1.stateTransitions, OperationWorkflows.Finished)
                    XCTAssertEqual(childOperation2.stateTransitions, OperationWorkflows.Executing)
                    XCTAssertEqual(childOperation3.stateTransitions, OperationWorkflows.Pending)
                    
                    XCTAssertFalse(operation.ready)
                    XCTAssertTrue(operation.executing)
                    XCTAssertFalse(operation.finished)
                    XCTAssertFalse(operation.cancelled)
                    
                    XCTAssertTrue(childOperation1.wasRun)
                    XCTAssertFalse(childOperation1.ready)
                    XCTAssertFalse(childOperation1.executing)
                    XCTAssertTrue(childOperation1.finished)
                    XCTAssertFalse(childOperation1.cancelled)
                    
                    XCTAssertTrue(childOperation2.wasRun)
                    XCTAssertFalse(childOperation2.ready)
                    XCTAssertTrue(childOperation2.executing)
                    XCTAssertFalse(childOperation2.finished)
                    XCTAssertFalse(childOperation2.cancelled)
                    
                    XCTAssertFalse(childOperation3.wasRun)
                    XCTAssertFalse(childOperation3.ready)
                    XCTAssertFalse(childOperation3.executing)
                    XCTAssertFalse(childOperation3.finished)
                    XCTAssertFalse(childOperation3.cancelled)
                    
                    print("Cancelling operation")
                    operation.cancel()
                }
            },
            finishHandler: { _, errors in
                XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
                expectation.fulfill()
        }))
        
        NSThread.sleepForTimeInterval(0.5)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.New)
        XCTAssertEqual(childOperation1.stateTransitions, OperationWorkflows.Pending)
        XCTAssertEqual(childOperation2.stateTransitions, OperationWorkflows.Pending)
        
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        NSThread.sleepForTimeInterval(0.5)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.Finished)
        XCTAssertEqual(childOperation1.stateTransitions, OperationWorkflows.Finished)
        XCTAssertEqual(childOperation2.stateTransitions, OperationWorkflows.Finished)
        XCTAssertEqual(childOperation3.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        
        XCTAssertFalse(operation.ready)
        XCTAssertFalse(operation.executing)
        XCTAssertTrue(operation.finished)
        XCTAssertFalse(operation.cancelled)
        
        XCTAssertTrue(childOperation1.wasRun)
        XCTAssertFalse(childOperation1.ready)
        XCTAssertFalse(childOperation1.executing)
        XCTAssertTrue(childOperation1.finished)
        XCTAssertFalse(childOperation1.cancelled)
        
        XCTAssertTrue(childOperation2.wasRun)
        XCTAssertFalse(childOperation2.ready)
        XCTAssertFalse(childOperation2.executing)
        XCTAssertTrue(childOperation2.finished)
        XCTAssertFalse(childOperation2.cancelled)
        
        XCTAssertFalse(childOperation3.wasRun)
        XCTAssertFalse(childOperation3.ready)
        XCTAssertFalse(childOperation3.executing)
        XCTAssertTrue(childOperation3.finished)
        XCTAssertTrue(childOperation3.cancelled)
    }
    
    func testRunNestedNoConditions() {
        let operationQueue = createOperationQueue()
        
        let childOperation1_1 = StubOperation()
        childOperation1_1.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        
        let childOperation1_2 = StubOperation()
        childOperation1_2.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        childOperation1_2.addDependency(childOperation1_1)
        
        let nested1 = StubGroupOperation(operations: childOperation1_1, childOperation1_2)
        nested1.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        
        let childOperation2_1 = StubOperation()
        childOperation2_1.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        
        let childOperation2_2 = StubOperation()
        childOperation2_2.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        childOperation2_2.addDependency(childOperation2_1)
        
        let nested2 = StubGroupOperation(operations: childOperation2_1, childOperation2_2)
        nested2.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        
        let expectation = expectationWithDescription("operation")
        let operation = StubGroupOperation(operations: nested1, nested2)
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            expectation.fulfill()
            })
        
        NSThread.sleepForTimeInterval(0.5)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.New)
        XCTAssertEqual(nested1.stateTransitions, OperationWorkflows.Pending)
        XCTAssertEqual(childOperation1_1.stateTransitions, OperationWorkflows.Pending)
        XCTAssertEqual(childOperation1_2.stateTransitions, OperationWorkflows.Pending)
        XCTAssertEqual(nested2.stateTransitions, OperationWorkflows.Pending)
        XCTAssertEqual(childOperation2_1.stateTransitions, OperationWorkflows.Pending)
        XCTAssertEqual(childOperation2_2.stateTransitions, OperationWorkflows.Pending)
        
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.Finished)
        XCTAssertEqual(nested1.stateTransitions, OperationWorkflows.Finished)
        XCTAssertEqual(childOperation1_1.stateTransitions, OperationWorkflows.Finished)
        XCTAssertEqual(childOperation1_2.stateTransitions, OperationWorkflows.Finished)
        XCTAssertEqual(nested2.stateTransitions, OperationWorkflows.Finished)
        XCTAssertEqual(childOperation2_1.stateTransitions, OperationWorkflows.Finished)
        XCTAssertEqual(childOperation2_2.stateTransitions, OperationWorkflows.Finished)
        
        XCTAssertFalse(operation.ready)
        XCTAssertFalse(operation.executing)
        XCTAssertTrue(operation.finished)
        XCTAssertFalse(operation.cancelled)
        
        XCTAssertFalse(nested1.ready)
        XCTAssertFalse(nested1.executing)
        XCTAssertTrue(nested1.finished)
        XCTAssertFalse(nested1.cancelled)
        
        XCTAssertTrue(childOperation1_1.wasRun)
        XCTAssertFalse(childOperation1_1.ready)
        XCTAssertFalse(childOperation1_1.executing)
        XCTAssertTrue(childOperation1_1.finished)
        XCTAssertFalse(childOperation1_1.cancelled)
        
        XCTAssertTrue(childOperation1_2.wasRun)
        XCTAssertFalse(childOperation1_2.ready)
        XCTAssertFalse(childOperation1_2.executing)
        XCTAssertTrue(childOperation1_2.finished)
        XCTAssertFalse(childOperation1_2.cancelled)
        
        XCTAssertFalse(nested2.ready)
        XCTAssertFalse(nested2.executing)
        XCTAssertTrue(nested2.finished)
        XCTAssertFalse(nested2.cancelled)
        
        XCTAssertTrue(childOperation2_1.wasRun)
        XCTAssertFalse(childOperation2_1.ready)
        XCTAssertFalse(childOperation2_1.executing)
        XCTAssertTrue(childOperation2_1.finished)
        XCTAssertFalse(childOperation2_1.cancelled)
        
        XCTAssertTrue(childOperation2_2.wasRun)
        XCTAssertFalse(childOperation2_2.ready)
        XCTAssertFalse(childOperation2_2.executing)
        XCTAssertTrue(childOperation2_2.finished)
        XCTAssertFalse(childOperation2_2.cancelled)
    }
    
    func testRunNestedCancelBeforeStart() {
        let operationQueue = createOperationQueue()
        
        let childOperation1_1 = StubOperation()
        childOperation1_1.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        
        let childOperation1_2 = StubOperation()
        childOperation1_2.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        childOperation1_2.addDependency(childOperation1_1)
        
        let nested1 = StubGroupOperation(operations: childOperation1_1, childOperation1_2)
        nested1.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        
        let childOperation2_1 = StubOperation()
        childOperation2_1.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        
        let childOperation2_2 = StubOperation()
        childOperation2_2.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        childOperation2_2.addDependency(childOperation2_1)
        
        let nested2 = StubGroupOperation(operations: childOperation2_1, childOperation2_2)
        nested2.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        
        let expectation = expectationWithDescription("operation")
        let operation = StubGroupOperation(operations: nested1, nested2)
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            expectation.fulfill()
            })
        
        NSThread.sleepForTimeInterval(0.5)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.New)
        XCTAssertEqual(nested1.stateTransitions, OperationWorkflows.Pending)
        XCTAssertEqual(childOperation1_1.stateTransitions, OperationWorkflows.Pending)
        XCTAssertEqual(childOperation1_2.stateTransitions, OperationWorkflows.Pending)
        XCTAssertEqual(nested2.stateTransitions, OperationWorkflows.Pending)
        XCTAssertEqual(childOperation2_1.stateTransitions, OperationWorkflows.Pending)
        XCTAssertEqual(childOperation2_2.stateTransitions, OperationWorkflows.Pending)
        
        operation.cancel()
        
        NSThread.sleepForTimeInterval(0.5)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.New)
        XCTAssertEqual(nested1.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        XCTAssertEqual(childOperation1_1.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        XCTAssertEqual(childOperation1_2.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        XCTAssertEqual(nested2.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        XCTAssertEqual(childOperation2_1.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        XCTAssertEqual(childOperation2_2.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        XCTAssertEqual(nested1.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        XCTAssertEqual(childOperation1_1.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        XCTAssertEqual(childOperation1_2.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        XCTAssertEqual(nested2.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        XCTAssertEqual(childOperation2_1.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        XCTAssertEqual(childOperation2_2.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        
        XCTAssertFalse(operation.ready)
        XCTAssertFalse(operation.executing)
        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
        
        XCTAssertFalse(nested1.ready)
        XCTAssertFalse(nested1.executing)
        XCTAssertTrue(nested1.finished)
        XCTAssertTrue(nested1.cancelled)
        
        XCTAssertFalse(childOperation1_1.wasRun)
        XCTAssertFalse(childOperation1_1.ready)
        XCTAssertFalse(childOperation1_1.executing)
        XCTAssertTrue(childOperation1_1.finished)
        XCTAssertTrue(childOperation1_1.cancelled)
        
        XCTAssertFalse(childOperation1_2.wasRun)
        XCTAssertFalse(childOperation1_2.ready)
        XCTAssertFalse(childOperation1_2.executing)
        XCTAssertTrue(childOperation1_2.finished)
        XCTAssertTrue(childOperation1_2.cancelled)
        
        XCTAssertFalse(nested2.ready)
        XCTAssertFalse(nested2.executing)
        XCTAssertTrue(nested2.finished)
        XCTAssertTrue(nested2.cancelled)
        
        XCTAssertFalse(childOperation2_1.wasRun)
        XCTAssertFalse(childOperation2_1.ready)
        XCTAssertFalse(childOperation2_1.executing)
        XCTAssertTrue(childOperation2_1.finished)
        XCTAssertTrue(childOperation2_1.cancelled)
        
        XCTAssertFalse(childOperation2_2.wasRun)
        XCTAssertFalse(childOperation2_2.ready)
        XCTAssertFalse(childOperation2_2.executing)
        XCTAssertTrue(childOperation2_2.finished)
        XCTAssertTrue(childOperation2_2.cancelled)
    }
    
}
