//
//  ReviewStatistics.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct ReviewStatistics: ResourceCollectionItemData {
    public let createdAt: Date
    public let subjectID: Int
    public let subjectType: SubjectType
    public let meaningCorrect: Int
    public let meaningIncorrect: Int
    public let meaningMaxStreak: Int
    public let meaningCurrentStreak: Int
    public let readingCorrect: Int
    public let readingIncorrect: Int
    public let readingMaxStreak: Int
    public let readingCurrentStreak: Int
    public let percentageCorrect: Int
    
    private enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case subjectID = "subject_id"
        case subjectType = "subject_type"
        case meaningCorrect = "meaning_correct"
        case meaningIncorrect = "meaning_incorrect"
        case meaningMaxStreak = "meaning_max_streak"
        case meaningCurrentStreak = "meaning_current_streak"
        case readingCorrect = "reading_correct"
        case readingIncorrect = "reading_incorrect"
        case readingMaxStreak = "reading_max_streak"
        case readingCurrentStreak = "reading_current_streak"
        case percentageCorrect = "percentage_correct"
    }
}

extension ReviewStatistics: Equatable {
    public static func ==(lhs: ReviewStatistics, rhs: ReviewStatistics) -> Bool {
        return lhs.createdAt == rhs.createdAt
            && lhs.subjectID == rhs.subjectID
            && lhs.subjectType == rhs.subjectType
            && lhs.meaningCorrect == rhs.meaningCorrect
            && lhs.meaningIncorrect == rhs.meaningIncorrect
            && lhs.meaningMaxStreak == rhs.meaningMaxStreak
            && lhs.meaningCurrentStreak == rhs.meaningCurrentStreak
            && lhs.readingCorrect == rhs.readingCorrect
            && lhs.readingIncorrect == rhs.readingIncorrect
            && lhs.readingMaxStreak == rhs.readingMaxStreak
            && lhs.readingCurrentStreak == rhs.readingCurrentStreak
            && lhs.percentageCorrect == rhs.percentageCorrect
    }
}
