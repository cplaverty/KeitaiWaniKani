//
//  SubjectProgression.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct SubjectProgression {
    public let subject: Subject
    public let assignment: Assignment?
    public let isPassed: Bool
    public let availableAt: NextReviewTime?
    public let guruTime: NextReviewTime
    public let percentComplete: Float
    
    public init(subject: Subject, assignment: Assignment?, getAssignmentForSubjectID: (Int) -> Assignment?) {
        self.subject = subject
        self.assignment = assignment
        self.isPassed = assignment?.isPassed ?? false
        self.availableAt = type(of: self).availableAt(assignment: assignment)
        self.guruTime = type(of: self).guruTime(subject: subject, assignment: assignment, getAssignmentForSubjectID: getAssignmentForSubjectID)
        self.percentComplete = type(of: self).percentComplete(assignment: assignment)
    }
    
    private static func availableAt(assignment: Assignment?) -> NextReviewTime? {
        guard let assignment = assignment, assignment.srsStage > 0 else {
            return nil
        }
        
        return NextReviewTime(date: assignment.availableAt)
    }
    
    private static func guruTime(subject: Subject, assignment: Assignment?, getAssignmentForSubjectID: (Int) -> Assignment?) -> NextReviewTime {
        let unlockDateForLockedItems: Date?
        if subject.componentSubjectIDs.isEmpty {
            unlockDateForLockedItems = Date()
        } else {
            let guruDatesForComponents = subject.componentSubjectIDs.map { componentSubjectID in
                getAssignmentForSubjectID(componentSubjectID)?.guruDate(unlockDateForLockedItems: nil)
            }
            unlockDateForLockedItems = guruDatesForComponents.contains { $0 == nil } ? nil : guruDatesForComponents.lazy.flatMap { $0 }.min()
        }
        
        let guruDate: Date?
        if let assignment = assignment {
            guruDate = assignment.guruDate(unlockDateForLockedItems: unlockDateForLockedItems)
        } else if let unlockDateForLockedItems = unlockDateForLockedItems {
            guruDate = Assignment.earliestDate(from: unlockDateForLockedItems,
                                               forItemAtSRSStage: SRSStage.apprentice.numericLevelRange.lowerBound,
                                               toSRSStage: SRSStage.guru.numericLevelRange.lowerBound,
                                               withLevel: subject.level)
        } else {
            guruDate = nil
        }
        
        return NextReviewTime(date: guruDate)
    }
    
    private static func percentComplete(assignment: Assignment?) -> Float {
        guard let assignment = assignment else {
            return 0
        }
        
        let guruStage = SRSStage.guru.numericLevelRange.lowerBound
        let currentStage = assignment.srsStage
        return min(Float(currentStage) / Float(guruStage), 1.0)
    }
}
