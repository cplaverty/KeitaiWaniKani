//
//  MutuallyExclusiveTests.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
@testable import OperationKit

class MutuallyExclusiveTests: XCTestCase {
    
    func testMutualExclusion() {
        enum Test {}
        typealias TestMutualExclusion = MutuallyExclusive<Test>
        let mutuallyExclusiveCondition = MutuallyExclusive<TestMutualExclusion>()
        
        let operationQueue = createOperationQueue()
        operationQueue.maxConcurrentOperationCount = 2
        
        let expectation1 = expectationWithDescription("operation1")
        let operation1 = StubOperation(immediatelyFinish: false)
        operation1.addCondition(mutuallyExclusiveCondition)
        operation1.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            
            expectation1.fulfill()
            })
        
        let expectation2 = expectationWithDescription("operation2")
        let operation2 = StubOperation()
        operation2.addCondition(mutuallyExclusiveCondition)
        operation2.addObserver(BlockObserver(
            startHandler: { op in
                XCTAssertFalse(operation1.ready)
                XCTAssertFalse(operation1.executing)
                XCTAssertTrue(operation1.finished)
                XCTAssertFalse(operation1.cancelled)
            },
            finishHandler: { op, errors in
                XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
                expectation2.fulfill()
            }
            ))
        
        operationQueue.addOperation(operation1)
        operationQueue.addOperation(operation2)
        
        NSThread.sleepForTimeInterval(0.5)
        
        XCTAssertEqual(operation1.stateTransitions, OperationWorkflows.Executing)
        XCTAssertEqual(operation2.stateTransitions, OperationWorkflows.Pending)
        
        XCTAssertFalse(operation1.ready)
        XCTAssertTrue(operation1.executing)
        XCTAssertFalse(operation1.finished)
        XCTAssertFalse(operation1.cancelled)
        
        XCTAssertFalse(operation2.ready)
        XCTAssertFalse(operation2.executing)
        XCTAssertFalse(operation2.finished)
        XCTAssertFalse(operation2.cancelled)
        
        operation1.finish()
        
        waitForExpectationsWithTimeout(1, handler: nil)
        
        XCTAssertFalse(operation1.ready)
        XCTAssertFalse(operation1.executing)
        XCTAssertTrue(operation1.finished)
        XCTAssertFalse(operation1.cancelled)
        
        XCTAssertFalse(operation2.ready)
        XCTAssertFalse(operation2.executing)
        XCTAssertTrue(operation2.finished)
        XCTAssertFalse(operation2.cancelled)
    }
    
}
