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
            .apprentice: SRSItemCounts(radicals: 8, kanji: 10, vocabulary: 33, total: 51),
            .guru: SRSItemCounts(radicals: 51, kanji: 25, vocabulary: 17, total: 93),
            .master: SRSItemCounts(radicals: 0, kanji: 0, vocabulary: 0, total: 0),
            .enlightened: SRSItemCounts(radicals: 0, kanji: 0, vocabulary: 0, total: 0),
            .burned: SRSItemCounts(radicals: 0, kanji: 0, vocabulary: 0, total: 0),
            ]
        
        let expectedSRSDistribution = SRSDistribution(countsBySRSLevel: countsBySRSLevel)!
        
        let operationQueue = OperationKit.OperationQueue()
        
        stubForResource(Resource.srsDistribution, file: "SRS Distribution")
        defer { OHHTTPStubs.removeAllStubs() }
        
        self.measure() {
            let expect = self.expectation(description: "SRSDistribution")
            let operation = GetSRSDistributionOperation(resolver: self.resourceResolver, databaseQueue: self.databaseQueue)
            
            let completionObserver = BlockObserver(finishHandler: { (operation, errors) -> Void in
                defer { expect.fulfill() }
                XCTAssertEqual(errors.count, 0, "Expected no errors, but received: \(errors)")
            })
            operation.addObserver(completionObserver)
            operationQueue.addOperation(operation)
            
            self.waitForExpectations(timeout: 5.0, handler: nil)
        }
        
        let srsDistribution = try! databaseQueue.withDatabase { try SRSDistribution.coder.load(from: $0) }
        XCTAssertEqual(srsDistribution, expectedSRSDistribution, "SRSDistribution mismatch from database")
    }
    
}
