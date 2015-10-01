//
//  FileMissingConditionTests.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
@testable import OperationKit

class FileMissingConditionTests: XCTestCase {
    
    func testMissingFile() {
        let operationQueue = createOperationQueue()
        
        let tempDirectory = try! NSFileManager.defaultManager().URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        let missingFile = tempDirectory.URLByAppendingPathComponent("jfjlkjijofsjaklfjskfjsiofjsfjalk")
        
        let expectation = expectationWithDescription("operation")
        let operation = StubOperation()
        operation.addCondition(FileMissingCondition(fileURL: missingFile))
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            expectation.fulfill()
            })
        
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.Finished)
        
        XCTAssertFalse(operation.cancelled)
    }
    
    func testExistingFile() {
        let operationQueue = createOperationQueue()
        
        let fm = NSFileManager.defaultManager()
        let tempDirectory = try! fm.URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        let nonMissingFile = tempDirectory.URLByAppendingPathComponent(NSUUID().UUIDString)
        fm.createFileAtPath(nonMissingFile.path!, contents: nil, attributes: nil)
        defer { try! fm.removeItemAtPath(nonMissingFile.path!) }
        
        let expectation = expectationWithDescription("operation")
        let operation = StubOperation()
        operation.addCondition(FileMissingCondition(fileURL: nonMissingFile))
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
            expectation.fulfill()
            })
        
        operationQueue.addOperation(operation)
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.CancelledAfterReady)
        
        XCTAssertFalse(operation.wasRun)
        XCTAssertTrue(operation.cancelled)
    }
    
}
