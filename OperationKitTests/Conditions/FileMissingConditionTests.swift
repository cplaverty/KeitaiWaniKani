//
//  FileMissingConditionTests.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
@testable import OperationKit

class FileMissingConditionTests: XCTestCase {
    typealias Operation = OperationKit.Operation
    
    func testMissingFile() {
        let operationQueue = makeOperationQueue()
        
        let tempDirectory = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let missingFile = tempDirectory.appendingPathComponent("jfjlkjijofsjaklfjskfjsiofjsfjalk")
        
        let operation = StubOperation()
        keyValueObservingExpectation(for: operation, keyPath: "isFinished", expectedValue: true)
        operation.addCondition(FileMissingCondition(url: missingFile))
        operation.addObserver(BlockObserver { _, errors in
            XCTAssertTrue(errors.isEmpty, "Expected no errors on operation finish")
            })
        
        operationQueue.addOperation(operation)
        waitForExpectations(timeout: 15, handler: nil)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.finished)
        
        XCTAssertFalse(operation.isCancelled)
    }
    
    func testExistingFile() {
        let operationQueue = makeOperationQueue()
        
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
        waitForExpectations(timeout: 15, handler: nil)
        
        XCTAssertEqual(operation.stateTransitions, OperationWorkflows.cancelledAfterReady)
        
        XCTAssertFalse(operation.wasRun)
        XCTAssertTrue(operation.isCancelled)
    }
    
}
