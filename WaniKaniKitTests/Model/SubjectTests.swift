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
        let expectedGuruDate = Calendar.current.startOfHour(for: Date()).addingTimeInterval(2 * .oneHour + 4 * .oneHour + 8 * .oneHour + 23 * .oneHour)
        
        let guruDate = subject.earliestGuruDate(assignment: nil) { _ in
            XCTFail("Did not expect assignment fetch for radical")
            return nil
        }
        
        XCTAssertEqual(guruDate, expectedGuruDate)
    }
    
    func testRadical_LockedAssignment() {
        let subject = makeRadical()
        let assignment = makeAssignment(srsStage: .initiate, availableAt: Date())
        let expectedGuruDate = Calendar.current.startOfHour(for: Date()).addingTimeInterval(2 * .oneHour + 4 * .oneHour + 8 * .oneHour + 23 * .oneHour)
        
        let guruDate = subject.earliestGuruDate(assignment: assignment) { _ in
            XCTFail("Did not expect assignment fetch for radical")
            return nil
        }
        
        XCTAssertEqual(guruDate, expectedGuruDate)
    }
    
    func testRadical_PassedAssignment() {
        let subject = makeRadical()
        let passedAt = Date().addingTimeInterval(-1 * .oneDay)
        let assignment = makeAssignment(srsStage: .guru, availableAt: Date().addingTimeInterval(-5 * .oneDay), passedAt: passedAt)
        
        let guruDate = subject.earliestGuruDate(assignment: assignment) { _ in
            XCTFail("Did not expect assignment fetch for radical")
            return nil
        }
        
        XCTAssertEqual(guruDate, passedAt)
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
            return subjectID == 0 || subjectID == 1 ? nil : makeAssignment(srsStage: .apprentice, availableAt: nil)
        }
        
        XCTAssertNil(guruDate)
    }
    
    func testKanji_NoAssignment_AtLeastOneLockedComponentAssignments() {
        let subject = makeKanji()
        let expectedGuruDate = Calendar.current.startOfHour(for: Date()).addingTimeInterval((2 * .oneHour + 4 * .oneHour + 8 * .oneHour + 23 * .oneHour) * 2)
        
        let guruDate = subject.earliestGuruDate(assignment: nil) { subjectID in
            return makeAssignment(srsStage: subjectID == 1 ? .guru : .initiate, availableAt: nil)
        }
        
        XCTAssertEqual(guruDate, expectedGuruDate)
    }
    
    func testKanji_NoAssignment_ApprenticeComponentAssignments() {
        let subject = makeKanji()
        let expectedGuruDate = Calendar.current.startOfHour(for: Date()).addingTimeInterval((2 * .oneHour + 4 * .oneHour + 8 * .oneHour + 23 * .oneHour) * 2)
        
        let guruDate = subject.earliestGuruDate(assignment: nil) { _ in
            return makeAssignment(srsStage: .apprentice, availableAt: Calendar.current.startOfHour(for: Date()).addingTimeInterval(2 * .oneHour))
        }
        
        XCTAssertEqual(guruDate, expectedGuruDate)
    }
    
    func testKanji_NoAssignment_GuruComponentAssignments() {
        let subject = makeKanji()
        let expectedGuruDate = Calendar.current.startOfHour(for: Date()).addingTimeInterval(2 * .oneHour + 4 * .oneHour + 8 * .oneHour + 23 * .oneHour)
        
        let guruDate = subject.earliestGuruDate(assignment: nil) { _ in
            return makeAssignment(srsStage: .guru, availableAt: Calendar.current.startOfHour(for: Date()))
        }
        
        XCTAssertEqual(guruDate, expectedGuruDate)
    }
    
    func testKanji_Assignment_GuruComponentAssignments() {
        let subject = makeKanji()
        let assignment = makeAssignment(srsStage: .initiate, availableAt: Date())
        let expectedGuruDate = Calendar.current.startOfHour(for: Date()).addingTimeInterval(2 * .oneHour + 4 * .oneHour + 8 * .oneHour + 23 * .oneHour)
        
        let guruDate = subject.earliestGuruDate(assignment: assignment) { _ in
            return makeAssignment(srsStage: .guru, availableAt: Calendar.current.startOfHour(for: Date()))
        }
        
        XCTAssertEqual(guruDate, expectedGuruDate)
    }
    
    func testKanji_GuruAssignment_GuruComponentAssignments() {
        let subject = makeKanji()
        let passedAt = Date().addingTimeInterval(-1 * .oneDay)
        let assignment = makeAssignment(srsStage: .guru, availableAt: Date().addingTimeInterval(-5 * .oneDay), passedAt: passedAt)
        
        let guruDate = subject.earliestGuruDate(assignment: assignment) { _ in
            return makeAssignment(srsStage: .guru,
                                  availableAt: Calendar.current.startOfHour(for: Date()).addingTimeInterval(-10 * .oneDay),
                                  passedAt: Calendar.current.startOfHour(for: Date()).addingTimeInterval(-5 * .oneDay))
        }
        
        XCTAssertEqual(guruDate, passedAt)
    }
    
    private func makeRadical() -> Radical {
        return Radical(createdAt: Date(),
                       level: 1,
                       slug: "slug",
                       hiddenAt: nil,
                       documentURL: URL(string: "http://localhost")!,
                       characters: nil,
                       characterImages: [],
                       meanings: [],
                       auxiliaryMeanings: [],
                       amalgamationSubjectIDs: [1],
                       meaningMnemonic: "",
                       lessonPosition: 0)
    }
    
    private func makeKanji() -> Kanji {
        return Kanji(createdAt: Date(),
                     level: 1,
                     slug: "slug",
                     hiddenAt: nil,
                     documentURL: URL(string: "http://localhost")!,
                     characters: "char",
                     meanings: [],
                     auxiliaryMeanings: [],
                     readings: [],
                     componentSubjectIDs: [1, 2],
                     amalgamationSubjectIDs: [],
                     visuallySimilarSubjectIDs: [],
                     meaningMnemonic: "",
                     meaningHint: "",
                     readingMnemonic: "",
                     readingHint: "",
                     lessonPosition: 0)
    }
    
    private func makeAssignment(srsStage: SRSStage, availableAt: Date? = nil, passedAt: Date? = nil) -> Assignment {
        let srsStageNumeric = srsStage.numericLevelRange.lowerBound
        return Assignment(createdAt: Date(),
                          subjectID: 1,
                          subjectType: .radical,
                          srsStage: srsStageNumeric,
                          srsStageName: "",
                          unlockedAt: nil,
                          startedAt: nil,
                          passedAt: passedAt,
                          burnedAt: nil,
                          availableAt: availableAt,
                          resurrectedAt: nil,
                          isPassed: srsStage >= .guru,
                          isHidden: false)
    }
    
}
