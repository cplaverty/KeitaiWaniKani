//
//  StudyQueueTableViewCell.swift
//  WaniKaniStudyQueueWidget
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit
import WaniKaniKit

private let timeToNextReviewFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.year, .month, .weekOfMonth, .day, .hour, .minute]
    formatter.maximumUnitCount = 1
    formatter.unitsStyle = .abbreviated
    formatter.zeroFormattingBehavior = .dropAll
    
    return formatter
}()

class StudyQueueTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    
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
            timeToNextReviewLabel?.text = timeToNextReviewFormatter.string(from: date.timeIntervalSinceNow, roundingUpwardToNearest: .oneMinute) ?? "???"
        }
        
        if studyQueue.reviewsAvailable > 0 {
            associatedNameLabel?.text = "Reviews"
            associatedValueLabel?.text = NumberFormatter.localizedString(from: studyQueue.reviewsAvailable as NSNumber, number: .decimal)
        } else {
            associatedNameLabel?.text = "Next Day"
            associatedValueLabel?.text = NumberFormatter.localizedString(from: studyQueue.reviewsAvailableNextDay as NSNumber, number: .decimal)
        }
    }
    
    override func prepareForReuse() {
        timeToNextReviewLabel?.text = "–"
        associatedNameLabel?.text = nil
        associatedValueLabel?.text = nil
    }
}
