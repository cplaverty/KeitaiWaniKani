//
//  SRSDataItemTests.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
@testable import WaniKaniKit

class SRSDataItemTests: XCTestCase {
    
    func testGuruDateLockedKanji() {
        let locked = Kanji(character: "",
            meaning: "",
            importantReading: "",
            level: 4)
        
        let lockedGuruDate = locked.guruDate(date(2016, 1, 1, 0, 0, 0))
        let lockedExpectedGuruDate = date(2016, 1, 5, 10, 0, 0)
        XCTAssertEqual(lockedGuruDate, lockedExpectedGuruDate)
    }
    
    func testGuruDateApprenticeKanji() {
        let newlyUnlocked = Kanji(character: "",
            meaning: "",
            importantReading: "",
            level: 4,
            userSpecificSRSData: UserSpecificSRSData(srsLevel: SRSLevel.Apprentice,
                srsLevelNumeric: 1,
                dateUnlocked: date(2016, 1, 1, 0, 0, 0),
                dateAvailable: date(2016, 2, 1, 0, 0, 0),
                burned: false))
        
        let newlyUnlockedGuruDate = newlyUnlocked.guruDate(nil)
        let newlyUnlockedExpectedGuruDate = date(2016, 2, 5, 6, 0, 0)
        XCTAssertEqual(newlyUnlockedGuruDate, newlyUnlockedExpectedGuruDate)
    }
    
    func testGuruDateApprentice3Kanji() {
        let nearlyGuru = Kanji(character: "",
            meaning: "",
            importantReading: "",
            level: 4,
            userSpecificSRSData: UserSpecificSRSData(srsLevel: SRSLevel.Apprentice,
                srsLevelNumeric: SRSLevel.Guru.numericLevelThreshold - 1,
                dateUnlocked: date(2016, 1, 1, 0, 0, 0),
                dateAvailable: date(2016, 2, 1, 0, 0, 0),
                burned: false))
        
        let nearlyGuruDate = nearlyGuru.guruDate(nil)
        let nearlyGuruExpectedDate = date(2016, 2, 1, 0, 0, 0)
        XCTAssertEqual(nearlyGuruDate, nearlyGuruExpectedDate)
    }
    
    func testGuruDateMasterKanji() {
        let mastered = Kanji(character: "",
            meaning: "",
            importantReading: "",
            level: 4,
            userSpecificSRSData: UserSpecificSRSData(srsLevel: SRSLevel.Master,
                srsLevelNumeric: SRSLevel.Master.numericLevelThreshold,
                dateUnlocked: date(2016, 1, 1, 0, 0, 0),
                dateAvailable: date(2016, 2, 1, 0, 0, 0),
                burned: false))
        
        let masteredGuruDate = mastered.guruDate(nil)
        let masteredExpectedGuruDate: NSDate? = nil
        XCTAssertEqual(masteredGuruDate, masteredExpectedGuruDate)
    }
    
    func testGuruDateLockedAcceleratedRadical() {
        let locked = Radical(meaning: "", level: 1)
        
        let lockedGuruDate = locked.guruDate(date(2016, 1, 1, 0, 0, 0))
        let lockedExpectedGuruDate = date(2016, 1, 2, 13, 0, 0)
        XCTAssertEqual(lockedGuruDate, lockedExpectedGuruDate)
    }
    
    func testGuruDateLockedNonAcceleratedRadical() {
        let locked = Radical(meaning: "", level: 3)
        
        let lockedGuruDate = locked.guruDate(date(2016, 1, 1, 0, 0, 0))
        let lockedExpectedGuruDate = date(2016, 1, 4, 10, 0, 0)
        XCTAssertEqual(lockedGuruDate, lockedExpectedGuruDate)
    }
    
    func testGuruDateApprenticeAcceleratedRadical() {
        let newlyUnlocked = Radical(meaning: "",
            level: 1,
            userSpecificSRSData: UserSpecificSRSData(srsLevel: SRSLevel.Apprentice,
                srsLevelNumeric: 1,
                dateUnlocked: date(2016, 1, 1, 0, 0, 0),
                dateAvailable: date(2016, 2, 1, 0, 0, 0),
                burned: false))
        
        let newlyUnlockedGuruDate = newlyUnlocked.guruDate(nil)
        let newlyUnlockedExpectedGuruDate = date(2016, 2, 2, 11, 0, 0)
        XCTAssertEqual(newlyUnlockedGuruDate, newlyUnlockedExpectedGuruDate)
    }
    
    func testGuruDateApprenticeNonAcceleratedRadical() {
        let newlyUnlocked = Radical(meaning: "",
            level: 10,
            userSpecificSRSData: UserSpecificSRSData(srsLevel: SRSLevel.Apprentice,
                srsLevelNumeric: 1,
                dateUnlocked: date(2016, 1, 1, 0, 0, 0),
                dateAvailable: date(2016, 2, 1, 0, 0, 0),
                burned: false))
        
        let newlyUnlockedGuruDate = newlyUnlocked.guruDate(nil)
        let newlyUnlockedExpectedGuruDate = date(2016, 2, 4, 6, 0, 0)
        XCTAssertEqual(newlyUnlockedGuruDate, newlyUnlockedExpectedGuruDate)
    }
    
