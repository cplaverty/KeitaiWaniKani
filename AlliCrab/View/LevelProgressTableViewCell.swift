//
//  LevelProgressTableViewCell.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit
import WaniKaniKit

class LevelProgressTableViewCell: UITableViewCell {
    
    private(set) var subjectType: SubjectType?
    
    // MARK: - Outlets
    
    @IBOutlet weak var progressBarView: ProgressBarView!
    
    // MARK: - Update UI
    
    func update(subjectType: SubjectType, levelProgression: CurrentLevelProgression?) {
        self.subjectType = subjectType
        
        let fractionComplete: Double?
        let total: Int?
        switch subjectType {
        case .radical:
            progressBarView.title = "Radicals"
            fractionComplete = levelProgression?.radicalsFractionComplete
            total = levelProgression?.radicalsTotal
        case .kanji:
            progressBarView.title = "Kanji"
            fractionComplete = levelProgression?.kanjiFractionComplete
            total = levelProgression?.kanjiTotal
        case .vocabulary:
            fatalError("Vocabulary progression not supported")
        }
        
        progressBarView.totalCount = total ?? 0
        progressBarView.progressView.tintColor = subjectType.backgroundColor
        progressBarView.progress = Float(fractionComplete ?? 0.0)
    }
    
}
