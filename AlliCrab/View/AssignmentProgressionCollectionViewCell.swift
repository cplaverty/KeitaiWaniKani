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
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var timeToNextReviewLabel: UILabel!
    @IBOutlet weak var timeToGuruLabel: UILabel!
    
    // MARK: - Update UI
    
    func updateUI() {
        guard let subjectProgression = self.subjectProgression else {
            fatalError()
        }
        
        let isLocked = subjectProgression.isLocked
        let availableAt = subjectProgression.availableAt
        let guruTime = subjectProgression.guruTime
        let percentComplete = subjectProgression.percentComplete
        let subject = subjectProgression.subject
        
        characterView.setSubject(subject, id: subjectProgression.subjectID)
        backgroundColor = subject.subjectType.backgroundColor.withAlphaComponent(isLocked ? 0.5 : 1.0)
        progressView.progressTintColor = subject.subjectType.backgroundColor.withAlphaComponent(0.4)
        
        if isLocked {
            timeToNextReviewLabel.text = "Locked"
        } else {
            switch availableAt {
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
        
        switch guruTime {
        case .none, .now:
            timeToGuruLabel.text = "-"
        case let .date(date) where date.timeIntervalSinceNow <= 0:
            timeToGuruLabel.text = "-"
        case let .date(date):
            let formattedInterval = dateComponentsFormatter.string(from: date.timeIntervalSinceNow, roundingUpwardToNearest: .oneMinute) ?? "???"
            timeToGuruLabel.text = formattedInterval
        }
        
        progressView.setProgress(percentComplete, animated: false)
    }
}
