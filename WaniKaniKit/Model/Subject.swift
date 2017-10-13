//
//  Subject.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public enum SubjectType: String, Codable {
    case radical
    case kanji
    case vocabulary
}

public extension SubjectType {
    var backgroundColor: UIColor {
        switch self {
        case .radical:
            return .waniKaniRadical
        case .kanji:
            return .waniKaniKanji
        case .vocabulary:
            return .waniKaniVocabulary
        }
    }
}

public protocol Subject {
    var level: Int { get }
    var subjectType: SubjectType { get }
    var slug: String { get }
    var componentSubjectIDs: [Int] { get }
    var documentURL: URL { get }
}

extension Subject {
    public func earliestGuruDate(assignment: Assignment?, getAssignmentForSubjectID: (Int) -> Assignment?) -> Date? {
        if assignment?.isPassed == true {
            return nil
        }
        
        let pendingSubjectAssignments = componentSubjectIDs.map({ componentSubjectID in getAssignmentForSubjectID(componentSubjectID) })
            .filter( { assignment in assignment?.isPassed != true })
        
        let unlockDateForLockedItems: Date?
        if pendingSubjectAssignments.isEmpty {
            unlockDateForLockedItems = Date()
        } else {
            unlockDateForLockedItems = pendingSubjectAssignments.flatMap({ assignment in assignment?.guruDate(unlockDateForLockedItems: nil) }).min()
        }
        
        let guruDate: Date?
        if let assignment = assignment {
            guruDate = assignment.guruDate(unlockDateForLockedItems: unlockDateForLockedItems)
        } else if let unlockDateForLockedItems = unlockDateForLockedItems {
            guruDate = Assignment.earliestDate(from: unlockDateForLockedItems,
                                               forItemAtSRSStage: SRSStage.apprentice.numericLevelRange.lowerBound,
                                               toSRSStage: SRSStage.guru.numericLevelRange.lowerBound,
                                               subjectType: subjectType,
                                               level: level)
        } else {
            guruDate = nil
        }
        
        return guruDate
    }
}
