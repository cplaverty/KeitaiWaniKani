//
//  StudyQueueTableViewCell.swift
//  WaniKaniStudyQueueWidget
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
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
        formatter.zeroFormattingBehavior = .dropAll
        
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
        
        switch studyQueue.nextReviewTime {
        case .none:
            timeToNextReviewLabel?.text = "–"
        case .now:
            timeToNextReviewLabel?.text = "Now"
        case let .date(date):
            timeToNextReviewLabel?.text = type(of: self).timeToNextReviewFormatter.string(from: date.timeIntervalSinceNow, roundingUpwardToNearest: .oneMinute) ?? "???"
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
        
        timeToNextReviewLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        associatedValueLabel.font = UIFont.preferredFont(forTextStyle: .title1)
    }
}
