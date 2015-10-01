//
//  GetLevelProgressionOperationTests.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
import OperationKit
@testable import WaniKaniKit

class GetLevelProgressionOperationTests: DatabaseTestCase {
    
    func testLevelProgressionSuccess() {
        let expectedLevelProgression = LevelProgression(radicalsProgress: 25,
            radicalsTotal: 35,
            kanjiProgress: 7,
            kanjiTotal: 38)
        
        let resourceResolver = TestFileResourceResolver(fileName: "Level Progression")
        let operationQueue = OperationQueue()
        
        self.measureBlock() {
            let expect = self.expectationWithDescription("LevelProgression")
            let operation = GetLevelProgressionOperation(resolver: resourceResolver, databaseQueue: self.databaseQueue)
            
            let completionObserver = BlockObserver(finishHandler: { (operation, errors) -> Void in
                defer { expect.fulfill() }
                XCTAssertEqual(errors.count, 0, "Expected no errors, but received: \(errors)")
            })
            operation.addObserver(completionObserver)
            operationQueue.addOperation(operation)
            
            self.waitForExpectationsWithTimeout(5.0, handler: nil)
        }
        
        let levelProgression = try! databaseQueue.withDatabase { try LevelProgression.coder.loadFromDatabase($0) }
        XCTAssertEqual(levelProgression, expectedLevelProgression, "LevelProgression mismatch from database")
    }

}
