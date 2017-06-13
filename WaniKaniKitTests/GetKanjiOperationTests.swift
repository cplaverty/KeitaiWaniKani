//
//  GetKanjiOperationTests.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
import OHHTTPStubs
import OperationKit
@testable import WaniKaniKit

class GetKanjiOperationTests: DatabaseTestCase, ResourceHTTPStubs {
    
    func testKanjiLevel2Success() {
        // Check a Kanji with multiple meanings
        let expectedRicePaddyKanji = Kanji(character: "田",
                                           meaning: "rice paddy, rice field, field",
                                           onyomi: "でん",
                                           kunyomi: "た",
                                           importantReading: "kunyomi",
                                           level: 2)
        
        // Check a Kanji without kunyomi
        let expectedHeavenKanji = Kanji(character: "天",
                                        meaning: "heaven",
                                        onyomi: "てん",
                                        importantReading: "onyomi",
                                        level: 2,
                                        userSpecificSRSData: UserSpecificSRSData(srsLevel: .apprentice,
                                                                                 srsLevelNumeric: 4,
                                                                                 dateUnlocked: Date(timeIntervalSince1970: TimeInterval(1437918884)),
                                                                                 dateAvailable: Date(timeIntervalSince1970: TimeInterval(1438325100)),
                                                                                 burned: false,
                                                                                 meaningStats: ItemStats(correctCount: 3, incorrectCount: 0, maxStreakLength: 3, currentStreakLength: 3),
                                                                                 readingStats: ItemStats(correctCount: 3, incorrectCount: 0, maxStreakLength: 3, currentStreakLength: 3)))
        
        let operationQueue = OperationKit.OperationQueue()
        
        stubRequest(for: .kanji, file: "Kanji Level 2")
        defer { OHHTTPStubs.removeAllStubs() }
        
        self.measure() {
            let expect = self.expectation(description: "kanji")
            let operation = GetKanjiOperation(resolver: self.resourceResolver, databaseQueue: self.databaseQueue, downloadStrategy: self.stubDownloadStrategy)
            
            let completionObserver = BlockObserver(finishHandler: { (operation, errors) -> Void in
                defer { expect.fulfill() }
                XCTAssertEqual(errors.count, 0, "Expected no errors, but received: \(errors)")
            })
            operation.addObserver(completionObserver)
            operationQueue.addOperation(operation)
            
            self.waitForExpectations(timeout: 5.0, handler: nil)
        }
        
        databaseQueue.inDatabase { database in
            XCTAssertNotNil(database, "Database is nil!")
            do {
                let fromDatabase = try Kanji.coder.load(from: database)
                XCTAssertEqual(fromDatabase.count, 38, "Failed to load all kanji")
                
                if let actualRicePaddyKanji = fromDatabase.filter({ $0.meaning == expectedRicePaddyKanji.meaning }).first {
                    XCTAssertEqual(actualRicePaddyKanji, expectedRicePaddyKanji, "Rice paddy kanji did not match")
                } else {
                    XCTFail("Could not find kanji with meaning \(expectedRicePaddyKanji.meaning)")
                }
                
                if let actualHeavenKanji = fromDatabase.filter({ $0.meaning == expectedHeavenKanji.meaning }).first {
                    XCTAssertEqual(actualHeavenKanji, expectedHeavenKanji, "Heaven kanji did not match")
                } else {
                    XCTFail("Could not find kanji with meaning \(expectedHeavenKanji.meaning)")
                }
            } catch {
                XCTFail("Could not load kanji from database due to error: \(error)")
            }
        }
    }
    
    #if HAS_DOWNLOADED_DATA
    func testLoadByLevel() {
        let operationQueue = OperationQueue()
        
        stubForResource(Resource.Kanji, file: "Kanji Levels 1-20")
        defer { OHHTTPStubs.removeAllStubs() }
        
        let expect = self.expectationWithDescription("kanji")
        let operation = GetKanjiOperation(resolver: self.resourceResolver, databaseQueue: self.databaseQueue, downloadStrategy: self.stubDownloadStrategy)
        
        let completionObserver = BlockObserver(finishHandler: { (operation, errors) -> Void in
            defer { expect.fulfill() }
            XCTAssertEqual(errors.count, 0, "Expected no errors, but received: \(errors)")
        })
        operation.addObserver(completionObserver)
        operationQueue.addOperation(operation)
        
        self.waitForExpectationsWithTimeout(30.0, handler: nil)
        
        databaseQueue.inDatabase { database in
            do {
                let fromDatabase = try Kanji.coder.loadFromDatabase(database, forLevel: 3)
                XCTAssertEqual(fromDatabase.count, 33, "Failed to load all kanji")
            } catch {
                XCTFail("Could not load kanji from database due to error: \(error)")
            }
        }
    }
    
    func testKanjiPerformance() {
        let kanjiCount = 18 + 38 + 33 + 38 + 42 + 40 + 33 + 32 + 35 + 35 +
            38 + 37 + 37 + 32 + 33 + 35 + 33 + 29 + 34 + 32
        
        let operationQueue = OperationQueue()
        
        stubForResource(Resource.Kanji, file: "Kanji Levels 1-20")
        defer { OHHTTPStubs.removeAllStubs() }
        
        self.measureBlock() {
            let expect = self.expectationWithDescription("kanji")
            let operation = GetKanjiOperation(resolver: self.resourceResolver, databaseQueue: self.databaseQueue, downloadStrategy: self.stubDownloadStrategy)
            
            let completionObserver = BlockObserver(finishHandler: { (operation, errors) -> Void in
                defer { expect.fulfill() }
                XCTAssertEqual(errors.count, 0, "Expected no errors, but received: \(errors)")
            })
            operation.addObserver(completionObserver)
            operationQueue.addOperation(operation)
            
            self.waitForExpectationsWithTimeout(30.0, handler: nil)
        }
        
        databaseQueue.inDatabase { database in
            do {
                let fromDatabase = try Kanji.coder.loadFromDatabase(database)
                XCTAssertEqual(fromDatabase.count, kanjiCount, "Failed to load all kanji")
            } catch {
                XCTFail("Could not load kanji from database due to error: \(error)")
            }
        }
    }
    #endif
}
