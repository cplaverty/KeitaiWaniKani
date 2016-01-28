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
    private let actualNextReviewDate: NSDate?
    public var nextReviewDate: NSDate? {
        guard let actualNextReviewDate = actualNextReviewDate else { return nil }
        
        // Provide a consistent NSDate when actualNextReviewDate is "Now"
        if reviewsAvailable > 0 && actualNextReviewDate <= lastUpdateTimestamp {
            return NSDate.distantPast()
        } else {
            return actualNextReviewDate
        }
    }
    public let reviewsAvailableNextHour: Int
    public let reviewsAvailableNextDay: Int
    public let lastUpdateTimestamp: NSDate
    
    public init(lessonsAvailable: Int, reviewsAvailable: Int, nextReviewDate: NSDate? = nil, reviewsAvailableNextHour: Int, reviewsAvailableNextDay: Int, lastUpdateTimestamp: NSDate? = nil) {
        self.lessonsAvailable = lessonsAvailable
        self.reviewsAvailable = reviewsAvailable
        self.actualNextReviewDate = nextReviewDate
        self.reviewsAvailableNextHour = reviewsAvailableNextHour
        self.reviewsAvailableNextDay = reviewsAvailableNextDay
        self.lastUpdateTimestamp = lastUpdateTimestamp ?? NSDate()
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
    public func formattedNextReviewDate(referenceDate: NSDate = NSDate()) -> String? {
        guard let nextReviewDate = self.nextReviewDate else {
            return nil
        }
        
        let calendar = NSCalendar.autoupdatingCurrentCalendar()
        let formatter = NSDateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = calendar.isDate(referenceDate, inSameDayAsDate: nextReviewDate) ? .NoStyle : .MediumStyle
        formatter.timeStyle = .ShortStyle
        
        return formatter.stringFromDate(nextReviewDate)
    }
    
    public static let timeToNextReviewFormatter: NSDateComponentsFormatter = {
        let formatter = NSDateComponentsFormatter()
        formatter.allowedUnits = [.Year, .Month, .WeekOfMonth, .Day, .Hour, .Minute]
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .Abbreviated
        formatter.zeroFormattingBehavior = [.DropLeading, .DropTrailing]
        formatter.includesTimeRemainingPhrase = true
        
        return formatter
    }()
    
    public func formattedTimeToNextReview(formatter: NSDateComponentsFormatter = timeToNextReviewFormatter) -> FormattedTimeInterval {
        guard reviewsAvailable == 0 else {
            return .Now
        }
        
        return Formatter.formatTimeIntervalToDate(self.nextReviewDate, formatter: formatter)
    }
}
