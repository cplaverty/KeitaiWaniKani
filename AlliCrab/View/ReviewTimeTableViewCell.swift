//
//  ReviewTimeTableViewCell.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit
import WaniKaniKit

class ReviewTimeTableViewCell: UITableViewCell {
    
    private static let timeToNextReviewFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.year, .month, .weekOfMonth, .day, .hour, .minute]
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        formatter.includesTimeRemainingPhrase = true
        
        return formatter
    }()
    
    private static let nextReviewDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        return formatter
    }()
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    func update(nextReviewDate: Date) {
        titleLabel.text = "Next Review"
        
        let formatter = type(of: self).nextReviewDateFormatter
        formatter.dateStyle = Calendar.current.isDateInToday(nextReviewDate) ? .none : .medium
        detailLabel.text = formatter.string(from: nextReviewDate)
        
        // Since the formatter only shows time remaining in minutes, round to the next whole minute
        subtitleLabel.text = type(of: self).timeToNextReviewFormatter.string(from: nextReviewDate.timeIntervalSinceNow, roundingUpwardToNearest: .oneMinute) ?? "???"
    }
    
}
