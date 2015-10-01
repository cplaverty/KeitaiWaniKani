//
//  NoCancelledDependenciesTests.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
@testable import OperationKit

class NoCancelledDependenciesTests: XCTestCase {

    func testWithNoCancellations() {
        let operationQueue = createOperationQueue()
        
        let expectation1 = expectationWithDescription("operation1")
        let operation1 = StubOperation()
        operation1.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            expectation1.fulfill()
            })
        
        let expectation2 = expectationWithDescription("operation2")
        let operation2 = StubOperation()
        operation2.addCondition(NoCancelledDependencies())
        operation2.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            expectation2.fulfill()
            })
        operation2.addDependency(operation1)
        
        let expectation3 = expectationWithDescription("operation3")
        let operation3 = StubOperation()
        operation3.addCondition(AlwaysSatisfiedCondition())
        operation3.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            expectation3.fulfill()
            })
        operation3.addDependency(operation2)
        
        operationQueue.addOperations([operation1, operation2, operation3], waitUntilFinished: false)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertEqual(operation1.stateTransitions, OperationWorkflows.Finished)
        XCTAssertEqual(operation2.stateTransitions, OperationWorkflows.Finished)
        XCTAssertEqual(operation3.stateTransitions, OperationWorkflows.Finished)
        
        XCTAssertFalse(operation1.cancelled)
        XCTAssertFalse(operation2.cancelled)
        XCTAssertFalse(operation3.cancelled)
    }
    
    func testWithExplicitCancellationSerialDependencies() {
        let operationQueue = createOperationQueue()
        
        let expectation1 = expectationWithDescription("operation1")
        let operation1 = StubOperation()
        operation1.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            expectation1.fulfill()
            })
        
        let expectation2 = expectationWithDescription("operation2")
        let operation2 = StubOperation()
        operation2.addCondition(NoCancelledDependencies())
        operation2.addObserver(BlockObserver { _, errors in
            XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
            expectation2.fulfill()
            })
        operation2.addDependency(operation1)
        
        let expectation3 = expectationWithDescription("operation3")
        let operation3 = StubOperation()
        operation3.addCondition(NoCancelledDependencies())
        operation3.addObserver(BlockObserver { _, errors in
            XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
            expectation3.fulfill()
            })
        operation3.addDependency(operation2)
        
        operation1.cancel()
        operationQueue.addOperations([operation1, operation2, operation3], waitUntilFinished: false)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertEqual(operation1.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        XCTAssertEqual(operation2.stateTransitions, OperationWorkflows.CancelledAfterReady)
        XCTAssertEqual(operation3.stateTransitions, OperationWorkflows.CancelledAfterReady)
        
        XCTAssertTrue(operation1.cancelled)
        XCTAssertTrue(operation2.cancelled)
        XCTAssertTrue(operation3.cancelled)
    }
    
    func testWithExplicitCancellationTreeDependencies() {
        let operationQueue = createOperationQueue()
        
        let expectation1 = expectationWithDescription("operation1")
        let operation1 = StubOperation()
        operation1.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            expectation1.fulfill()
            })
        
        let expectation2 = expectationWithDescription("operation2")
        let operation2 = StubOperation()
        operation2.addCondition(NoCancelledDependencies())
        operation2.addObserver(BlockObserver { _, errors in
            XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
            expectation2.fulfill()
            })
        operation2.addDependency(operation1)
        
        let expectation3 = expectationWithDescription("operation3")
        let operation3 = StubOperation()
        operation3.addCondition(NoCancelledDependencies())
        operation3.addObserver(BlockObserver { _, errors in
            XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
            expectation3.fulfill()
            })
        operation3.addDependency(operation1)
        operation3.addDependency(operation2)
        
        operation1.cancel()
        operationQueue.addOperations([operation1, operation2, operation3], waitUntilFinished: false)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertEqual(operation1.stateTransitions, OperationWorkflows.CancelledBeforeReady)
        XCTAssertEqual(operation2.stateTransitions, OperationWorkflows.CancelledAfterReady)
        XCTAssertEqual(operation3.stateTransitions, OperationWorkflows.CancelledAfterReady)
        
        XCTAssertTrue(operation1.cancelled)
        XCTAssertTrue(operation2.cancelled)
        XCTAssertTrue(operation3.cancelled)
    }

    func testWithImplicitCancellationSerialDependencies() {
        let operationQueue = createOperationQueue()
        
        let expectation1 = expectationWithDescription("operation1")
        let operation1 = StubOperation()
        operation1.addCondition(AlwaysFailedCondition())
        operation1.addObserver(BlockObserver { _, errors in
            XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
            expectation1.fulfill()
            })
        
        let expectation2 = expectationWithDescription("operation2")
        let operation2 = StubOperation()
        operation2.addCondition(NoCancelledDependencies())
        operation2.addObserver(BlockObserver { _, errors in
            XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
            expectation2.fulfill()
            })
        operation2.addDependency(operation1)
        
        let expectation3 = expectationWithDescription("operation3")
        let operation3 = StubOperation()
        operation3.addCondition(NoCancelledDependencies())
        operation3.addObserver(BlockObserver { _, errors in
            XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
            expectation3.fulfill()
            })
        operation3.addDependency(operation2)
        
        operationQueue.addOperations([operation1, operation2, operation3], waitUntilFinished: false)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertEqual(operation1.stateTransitions, OperationWorkflows.CancelledAfterReady)
        XCTAssertEqual(operation2.stateTransitions, OperationWorkflows.CancelledAfterReady)
        XCTAssertEqual(operation3.stateTransitions, OperationWorkflows.CancelledAfterReady)
        
        XCTAssertTrue(operation1.cancelled)
        XCTAssertTrue(operation2.cancelled)
        XCTAssertTrue(operation3.cancelled)
    }
    
}