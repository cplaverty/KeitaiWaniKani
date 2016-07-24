//
//  SRSDataItemCoderTests.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
import OperationKit
@testable import WaniKaniKit

#if HAS_DOWNLOADED_DATA
class SRSDataItemCoderTests: DatabaseTestCase, ResourceHTTPStubs {

    override func setUp() {
        super.setUp()
        
        let radicalsExpectation = expectationWithDescription("radicals")
        let kanjiExpectation = expectationWithDescription("kanji")
        let vocabularyExpectation = expectationWithDescription("vocabulary")
        let operationQueue = OperationQueue()
        
        let resourceResolver = WaniKaniAPIResourceResolver(forAPIKey: "TEST_API_KEY")
        stubForResource(Resource.Radicals, file: "Radicals Levels 1-20")
        stubForResource(Resource.Kanji, file: "Kanji Levels 1-20")
        stubForResource(Resource.Vocabulary, file: "Vocab Levels 1-20")
        
        let radicalsOperation = GetRadicalsOperation(resolver: resourceResolver,
            databaseQueue: self.databaseQueue, downloadStrategy: self.stubDownloadStrategy)
        let kanjiOperation = GetKanjiOperation(resolver: resourceResolver,
            databaseQueue: self.databaseQueue, downloadStrategy: self.stubDownloadStrategy)
        let vocabularyOperation = GetVocabularyOperation(resolver: resourceResolver,
            databaseQueue: self.databaseQueue, downloadStrategy: self.stubDownloadStrategy)
        
        radicalsOperation.addObserver(BlockObserver { _, errors in
            radicalsExpectation.fulfill()
            XCTAssertEqual(errors.count, 0, "Expected no errors, but received: \(errors)")
            })
        kanjiOperation.addObserver(BlockObserver { _, errors in
            kanjiExpectation.fulfill()
            XCTAssertEqual(errors.count, 0, "Expected no errors, but received: \(errors)")
            })
        vocabularyOperation.addObserver(BlockObserver { _, errors in
            vocabularyExpectation.fulfill()
            XCTAssertEqual(errors.count, 0, "Expected no errors, but received: \(errors)")
            })
        
        print("Loading test data...")
        // We have to set waitUntilFinished = false here since the requisite method in Operation throws a fatalError
        operationQueue.addOperations([radicalsOperation, kanjiOperation, vocabularyOperation], waitUntilFinished: false)
        waitForExpectationsWithTimeout(60.0, handler: nil)
    }
    
    func testReviewTimeline() {
        self.measureBlock() {
            self.databaseQueue.inDatabase { database in
                let reviewTimeline = try! SRSDataItemCoder.reviewTimeline(database)
                XCTAssertEqual(reviewTimeline.count, 249)
                XCTAssertEqual(reviewTimeline[2], SRSReviewCounts(dateAvailable: NSDate(timeIntervalSince1970: 1387708200), itemCounts: SRSItemCounts(radicals: 0, kanji: 0, vocabulary: 2, total: 2)))
            }
        }
    }
    
    func testReviewTimelineSince() {
        self.measureBlock() {
            self.databaseQueue.inDatabase { database in
                let reviewTimeline = try! SRSDataItemCoder.reviewTimeline(database, since: NSDate(timeIntervalSince1970: 1432004400))
                XCTAssertEqual(reviewTimeline.count, 29)
                XCTAssertEqual(reviewTimeline[0], SRSReviewCounts(dateAvailable: NSDate(timeIntervalSince1970: 0), itemCounts: SRSItemCounts(radicals: 18, kanji: 102, vocabulary: 347, total: 467)))
                XCTAssertEqual(reviewTimeline[2], SRSReviewCounts(dateAvailable: NSDate(timeIntervalSince1970: 1432250100), itemCounts: SRSItemCounts(radicals: 1, kanji: 2, vocabulary: 1, total: 4)))
            }
        }
    }
    
    func testReviewTimelineLimit() {
        self.measureBlock() {
            self.databaseQueue.inDatabase { database in
                let reviewTimeline = try! SRSDataItemCoder.reviewTimeline(database, rowLimit: 10)
                XCTAssertEqual(reviewTimeline.count, 10)
                XCTAssertEqual(reviewTimeline[2], SRSReviewCounts(dateAvailable: NSDate(timeIntervalSince1970: 1387708200), itemCounts: SRSItemCounts(radicals: 0, kanji: 0, vocabulary: 2, total: 2)))
            }
        }
    }
    
    func testLevelTimeline() {
        self.measureBlock() {
            self.databaseQueue.inDatabase { database in
                let levelTimeline = try! SRSDataItemCoder.levelTimeline(database)
                XCTAssertEqual(levelTimeline.detail.count, 20)
                XCTAssertNotNil(levelTimeline.stats?.mean)
            }
        }
    }

}
#endif
