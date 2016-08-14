//
//  Formatter.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public enum FormattedTimeInterval {
    case none, now, formattedString(String), unformattedInterval(TimeInterval)
}

public struct Formatter {
    
    private static let defaultFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.year, .month, .weekOfMonth, .day, .hour, .minute]
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = [.dropLeading, .dropTrailing]
        
        return formatter
    }()
    
    public static func formatTimeIntervalSinceNow(from date: Date?, formatter: DateComponentsFormatter = defaultFormatter) -> FormattedTimeInterval {
        guard let nextReviewDate = date else {
            return .none
        }
        
        let secondsUntilNextReview = nextReviewDate.timeIntervalSinceNow
        if secondsUntilNextReview <= 0 {
            return .now
        }
        
        // Since the default formatter only shows time remaining in minutes, round to the next whole minute before formatting
        let roundedSecondsUntilNextReview = secondsUntilNextReview + (60 - secondsUntilNextReview.truncatingRemainder(dividingBy: 60)).truncatingRemainder(dividingBy: 60)
        if let formatted = formatter.string(from: roundedSecondsUntilNextReview) {
            return .formattedString(formatted)
        }
        
        // It's not entirely clear when the date component formatter can fail, so we add this failsafe in case
        return .unformattedInterval(secondsUntilNextReview)
    }
    
}
