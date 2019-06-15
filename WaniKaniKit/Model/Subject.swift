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
    var subjectType: SubjectType { get }
    var level: Int { get }
    var slug: String { get }
    var documentURL: URL { get }
    var meanings: [Meaning] { get }
    var readings: [Reading] { get }
    var componentSubjectIDs: [Int] { get }
    var lessonPosition: Int { get }
}

public extension Subject {
    var primaryMeaning: String? {
        get {
            return meanings.lazy.filter({ $0.isPrimary }).map({ $0.meaning }).first
        }
    }
    
    var primaryReading: String? {
        get {
            return readings.lazy.filter({ $0.isPrimary }).map({ $0.reading }).first
        }
    }
    
    func earliestGuruDate(assignment: Assignment?, getAssignmentForSubjectID: (Int) -> Assignment?) -> Date? {
        if let assignment = assignment, assignment.isPassed == true {
            return assignment.passedAt ?? Date.distantPast
        }
        
        let pendingSubjectAssignments = componentSubjectIDs
            .map({ componentSubjectID in getAssignmentForSubjectID(componentSubjectID) })
            .filter({ assignment in assignment?.isPassed != true })
        
        if let assignment = assignment, pendingSubjectAssignments.isEmpty {
            return assignment.guruDate(subjectLevel: level)
        }
        
        let unlockDateForLockedItems: Date?
        if pendingSubjectAssignments.isEmpty {
            unlockDateForLockedItems = Calendar.current.startOfHour(for: Date())
        } else {
            let guruDates = pendingSubjectAssignments.map({ assignment in assignment?.guruDate(subjectLevel: level) })
            unlockDateForLockedItems = guruDates.allSatisfy({ $0 != nil }) ? guruDates.lazy.compactMap({ $0 }).max() : nil
        }
        
        if let unlockDateForLockedItems = unlockDateForLockedItems {
            return Assignment.earliestDate(from: unlockDateForLockedItems,
                                           forItemAtSRSStage: SRSStage.apprentice.numericLevelRange.lowerBound,
                                           toSRSStage: SRSStage.guru.numericLevelRange.lowerBound,
                                           subjectType: subjectType,
                                           subjectLevel: level)
        } else {
            return nil
        }
    }
    
    func earliestBurnDate(assignment: Assignment?, getAssignmentForSubjectID: (Int) -> Assignment?) -> Date? {
        if let assignment = assignment, let burnedAt = assignment.burnedAt {
            return burnedAt
        }
        
        let pendingSubjectAssignments = componentSubjectIDs
            .map({ componentSubjectID in getAssignmentForSubjectID(componentSubjectID) })
            .filter({ assignment in assignment?.isPassed != true })
        
        if let assignment = assignment, pendingSubjectAssignments.isEmpty {
            return assignment.burnDate(subjectLevel: level)
        }
        
        let unlockDateForLockedItems: Date?
        if pendingSubjectAssignments.isEmpty {
            unlockDateForLockedItems = Calendar.current.startOfHour(for: Date())
        } else {
            let guruDates = pendingSubjectAssignments.map({ assignment in assignment?.guruDate(subjectLevel: level) })
            unlockDateForLockedItems = guruDates.allSatisfy({ $0 != nil }) ? guruDates.lazy.compactMap({ $0 }).max() : nil
        }
        
        if let unlockDateForLockedItems = unlockDateForLockedItems {
            return Assignment.earliestDate(from: unlockDateForLockedItems,
                                           forItemAtSRSStage: SRSStage.apprentice.numericLevelRange.lowerBound,
                                           toSRSStage: SRSStage.burned.numericLevelRange.lowerBound,
                                           subjectType: subjectType,
                                           subjectLevel: level)
        } else {
            return nil
        }
    }
}
