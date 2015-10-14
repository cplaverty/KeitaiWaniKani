//
//  StudyQueueTableViewCell.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import WaniKaniKit

class StudyQueueTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    
    private static let timeToNextReviewFormatter: NSDateComponentsFormatter = {
        let formatter = NSDateComponentsFormatter()
        formatter.allowedUnits = [.Year, .Month, .WeekOfMonth, .Day, .Hour, .Minute]
        formatter.maximumUnitCount = 1
        formatter.unitsStyle = .Abbreviated
        formatter.zeroFormattingBehavior = [.DropLeading, .DropTrailing]

        return formatter
        }()
    
    var studyQueue: StudyQueue? {
        didSet {
            updateUI()
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var timeToNextReviewLabel: UILabel!
    @IBOutlet weak var associatedValueLabel: UILabel!
    @IBOutlet weak var associatedNameLabel: UILabel!
    
    // MARK: - Update UI
    
    func updateUI() {
        guard let studyQueue = self.studyQueue else {
            timeToNextReviewLabel?.text = "–"
            associatedNameLabel?.text = nil
            associatedValueLabel?.text = nil
            return
        }
        
        switch studyQueue.formattedTimeToNextReview(self.dynamicType.timeToNextReviewFormatter) {
        case .None:
            timeToNextReviewLabel?.text = "–"
        case .Now:
            timeToNextReviewLabel?.text = "Now"
        case .FormattedString(let formattedInterval):
            timeToNextReviewLabel?.text = formattedInterval
        case .UnformattedInterval(let secondsUntilNextReview):
            timeToNextReviewLabel?.text = "\(NSNumberFormatter.localizedStringFromNumber(secondsUntilNextReview, numberStyle: .DecimalStyle))s"
        }
        
        if studyQueue.reviewsAvailable > 0 {
            associatedNameLabel?.text = "Reviews"
            associatedValueLabel?.text = NSNumberFormatter.localizedStringFromNumber(studyQueue.reviewsAvailable, numberStyle: .DecimalStyle)
            return
        }
        
        associatedNameLabel?.text = "Next Day"
        associatedValueLabel?.text = NSNumberFormatter.localizedStringFromNumber(studyQueue.reviewsAvailableNextDay, numberStyle: .DecimalStyle)
        return
    }
    
}
