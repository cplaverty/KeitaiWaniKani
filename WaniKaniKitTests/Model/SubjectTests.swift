//
//  SubjectTests.swift
//  WaniKaniKitTests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import XCTest
@testable import WaniKaniKit

class SubjectTests: XCTestCase {
    
    func testRadical_NoAssignment() {
        let subject = makeRadical()
        let expectedGuruDate = Calendar.current.startOfHour(for: Date()).addingTimeInterval(4 * .oneHour + 4 * .oneHour + 8 * .oneHour + 23 * .oneHour)
        
        let guruDate = subject.earliestGuruDate(assignment: nil) { _ in
            XCTFail("Did not expect assignment fetch for radical")
            return nil
        }
        
        XCTAssertEqual(guruDate, expectedGuruDate)
    }
    
    func testRadical_LockedAssignment() {
        let subject = makeRadical()
        let assignment = makeAssignment(srsStage: .initiate, availableAt: Date())
        let expectedGuruDate = Calendar.current.startOfHour(for: Date()).addingTimeInterval(4 * .oneHour + 4 * .oneHour + 8 * .oneHour + 23 * .oneHour)
        
        let guruDate = subject.earliestGuruDate(assignment: assignment) { _ in
            XCTFail("Did not expect assignment fetch for radical")
            return nil
        }
        
        XCTAssertEqual(guruDate, expectedGuruDate)
    }
    
    func testRadical_PassedAssignment() {
        let subject = makeRadical()
        let assignment = makeAssignment(srsStage: .guru, availableAt: Date().addingTimeInterval(-5 * .oneDay))
        
        let guruDate = subject.earliestGuruDate(assignment: assignment) { _ in
            XCTFail("Did not expect assignment fetch for radical")
            return nil
        }
        
        XCTAssertNil(guruDate)
    }
    
    func testKanji_NoAssignment_NoComponentAssignments() {
        let subject = makeKanji()
        
        let guruDate = subject.earliestGuruDate(assignment: nil) { _ in
            return nil
        }
        
        XCTAssertNil(guruDate)
    }
    
    func testKanji_NoAssignment_AtLeastOneMissingComponentAssignments() {
        let subject = makeKanji()
        
        let guruDate = subject.earliestGuruDate(assignment: nil) { subjectID in
            return subjectID == 0 ? nil : makeAssignment(srsStage: .apprentice, availableAt: nil)
        }
        
        XCTAssertNil(guruDate)
    }
    
    func testKanji_NoAssignment_AtLeastOneLockedComponentAssignments() {
        let subject = makeKanji()
        
        let guruDate = subject.earliestGuruDate(assignment: nil) { subjectID in
            return makeAssignment(srsStage: subjectID == 0 ? .guru : .initiate, availableAt: nil)
        }
        
        XCTAssertNil(guruDate)
    }
    
    func testKanji_NoAssignment_ApprenticeComponentAssignments() {
        let subject = makeKanji()
        let expectedGuruDate = Calendar.current.startOfHour(for: Date()).addingTimeInterval((4 * .oneHour + 4 * .oneHour + 8 * .oneHour + 23 * .oneHour) * 2)
        
        let guruDate = subject.earliestGuruDate(assignment: nil) { _ in
            return makeAssignment(srsStage: .apprentice, availableAt: Calendar.current.startOfHour(for: Date()).addingTimeInterval(4 * .oneHour))
        }
        
        XCTAssertEqual(guruDate, expectedGuruDate)
    }
    
    func testKanji_NoAssignment_GuruComponentAssignments() {
        let subject = makeKanji()
        let expectedGuruDate = Calendar.current.startOfHour(for: Date()).addingTimeInterval(4 * .oneHour + 4 * .oneHour + 8 * .oneHour + 23 * .oneHour)
        
        let guruDate = subject.earliestGuruDate(assignment: nil) { _ in
            return makeAssignment(srsStage: .guru, availableAt: Calendar.current.startOfHour(for: Date()))
        }
        
        XCTAssertEqual(guruDate, expectedGuruDate)
    }
    
    func testKanji_Assignment_GuruComponentAssignments() {
        let subject = makeKanji()
        let assignment = makeAssignment(srsStage: .initiate, availableAt: Date())
        let expectedGuruDate = Calendar.current.startOfHour(for: Date()).addingTimeInterval(4 * .oneHour + 4 * .oneHour + 8 * .oneHour + 23 * .oneHour)
        
        let guruDate = subject.earliestGuruDate(assignment: assignment) { _ in
            return makeAssignment(srsStage: .guru, availableAt: Calendar.current.startOfHour(for: Date()))
        }
        
        XCTAssertEqual(guruDate, expectedGuruDate)
    }
    
    func testKanji_GuruAssignment_GuruComponentAssignments() {
        let subject = makeKanji()
        let assignment = makeAssignment(srsStage: .guru, availableAt: Date())
        
        let guruDate = subject.earliestGuruDate(assignment: assignment) { _ in
            return makeAssignment(srsStage: .guru, availableAt: Calendar.current.startOfHour(for: Date()))
        }
        
        XCTAssertNil(guruDate)
    }
    
    private func makeRadical() -> Radical {
        return Radical(level: 1,
                       createdAt: Date(),
                       slug: "slug",
                       character: nil,
                       characterImages: [],
                       meanings: [],
                       documentURL: URL(string: "http://localhost")!)
    }
    
    private func makeKanji() -> Kanji {
        return Kanji(level: 1,
                     createdAt: Date(),
                     slug: "slug",
                     character: "char",
                     meanings: [],
                     readings: [],
                     componentSubjectIDs: [1, 2],
                     documentURL: URL(string: "http://localhost")!)
    }
    
    private func makeAssignment(srsStage: SRSStage, availableAt: Date?) -> Assignment {
        let srsStageNumeric = srsStage.numericLevelRange.lowerBound
        return Assignment(subjectID: 1,
                          subjectType: .radical,
                          level: 1,
                          srsStage: srsStageNumeric,
                          srsStageName: "",
                          unlockedAt: nil,
                          startedAt: nil,
                          passedAt: nil,
                          burnedAt: nil,
                          availableAt: availableAt,
                          isPassed: srsStage >= .guru,
                          isResurrected: false)
    }
    
}
