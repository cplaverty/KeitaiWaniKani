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

public protocol SubjectImage {
    var url: URL { get }
    var contentType: String { get }
}

public enum SubjectCharacterRepresentation {
    case unicode(String)
    case image([SubjectImage])
}

public protocol Subject {
    var subjectType: SubjectType { get }
    var level: Int { get }
    var slug: String { get }
    var documentURL: URL { get }
    var characterRepresentation: SubjectCharacterRepresentation { get }
    var meanings: [Meaning] { get }
    var readings: [Reading] { get }
    var componentSubjectIDs: [Int] { get }
    var lessonPosition: Int { get }
}

extension Subject {
    public func earliestGuruDate(assignment: Assignment?, getAssignmentForSubjectID: (Int) -> Assignment?) -> Date? {
        if assignment?.isPassed == true {
            return assignment?.passedAt ?? Date.distantPast
        }
        
        let pendingSubjectAssignments = componentSubjectIDs.map({ componentSubjectID in getAssignmentForSubjectID(componentSubjectID) })
            .filter({ assignment in assignment?.isPassed != true })
        
        let unlockDateForLockedItems: Date?
        if pendingSubjectAssignments.isEmpty {
            unlockDateForLockedItems = Calendar.current.startOfHour(for: Date())
        } else {
            let guruDates = pendingSubjectAssignments.map({ assignment in assignment?.guruDate(level: level) })
            unlockDateForLockedItems = guruDates.lazy.filter({ $0 == nil }).isEmpty ? guruDates.lazy.compactMap({ $0 }).max() : nil
        }
        
        let guruDate: Date?
        if let assignment = assignment {
            guruDate = assignment.guruDate(level: level)
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
