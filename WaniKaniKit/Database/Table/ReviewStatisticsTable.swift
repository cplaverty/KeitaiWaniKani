//
//  ReviewStatisticsTable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

final class ReviewStatisticsTable: Table {
    let id = Column(name: "id", type: .int, nullable: false, primaryKey: true)
    let createdAt = Column(name: "created_at", type: .float, nullable: false)
    let subjectID = Column(name: "subject_id", type: .int, nullable: false, unique: true)
    let subjectType = Column(name: "subject_type", type: .text, nullable: false)
    let meaningCorrect = Column(name: "meaning_correct", type: .int, nullable: false)
    let meaningIncorrect = Column(name: "meaning_incorrect", type: .int, nullable: false)
    let meaningMaxStreak = Column(name: "meaning_max_streak", type: .int, nullable: false)
    let meaningCurrentStreak = Column(name: "meaning_current_streak", type: .int, nullable: false)
    let readingCorrect = Column(name: "reading_correct", type: .int, nullable: false)
    let readingIncorrect = Column(name: "reading_incorrect", type: .int, nullable: false)
    let readingMaxStreak = Column(name: "reading_max_streak", type: .int, nullable: false)
    let readingCurrentStreak = Column(name: "reading_current_streak", type: .int, nullable: false)
    let percentageCorrect = Column(name: "percentage_correct", type: .int, nullable: false)
    
    init() {
        super.init(name: "review_statistics")
    }
}