    func testEarliestPossibleGuruDateLockedKanji() {
        let locked = Kanji(character: "",
            meaning: "",
            importantReading: "",
            level: 4)
        
        let lockedGuruDate = locked.earliestPossibleGuruDate(date(2016, 1, 1, 0, 0, 0))
        let lockedExpectedGuruDate = date(2016, 1, 5, 10, 0, 0)
        XCTAssertEqual(lockedGuruDate, lockedExpectedGuruDate)
    }
    
    func testEarliestPossibleGuruDateApprenticeKanji() {
        let newlyUnlocked = Kanji(character: "",
            meaning: "",
            importantReading: "",
            level: 4,
            userSpecificSRSData: UserSpecificSRSData(srsLevel: SRSLevel.Apprentice,
                srsLevelNumeric: 1,
                dateUnlocked: date(2016, 1, 1, 0, 0, 0),
                dateAvailable: date(2016, 2, 1, 0, 0, 0),
                burned: false))
        
        let newlyUnlockedGuruDate = newlyUnlocked.earliestPossibleGuruDate(nil)
        let newlyUnlockedExpectedGuruDate = date(2016, 1, 5, 10, 0, 0)
        XCTAssertEqual(newlyUnlockedGuruDate, newlyUnlockedExpectedGuruDate)
    }
    
    func testEarliestPossibleGuruDateApprentice3Kanji() {
        let nearlyGuru = Kanji(character: "",
            meaning: "",
            importantReading: "",
            level: 4,
            userSpecificSRSData: UserSpecificSRSData(srsLevel: SRSLevel.Apprentice,
                srsLevelNumeric: SRSLevel.Guru.numericLevelThreshold - 1,
                dateUnlocked: date(2016, 1, 1, 0, 0, 0),
                dateAvailable: date(2016, 2, 1, 0, 0, 0),
                burned: false))
        
        let nearlyGuruDate = nearlyGuru.earliestPossibleGuruDate(nil)
        let nearlyGuruExpectedDate = date(2016, 1, 5, 10, 0, 0)
        XCTAssertEqual(nearlyGuruDate, nearlyGuruExpectedDate)
    }
    
    func testEarliestPossibleGuruDateMasterKanji() {
        let mastered = Kanji(character: "",
            meaning: "",
            importantReading: "",
            level: 4,
            userSpecificSRSData: UserSpecificSRSData(srsLevel: SRSLevel.Master,
                srsLevelNumeric: SRSLevel.Master.numericLevelThreshold,
                dateUnlocked: date(2016, 1, 1, 0, 0, 0),
                dateAvailable: date(2016, 2, 1, 0, 0, 0),
                burned: false))
        
        let masteredGuruDate = mastered.earliestPossibleGuruDate(nil)
        let masteredExpectedGuruDate = date(2016, 1, 5, 10, 0, 0)
        XCTAssertEqual(masteredGuruDate, masteredExpectedGuruDate)
    }
    
    func testEarliestPossibleGuruDateLockedAcceleratedRadical() {
        let locked = Radical(meaning: "", level: 1)
        
        let lockedGuruDate = locked.earliestPossibleGuruDate(date(2016, 1, 1, 0, 0, 0))
        let lockedExpectedGuruDate = date(2016, 1, 2, 13, 0, 0)
        XCTAssertEqual(lockedGuruDate, lockedExpectedGuruDate)
    }
    
    func testEarliestPossibleGuruDateLockedNonAcceleratedRadical() {
        let locked = Radical(meaning: "", level: 3)
        
        let lockedGuruDate = locked.earliestPossibleGuruDate(date(2016, 1, 1, 0, 0, 0))
        let lockedExpectedGuruDate = date(2016, 1, 4, 10, 0, 0)
        XCTAssertEqual(lockedGuruDate, lockedExpectedGuruDate)
    }
    
    func testEarliestPossibleGuruDateApprenticeAcceleratedRadical() {
        let newlyUnlocked = Radical(meaning: "",
            level: 1,
            userSpecificSRSData: UserSpecificSRSData(srsLevel: SRSLevel.Apprentice,
                srsLevelNumeric: 1,
                dateUnlocked: date(2016, 1, 1, 0, 0, 0),
                dateAvailable: date(2016, 2, 1, 0, 0, 0),
                burned: false))
        
        let newlyUnlockedGuruDate = newlyUnlocked.earliestPossibleGuruDate(nil)
        let newlyUnlockedExpectedGuruDate = date(2016, 1, 2, 13, 0, 0)
        XCTAssertEqual(newlyUnlockedGuruDate, newlyUnlockedExpectedGuruDate)
    }
    
    func testEarliestPossibleGuruDateApprenticeNonAcceleratedRadical() {
        let newlyUnlocked = Radical(meaning: "",
            level: 10,
            userSpecificSRSData: UserSpecificSRSData(srsLevel: SRSLevel.Apprentice,
                srsLevelNumeric: 1,
                dateUnlocked: date(2016, 1, 1, 0, 0, 0),
                dateAvailable: date(2016, 2, 1, 0, 0, 0),
                burned: false))
        
        let newlyUnlockedGuruDate = newlyUnlocked.earliestPossibleGuruDate(nil)
        let newlyUnlockedExpectedGuruDate = date(2016, 1, 4, 10, 0, 0)
        XCTAssertEqual(newlyUnlockedGuruDate, newlyUnlockedExpectedGuruDate)
    }
    
}
