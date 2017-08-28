//
//  StudyQueue.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public enum NextReviewTime: Equatable {
    case none
    case now
    case date(Date)
    
    public init(date: Date?) {
        guard let date = date else {
            self = .none
            return
        }
        
        if date.timeIntervalSinceNow <= 0 {
            self = .now
        } else {
            self = .date(date)
        }
    }
}

extension NextReviewTime {
    public static func ==(lhs: NextReviewTime, rhs: NextReviewTime) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none), (.now, .now):
            return true
        case let (.date(ldate), .date(rdate)):
            return ldate == rdate
        default:
            return false
        }
    }
}

public struct StudyQueue: Equatable {
    public let lessonsAvailable: Int
    public let reviewsAvailable: Int
    private let nextReviewDate: Date?
    public let reviewsAvailableNextHour: Int
    public let reviewsAvailableNextDay: Int
    
    public var nextReviewTime: NextReviewTime {
        guard reviewsAvailable == 0 else {
            return .now
        }
        
        return NextReviewTime(date: nextReviewDate)
    }
    
    public init(lessonsAvailable: Int, reviewsAvailable: Int, nextReviewDate: Date?, reviewsAvailableNextHour: Int, reviewsAvailableNextDay: Int) {
        self.lessonsAvailable = lessonsAvailable
        self.reviewsAvailable = reviewsAvailable
        self.nextReviewDate = nextReviewDate
        self.reviewsAvailableNextHour = reviewsAvailableNextHour
        self.reviewsAvailableNextDay = reviewsAvailableNextDay
    }
}

extension StudyQueue {
    public static func ==(lhs: StudyQueue, rhs: StudyQueue) -> Bool {
        return lhs.lessonsAvailable == rhs.lessonsAvailable
            && lhs.reviewsAvailable == rhs.reviewsAvailable
            && lhs.nextReviewTime == rhs.nextReviewTime
            && lhs.reviewsAvailableNextHour == rhs.reviewsAvailableNextHour
            && lhs.reviewsAvailableNextDay == rhs.reviewsAvailableNextDay
    }
}
