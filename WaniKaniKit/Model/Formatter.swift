//
//  Formatter.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public enum FormattedTimeInterval {
    case None, Now, FormattedString(String), UnformattedInterval(NSTimeInterval)
}

public struct Formatter {
    
    private static let defaultFormatter: NSDateComponentsFormatter = {
        let formatter = NSDateComponentsFormatter()
        formatter.allowedUnits = [.Year, .Month, .WeekOfMonth, .Day, .Hour, .Minute]
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .Abbreviated
        formatter.zeroFormattingBehavior = [.DropLeading, .DropTrailing]
        
        return formatter
        }()
    
    public static func formatTimeIntervalToDate(date: NSDate?, formatter: NSDateComponentsFormatter = defaultFormatter) -> FormattedTimeInterval {
        guard let nextReviewDate = date else {
            return .None
        }
        
        let secondsUntilNextReview = nextReviewDate.timeIntervalSinceNow
        if secondsUntilNextReview <= 0 {
            return .Now
        }
        
        // Since the default formatter only shows time remaining in minutes, round to the next whole minute before formatting
        let roundedSecondsUntilNextReview = secondsUntilNextReview + ((60 - (secondsUntilNextReview % 60)) % 60)
        if let formatted = formatter.stringFromTimeInterval(roundedSecondsUntilNextReview) {
            return .FormattedString(formatted)
        }
        
        // It's not entirely clear when the date component formatter can fail, so we add this failsafe in case
        return .UnformattedInterval(secondsUntilNextReview)
    }
    
}
