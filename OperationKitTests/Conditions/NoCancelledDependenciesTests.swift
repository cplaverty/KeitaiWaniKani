//
//  NoCancelledDependenciesTests.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
@testable import OperationKit

class NoCancelledDependenciesTests: XCTestCase {
    typealias Operation = OperationKit.Operation
    
    func testWithNoCancellations() {
        let operationQueue = makeOperationQueue()
        
        let operation1 = StubOperation()
        keyValueObservingExpectation(for: operation1, keyPath: "isFinished", expectedValue: true)
        operation1.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        
        let operation2 = StubOperation()
        keyValueObservingExpectation(for: operation2, keyPath: "isFinished", expectedValue: true)
        operation2.addCondition(NoCancelledDependencies())
        operation2.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        operation2.addDependency(operation1)
        
        let operation3 = StubOperation()
        keyValueObservingExpectation(for: operation3, keyPath: "isFinished", expectedValue: true)
        operation3.addCondition(AlwaysSatisfiedCondition())
        operation3.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        operation3.addDependency(operation2)
        
        operationQueue.addOperations([operation1, operation2, operation3], waitUntilFinished: false)
        waitForExpectations(timeout: 15, handler: nil)
        
        XCTAssertEqual(operation1.stateTransitions, OperationWorkflows.finished)
        XCTAssertEqual(operation2.stateTransitions, OperationWorkflows.finished)
        XCTAssertEqual(operation3.stateTransitions, OperationWorkflows.finished)
        
        XCTAssertFalse(operation1.isCancelled)
        XCTAssertFalse(operation2.isCancelled)
        XCTAssertFalse(operation3.isCancelled)
    }
    
    func testWithExplicitCancellationSerialDependencies() {
        let operationQueue = makeOperationQueue()
        
        let operation1 = StubOperation()
        keyValueObservingExpectation(for: operation1, keyPath: "isFinished", expectedValue: true)
        operation1.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        
        let operation2 = StubOperation()
        keyValueObservingExpectation(for: operation2, keyPath: "isFinished", expectedValue: true)
        operation2.addCondition(NoCancelledDependencies())
        operation2.addObserver(BlockObserver { _, errors in
            XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
            })
        operation2.addDependency(operation1)
        
        let operation3 = StubOperation()
        keyValueObservingExpectation(for: operation3, keyPath: "isFinished", expectedValue: true)
        operation3.addCondition(NoCancelledDependencies())
        operation3.addObserver(BlockObserver { _, errors in
            XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
            })
        operation3.addDependency(operation2)
        
        operation1.cancel()
        operationQueue.addOperations([operation1, operation2, operation3], waitUntilFinished: false)
        waitForExpectations(timeout: 15, handler: nil)
        
        XCTAssertEqual(operation1.stateTransitions, OperationWorkflows.cancelledBeforeReady)
        XCTAssertEqual(operation2.stateTransitions, OperationWorkflows.cancelledAfterReady)
        XCTAssertEqual(operation3.stateTransitions, OperationWorkflows.cancelledAfterReady)
        
        XCTAssertTrue(operation1.isCancelled)
        XCTAssertTrue(operation2.isCancelled)
        XCTAssertTrue(operation3.isCancelled)
    }
    
    func testWithExplicitCancellationTreeDependencies() {
        let operationQueue = makeOperationQueue()
        
        let operation1 = StubOperation()
        keyValueObservingExpectation(for: operation1, keyPath: "isFinished", expectedValue: true)
        operation1.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        
        let operation2 = StubOperation()
        keyValueObservingExpectation(for: operation2, keyPath: "isFinished", expectedValue: true)
        operation2.addCondition(NoCancelledDependencies())
        operation2.addObserver(BlockObserver { _, errors in
            XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
            })
        operation2.addDependency(operation1)
        
        let operation3 = StubOperation()
        keyValueObservingExpectation(for: operation3, keyPath: "isFinished", expectedValue: true)
        operation3.addCondition(NoCancelledDependencies())
        operation3.addObserver(BlockObserver { _, errors in
            XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
            })
        operation3.addDependency(operation1)
        operation3.addDependency(operation2)
        
        operation1.cancel()
        operationQueue.addOperations([operation1, operation2, operation3], waitUntilFinished: false)
        waitForExpectations(timeout: 15, handler: nil)
        
        XCTAssertEqual(operation1.stateTransitions, OperationWorkflows.cancelledBeforeReady)
        XCTAssertEqual(operation2.stateTransitions, OperationWorkflows.cancelledAfterReady)
        XCTAssertEqual(operation3.stateTransitions, OperationWorkflows.cancelledAfterReady)
        
        XCTAssertTrue(operation1.isCancelled)
        XCTAssertTrue(operation2.isCancelled)
        XCTAssertTrue(operation3.isCancelled)
    }
    
    func testWithImplicitCancellationSerialDependencies() {
        let operationQueue = makeOperationQueue()
        
        let operation1 = StubOperation()
        keyValueObservingExpectation(for: operation1, keyPath: "isFinished", expectedValue: true)
        operation1.addCondition(AlwaysFailedCondition())
        operation1.addObserver(BlockObserver { _, errors in
            XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
            })
        
        let operation2 = StubOperation()
        keyValueObservingExpectation(for: operation2, keyPath: "isFinished", expectedValue: true)
        operation2.addCondition(NoCancelledDependencies())
        operation2.addObserver(BlockObserver { _, errors in
            XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
            })
        operation2.addDependency(operation1)
        
        let operation3 = StubOperation()
        keyValueObservingExpectation(for: operation3, keyPath: "isFinished", expectedValue: true)
        operation3.addCondition(NoCancelledDependencies())
        operation3.addObserver(BlockObserver { _, errors in
            XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
            })
        operation3.addDependency(operation2)
        
        operationQueue.addOperations([operation1, operation2, operation3], waitUntilFinished: false)
        waitForExpectations(timeout: 15, handler: nil)
        
        XCTAssertEqual(operation1.stateTransitions, OperationWorkflows.cancelledAfterReady)
        XCTAssertEqual(operation2.stateTransitions, OperationWorkflows.cancelledAfterReady)
        XCTAssertEqual(operation3.stateTransitions, OperationWorkflows.cancelledAfterReady)
        
        XCTAssertTrue(operation1.isCancelled)
        XCTAssertTrue(operation2.isCancelled)
        XCTAssertTrue(operation3.isCancelled)
    }
    
}
