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
    public let isLocked: Bool
    public let isPassed: Bool
    public let availableAt: NextReviewTime
    public let guruTime: NextReviewTime
    public let percentComplete: Float
    
    public init(subjectID: Int, subject: Subject, assignment: Assignment?, getAssignmentForSubjectID: (Int) -> Assignment?) {
        self.subjectID = subjectID
        self.subject = subject
        self.assignment = assignment
        self.isLocked = assignment == nil || assignment!.srsStage == 0
        self.isPassed = assignment?.isPassed ?? false
        self.availableAt = NextReviewTime(date: assignment?.availableAt)
        self.guruTime = NextReviewTime(date: subject.earliestGuruDate(assignment: assignment, getAssignmentForSubjectID: getAssignmentForSubjectID))
        self.percentComplete = min(Float(assignment?.srsStage ?? 0) / Float(SRSStage.guru.numericLevelRange.lowerBound), 1.0)
    }
}
