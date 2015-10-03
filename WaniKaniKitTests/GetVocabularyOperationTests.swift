//
//  GetVocabularyOperationTests.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
import OperationKit
@testable import WaniKaniKit

class GetVocabularyOperationTests: DatabaseTestCase {
    
    func testVocabLevel1Success() {
        // Check a locked Vocab with multiple meanings
        let expectedArtificialVocab = Vocabulary(character: "人工",
            meaning: "artificial, man made, human made, human work, human skill, artificially",
            kana: "じんこう",
            level: 1,
            userSpecificSRSData: UserSpecificSRSData(srsLevel: .Apprentice,
                srsLevelNumeric: 4,
                dateUnlocked: NSDate(timeIntervalSince1970: NSTimeInterval(1436895207)),
                dateAvailable: NSDate(timeIntervalSince1970: NSTimeInterval(1438173900)),
                burned: false,
                meaningStats: ItemStats(correctCount: 3, incorrectCount: 0, maxStreakLength: 3, currentStreakLength: 3),
                readingStats: ItemStats(correctCount: 3, incorrectCount: 0, maxStreakLength: 3, currentStreakLength: 3)))
        
        // Check an unlocked, unburned Vocab
        let expectedNineThingsVocab = Vocabulary(character: "九つ",
            meaning: "nine things",
            kana: "ここのつ",
            level: 1,
            userSpecificSRSData: UserSpecificSRSData(srsLevel: .Apprentice,
                srsLevelNumeric: 4,
                dateUnlocked: NSDate(timeIntervalSince1970: NSTimeInterval(1436895229)),
                dateAvailable: NSDate(timeIntervalSince1970: NSTimeInterval(1438206300)),
                burned: false,
                meaningStats: ItemStats(correctCount: 3, incorrectCount: 0, maxStreakLength: 3, currentStreakLength: 3),
                readingStats: ItemStats(correctCount: 3, incorrectCount: 0, maxStreakLength: 3, currentStreakLength: 3)))
        
        let resourceResolver = TestFileResourceResolver(fileName: "Vocab Level 1")
        let operationQueue = OperationQueue()
        
        self.measureBlock() {
            let expect = self.expectationWithDescription("vocabulary")
            let operation = GetVocabularyOperation(resolver: resourceResolver, databaseQueue: self.databaseQueue, downloadStrategy: self.stubDownloadStrategy)
            
            let completionObserver = BlockObserver(finishHandler: { (operation, errors) -> Void in
                defer { expect.fulfill() }
                XCTAssertEqual(errors.count, 0, "Expected no errors, but received: \(errors)")
            })
            operation.addObserver(completionObserver)
            operationQueue.addOperation(operation)
            
            self.waitForExpectationsWithTimeout(15.0, handler: nil)
        }
        
        databaseQueue.inDatabase { database in
            do {
                let fromDatabase = try Vocabulary.coder.loadFromDatabase(database)
                XCTAssertEqual(fromDatabase.count, 42, "Failed to load all vocabulary")
                
                if let actualArtificialVocab = fromDatabase.filter({ $0.meaning == expectedArtificialVocab.meaning }).first {
                    XCTAssertEqual(actualArtificialVocab, expectedArtificialVocab, "Artificial vocab did not match")
                } else {
                    XCTFail("Could not find vocab with meaning \(expectedArtificialVocab.meaning)")
                }
                
                if let actualNineThingsVocab = fromDatabase.filter({ $0.meaning == expectedNineThingsVocab.meaning }).first {
                    XCTAssertEqual(actualNineThingsVocab, expectedNineThingsVocab, "Nine things vocabulary did not match")
                } else {
                    XCTFail("Could not find vocab with meaning \(expectedNineThingsVocab.meaning)")
                }
            } catch {
                XCTFail("Could not load vocab from database due to error: \(error)")
            }
        }
    }
    
    #if HAS_DOWNLOADED_DATA
    func testLoadByLevel() {
        let resourceResolver = TestFileResourceResolver(fileName: "Vocab Levels 1-20")
        let operationQueue = OperationQueue()
        
        let expect = self.expectationWithDescription("vocabulary")
        let operation = GetVocabularyOperation(resolver: resourceResolver, databaseQueue: self.databaseQueue, downloadStrategy: self.stubDownloadStrategy)
        
        let completionObserver = BlockObserver(finishHandler: { (operation, errors) -> Void in
            defer { expect.fulfill() }
            XCTAssertEqual(errors.count, 0, "Expected no errors, but received: \(errors)")
        })
        operation.addObserver(completionObserver)
        operationQueue.addOperation(operation)
        
        self.waitForExpectationsWithTimeout(60.0, handler: nil)
        
        databaseQueue.inDatabase { database in
            do {
                let fromDatabase = try Vocabulary.coder.loadFromDatabase(database, forLevel: 3)
                XCTAssertEqual(fromDatabase.count, 68, "Failed to load all vocabulary")
            } catch {
                XCTFail("Could not load vocabulary from database due to error: \(error)")
            }
        }
    }
    
    func testVocabPerformance() {
        let vocabCount = 42 + 90 + 68 + 104 + 124 + 115 + 95 + 132 + 115 + 114 +
            121 + 125 + 113 + 114 + 96 + 116 + 122 + 134 + 105 + 112
        
        let resourceResolver = TestFileResourceResolver(fileName: "Vocab Levels 1-20")
        let operationQueue = OperationQueue()
        
        self.measureBlock() {
            let expect = self.expectationWithDescription("vocabulary")
            let operation = GetVocabularyOperation(resolver: resourceResolver, databaseQueue: self.databaseQueue, downloadStrategy: self.stubDownloadStrategy)
            
            let completionObserver = BlockObserver(finishHandler: { (operation, errors) -> Void in
                defer { expect.fulfill() }
                XCTAssertEqual(errors.count, 0, "Expected no errors, but received: \(errors)")
            })
            operation.addObserver(completionObserver)
            operationQueue.addOperation(operation)
            
            self.waitForExpectationsWithTimeout(60.0, handler: nil)
        }
        
        databaseQueue.inDatabase { database in
            do {
                let fromDatabase = try Vocabulary.coder.loadFromDatabase(database)
                XCTAssertEqual(fromDatabase.count, vocabCount, "Failed to load all vocabulary")
            } catch {
                XCTFail("Could not load vocabulary from database due to error: \(error)")
            }
        }
    }
    #endif
    
}
