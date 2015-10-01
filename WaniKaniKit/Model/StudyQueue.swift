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

public enum StudyQueueReviewTime {
    case None, Now, FormattedString(String), UnformattedInterval(NSTimeInterval)
}

public extension StudyQueue {
    public func formattedNextReviewDate(referenceDate: NSDate = NSDate()) -> String? {
        guard let nextReviewDate = self.nextReviewDate else {
            return nil
        }

        let calendar = NSCalendar.autoupdatingCurrentCalendar()
        if calendar.isDate(referenceDate, inSameDayAsDate: nextReviewDate) {
            // Matching date, so only return the time of day
            return NSDateFormatter.localizedStringFromDate(nextReviewDate, dateStyle: .NoStyle, timeStyle: .ShortStyle)
        } else {
            return NSDateFormatter.localizedStringFromDate(nextReviewDate, dateStyle: .MediumStyle, timeStyle: .ShortStyle)
        }
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

    public func formattedTimeToNextReview(formatter: NSDateComponentsFormatter? = nil) -> StudyQueueReviewTime {
        guard let nextReviewDate = self.nextReviewDate else {
            return .None
        }
        
        let secondsUntilNextReview = nextReviewDate.timeIntervalSinceNow
        if secondsUntilNextReview <= 0 || reviewsAvailable > 0 {
            return .Now
        }
        
        // Since the UI only shows time remaining in minutes, round to the next whole minute before formatting
        let roundedSecondsUntilNextReview = secondsUntilNextReview + ((60 - (secondsUntilNextReview % 60)) % 60)
        let formatter = formatter ?? self.dynamicType.timeToNextReviewFormatter
        if let formatted = formatter.stringFromTimeInterval(roundedSecondsUntilNextReview) {
            return .FormattedString(formatted)
        }

        // It's not entirely clear when the date component formatter can fail, so we add this failsafe in case
        return .UnformattedInterval(secondsUntilNextReview)
    }
}
