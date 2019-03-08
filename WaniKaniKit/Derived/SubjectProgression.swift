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
    
    public var isLocked: Bool {
        get {
            return assignment == nil || assignment!.srsStage == 0
        }
    }
    
    public var isPassed: Bool {
        get {
            return assignment?.isPassed ?? false
        }
    }
    
    public var availableAt: NextReviewTime {
        get {
            return NextReviewTime(date: assignment?.availableAt)
        }
    }
    
    public var guruTime: NextReviewTime {
        get {
            return NextReviewTime(date: earliestGuruDate)
        }
    }
    
    public init(subjectID: Int, subject: Subject, assignment: Assignment?, getAssignmentForSubjectID: (Int) -> Assignment?) {
        self.subjectID = subjectID
        self.subject = subject
        self.assignment = assignment
        self.earliestGuruDate = subject.earliestGuruDate(assignment: assignment, getAssignmentForSubjectID: getAssignmentForSubjectID)
        self.percentComplete = min(Float(assignment?.srsStage ?? 0) / Float(SRSStage.guru.numericLevelRange.lowerBound), 1.0)
    }
}
