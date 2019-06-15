//
//  AssignmentProgressionCollectionViewCell.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit
import WaniKaniKit

private let dateComponentsFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.year, .month, .weekOfMonth, .day, .hour, .minute]
    formatter.maximumUnitCount = 2
    formatter.unitsStyle = .abbreviated
    formatter.zeroFormattingBehavior = .dropAll
    
    return formatter
}()

class AssignmentProgressionCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    var subjectProgression: SubjectProgression?
    
    // MARK: - Outlets
    
    @IBOutlet weak var characterView: SubjectCharacterView!
    @IBOutlet weak var timeToNextReviewLabel: UILabel!
    @IBOutlet weak var timeToNextMilestoneStageValueLabel: UILabel!
    @IBOutlet weak var timeToNextMilestoneStageNameLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    // MARK: - Update UI
    
    func updateUI() {
        guard let subjectProgression = self.subjectProgression else {
            fatalError()
        }
        
        let isLocked = subjectProgression.isLocked
        let subject = subjectProgression.subject
        
        characterView.setSubject(subject, id: subjectProgression.subjectID)
        backgroundColor = subject.subjectType.backgroundColor.withAlphaComponent(isLocked ? 0.5 : 1.0)
        progressView.progressTintColor = subject.subjectType.backgroundColor.withAlphaComponent(0.4)
        
        if isLocked {
            timeToNextReviewLabel.text = "Locked"
        } else {
            setNextReviewTime(subjectProgression.availableAt)
        }
        
        if !subjectProgression.isPassed {
            setTimeToNextMilestone(subjectProgression.guruTime, name: "Guru")
        } else {
            setTimeToNextMilestone(subjectProgression.burnTime, name: "Burned")
        }
        
        progressView.setProgress(subjectProgression.percentComplete, animated: false)
    }
    
    private func setNextReviewTime(_ nextReviewTime: NextReviewTime) {
        switch nextReviewTime {
        case .none:
            timeToNextReviewLabel.text = "Burned"
        case .now:
            timeToNextReviewLabel.text = "Now"
        case let .date(date) where date.timeIntervalSinceNow <= 0:
            timeToNextReviewLabel.text = "Now"
        case let .date(date):
            let formattedInterval = dateComponentsFormatter.string(from: date.timeIntervalSinceNow, roundingUpwardToNearest: .oneMinute) ?? "???"
            timeToNextReviewLabel.text = formattedInterval
        }
    }
    
    private func setTimeToNextMilestone(_ guruTime: NextReviewTime, name: String) {
        timeToNextMilestoneStageNameLabel.text = "To \(name)"
        
        switch guruTime {
        case .none, .now:
            timeToNextMilestoneStageValueLabel.text = "-"
        case let .date(date) where date.timeIntervalSinceNow <= 0:
            timeToNextMilestoneStageValueLabel.text = "-"
        case let .date(date):
            let formattedInterval = dateComponentsFormatter.string(from: date.timeIntervalSinceNow, roundingUpwardToNearest: .oneMinute) ?? "???"
            timeToNextMilestoneStageValueLabel.text = formattedInterval
        }
    }
    
}
