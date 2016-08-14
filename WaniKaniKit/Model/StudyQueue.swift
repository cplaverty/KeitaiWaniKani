//
//  StudyQueue.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public struct StudyQueue: Equatable {
    public let lessonsAvailable: Int
    public let reviewsAvailable: Int
    private let actualNextReviewDate: Date?
    public var nextReviewDate: Date? {
        guard let actualNextReviewDate = actualNextReviewDate else { return nil }
        
        // Provide a consistent Date when actualNextReviewDate is "Now"
        if reviewsAvailable > 0 && actualNextReviewDate <= lastUpdateTimestamp {
            return Date.distantPast
        } else {
            return actualNextReviewDate
        }
    }
    public let reviewsAvailableNextHour: Int
    public let reviewsAvailableNextDay: Int
    public let lastUpdateTimestamp: Date
    
    public init(lessonsAvailable: Int, reviewsAvailable: Int, nextReviewDate: Date? = nil, reviewsAvailableNextHour: Int, reviewsAvailableNextDay: Int, lastUpdateTimestamp: Date? = nil) {
        self.lessonsAvailable = lessonsAvailable
        self.reviewsAvailable = reviewsAvailable
        self.actualNextReviewDate = nextReviewDate
        self.reviewsAvailableNextHour = reviewsAvailableNextHour
        self.reviewsAvailableNextDay = reviewsAvailableNextDay
        self.lastUpdateTimestamp = lastUpdateTimestamp ?? Date()
    }
}

public func ==(lhs: StudyQueue, rhs: StudyQueue) -> Bool {
    return lhs.lessonsAvailable == rhs.lessonsAvailable &&
        lhs.reviewsAvailable == rhs.reviewsAvailable &&
        lhs.nextReviewDate == rhs.nextReviewDate &&
        lhs.reviewsAvailableNextHour == rhs.reviewsAvailableNextHour &&
        lhs.reviewsAvailableNextDay == rhs.reviewsAvailableNextDay
}

public extension StudyQueue {
    public func formattedNextReviewDate(_ referenceDate: Date = Date()) -> String? {
        guard let nextReviewDate = self.nextReviewDate else {
            return nil
        }
        
        let calendar = Calendar.autoupdatingCurrent
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = calendar.isDate(referenceDate, inSameDayAs: nextReviewDate) ? .none : .medium
        formatter.timeStyle = .short
        
        return formatter.string(from: nextReviewDate)
    }
    
    public static let timeToNextReviewFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.year, .month, .weekOfMonth, .day, .hour, .minute]
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = [.dropLeading, .dropTrailing]
        formatter.includesTimeRemainingPhrase = true
        
        return formatter
    }()
    
    public func formattedTimeToNextReview(_ formatter: DateComponentsFormatter = timeToNextReviewFormatter) -> FormattedTimeInterval {
        guard reviewsAvailable == 0 else {
            return .now
        }
        
        return Formatter.formatTimeIntervalSinceNow(from: self.nextReviewDate, formatter: formatter)
    }
}
