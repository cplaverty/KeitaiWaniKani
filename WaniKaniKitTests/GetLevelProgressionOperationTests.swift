//
//  GetLevelProgressionOperationTests.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
import OHHTTPStubs
import OperationKit
@testable import WaniKaniKit

class GetLevelProgressionOperationTests: DatabaseTestCase, ResourceHTTPStubs {
    
    func testLevelProgressionSuccess() {
        let expectedLevelProgression = LevelProgression(radicalsProgress: 25,
                                                        radicalsTotal: 35,
                                                        kanjiProgress: 7,
                                                        kanjiTotal: 38)
        
        let operationQueue = OperationKit.OperationQueue()
        
        stubForResource(Resource.levelProgression, file: "Level Progression")
        defer { OHHTTPStubs.removeAllStubs() }
        
        self.measure() {
            let expect = self.expectation(description: "LevelProgression")
            let operation = GetLevelProgressionOperation(resolver: self.resourceResolver, databaseQueue: self.databaseQueue)
            
            let completionObserver = BlockObserver(finishHandler: { (operation, errors) -> Void in
                defer { expect.fulfill() }
                XCTAssertEqual(errors.count, 0, "Expected no errors, but received: \(errors)")
            })
            operation.addObserver(completionObserver)
            operationQueue.addOperation(operation)
            
            self.waitForExpectations(timeout: 5.0, handler: nil)
        }
        
        let levelProgression = try! databaseQueue.withDatabase { try LevelProgression.coder.load(from: $0) }
        XCTAssertEqual(levelProgression, expectedLevelProgression, "LevelProgression mismatch from database")
    }
    
}
