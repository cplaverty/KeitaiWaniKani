//
//  GetSRSDistributionOperationTests.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
import OHHTTPStubs
import OperationKit
@testable import WaniKaniKit

class GetSRSDistributionOperationTests: DatabaseTestCase, ResourceHTTPStubs {
    
    func testSRSDistributionSuccess() {
        let countsBySRSLevel: [SRSLevel: SRSItemCounts] = [
            .Apprentice: SRSItemCounts(radicals: 8, kanji: 10, vocabulary: 33, total: 51),
            .Guru: SRSItemCounts(radicals: 51, kanji: 25, vocabulary: 17, total: 93),
            .Master: SRSItemCounts(radicals: 0, kanji: 0, vocabulary: 0, total: 0),
            .Enlightened: SRSItemCounts(radicals: 0, kanji: 0, vocabulary: 0, total: 0),
            .Burned: SRSItemCounts(radicals: 0, kanji: 0, vocabulary: 0, total: 0),
            ]
        
        let expectedSRSDistribution = SRSDistribution(countsBySRSLevel: countsBySRSLevel)!
        
        let operationQueue = OperationQueue()
        
        stubForResource(Resource.SRSDistribution, file: "SRS Distribution")
        defer { OHHTTPStubs.removeAllStubs() }
        
        self.measureBlock() {
            let expect = self.expectationWithDescription("SRSDistribution")
            let operation = GetSRSDistributionOperation(resolver: self.resourceResolver, databaseQueue: self.databaseQueue)
            
            let completionObserver = BlockObserver(finishHandler: { (operation, errors) -> Void in
                defer { expect.fulfill() }
                XCTAssertEqual(errors.count, 0, "Expected no errors, but received: \(errors)")
            })
            operation.addObserver(completionObserver)
            operationQueue.addOperation(operation)
            
            self.waitForExpectationsWithTimeout(5.0, handler: nil)
        }
        
        let srsDistribution = try! databaseQueue.withDatabase { try SRSDistribution.coder.loadFromDatabase($0) }
        XCTAssertEqual(srsDistribution, expectedSRSDistribution, "SRSDistribution mismatch from database")
    }
    
}
