//
//  MutuallyExclusiveTests.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
@testable import OperationKit

class MutuallyExclusiveTests: XCTestCase {
    typealias Operation = OperationKit.Operation
    
    func testMutualExclusion() {
        enum Test {}
        typealias TestMutualExclusion = MutuallyExclusive<Test>
        let mutuallyExclusiveCondition = MutuallyExclusive<TestMutualExclusion>()
        
        let operationQueue = makeOperationQueue()
        operationQueue.maxConcurrentOperationCount = 2
        
        let operation1 = StubOperation(immediatelyFinish: false)
        keyValueObservingExpectation(for: operation1, keyPath: "isFinished", expectedValue: true)
        operation1.addCondition(mutuallyExclusiveCondition)
        operation1.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        
        let operation2 = StubOperation()
        keyValueObservingExpectation(for: operation2, keyPath: "isFinished", expectedValue: true)
        operation2.addCondition(mutuallyExclusiveCondition)
        operation2.addObserver(BlockObserver(
            startHandler: { op in
                XCTAssertFalse(operation1.isReady)
                XCTAssertFalse(operation1.isExecuting)
                XCTAssertTrue(operation1.isFinished)
                XCTAssertFalse(operation1.isCancelled)
            },
            finishHandler: { op, errors in
                XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            }
            ))
        
        operationQueue.addOperation(operation1)
        operationQueue.addOperation(operation2)
        
        Thread.sleep(forTimeInterval: 0.5)
        
        XCTAssertEqual(operation1.stateTransitions, OperationWorkflows.executing)
        XCTAssertEqual(operation2.stateTransitions, OperationWorkflows.pending)
        
        XCTAssertFalse(operation1.isReady)
        XCTAssertTrue(operation1.isExecuting)
        XCTAssertFalse(operation1.isFinished)
        XCTAssertFalse(operation1.isCancelled)
        
        XCTAssertFalse(operation2.isReady)
        XCTAssertFalse(operation2.isExecuting)
        XCTAssertFalse(operation2.isFinished)
        XCTAssertFalse(operation2.isCancelled)
        
        operation1.finish()
        
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertFalse(operation1.isReady)
        XCTAssertFalse(operation1.isExecuting)
        XCTAssertTrue(operation1.isFinished)
        XCTAssertFalse(operation1.isCancelled)
        
        XCTAssertFalse(operation2.isReady)
        XCTAssertFalse(operation2.isExecuting)
        XCTAssertTrue(operation2.isFinished)
        XCTAssertFalse(operation2.isCancelled)
    }
    
}
