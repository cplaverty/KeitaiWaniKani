//
//  StudyQueueTableViewCell.swift
//  AlliCrab
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import WaniKaniKit

class StudyQueueTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    
    private static let timeToNextReviewFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.year, .month, .weekOfMonth, .day, .hour, .minute]
        formatter.maximumUnitCount = 1
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = [.dropLeading, .dropTrailing]
        
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
            return
        }
        
        switch studyQueue.formattedTimeToNextReview(type(of: self).timeToNextReviewFormatter) {
        case .none:
            timeToNextReviewLabel?.text = "–"
        case .now:
            timeToNextReviewLabel?.text = "Now"
        case .formattedString(let formattedInterval):
            timeToNextReviewLabel?.text = formattedInterval
        case .unformattedInterval(let secondsUntilNextReview):
            timeToNextReviewLabel?.text = "\(NumberFormatter.localizedString(from: NSNumber(value: secondsUntilNextReview), number: .decimal))s"
        }
        
        if studyQueue.reviewsAvailable > 0 {
            associatedNameLabel?.text = "Reviews"
            associatedValueLabel?.text = NumberFormatter.localizedString(from: NSNumber(value: studyQueue.reviewsAvailable), number: .decimal)
            return
        }
        
        associatedNameLabel?.text = "Next Day"
        associatedValueLabel?.text = NumberFormatter.localizedString(from: NSNumber(value: studyQueue.reviewsAvailableNextDay), number: .decimal)
        return
    }
    
    override func prepareForReuse() {
        timeToNextReviewLabel?.text = "–"
        associatedNameLabel?.text = nil
        associatedValueLabel?.text = nil
        
        if #available(iOSApplicationExtension 9.0, *) {
            timeToNextReviewLabel.font = UIFont.preferredFont(forTextStyle: .title1)
            associatedValueLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        } else {
            timeToNextReviewLabel.font = UIFont.systemFont(ofSize: 35, weight: UIFontWeightThin)
            associatedValueLabel.font = UIFont.systemFont(ofSize: 35, weight: UIFontWeightThin)
        }
    }
}
