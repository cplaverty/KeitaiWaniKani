//
//  SubjectProgression.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct SubjectProgression {
    public let subjectID: Int
    public let subject: Subject
    public let assignment: Assignment?
    public let percentComplete: Float
    
    private let earliestGuruDate: Date?
    private let earliestBurnDate: Date?
    
    public var isLocked: Bool {
        return assignment == nil || assignment!.srsStage == 0
    }
    
    public var isPassed: Bool {
        return assignment?.isPassed ?? false
    }
    
    public var availableAt: NextReviewTime {
        return NextReviewTime(date: assignment?.availableAt)
    }
    
    public var guruTime: NextReviewTime {
        return NextReviewTime(date: earliestGuruDate)
    }
    
    public var burnTime: NextReviewTime {
        return NextReviewTime(date: earliestBurnDate)
    }
    
    public init(subjectID: Int, subject: Subject, assignment: Assignment?, getAssignmentForSubjectID: (Int) -> Assignment?) {
        self.subjectID = subjectID
        self.subject = subject
        self.assignment = assignment
        self.earliestGuruDate = subject.earliestGuruDate(assignment: assignment, getAssignmentForSubjectID: getAssignmentForSubjectID)
        self.earliestBurnDate = subject.earliestBurnDate(assignment: assignment, getAssignmentForSubjectID: getAssignmentForSubjectID)
        self.percentComplete = min(Float(assignment?.srsStage ?? 0) / Float(SRSStage.guru.numericLevelRange.lowerBound), 1.0)
    }
}
