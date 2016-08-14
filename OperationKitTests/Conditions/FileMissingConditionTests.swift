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
        
        let tempDirectory = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let missingFile = tempDirectory.appendingPathComponent("jfjlkjijofsjaklfjskfjsiofjsfjalk")
        
        let operation = StubOperation()
        keyValueObservingExpectation(for: operation, keyPath: "isFinished", expectedValue: true)
        operation.addCondition(FileMissingCondition(url: missingFile))
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        
        operationQueue.addOperation(operation)
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.Finished)
        
        XCTAssertFalse(operation.isCancelled)
    }
    
    func testExistingFile() {
        let operationQueue = createOperationQueue()
        
        let fm = FileManager.default
        let tempDirectory = try! fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let nonMissingFile = tempDirectory.appendingPathComponent(UUID().uuidString)
        fm.createFile(atPath: nonMissingFile.path, contents: nil, attributes: nil)
        defer { try! fm.removeItem(atPath: nonMissingFile.path) }
        
        let operation = StubOperation()
        keyValueObservingExpectation(for: operation, keyPath: "isFinished", expectedValue: true)
        operation.addCondition(FileMissingCondition(url: nonMissingFile))
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertFalse(errors.isEmpty, "Expected errors on operation finish")
            })
        
        operationQueue.addOperation(operation)
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.CancelledAfterReady)
        
        XCTAssertFalse(operation.wasRun)
        XCTAssertTrue(operation.isCancelled)
    }
    
}
