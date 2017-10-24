//
//  LevelProgressTableViewCell.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit
import WaniKaniKit

class LevelProgressTableViewCell: UITableViewCell {
    
    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.roundingMode = .down
        formatter.roundingIncrement = 0.01
        return formatter
    }()
    
    private(set) var subjectType: SubjectType?
    
    // MARK: - Outlets
    
    @IBOutlet weak var subjectTypeLabel: UILabel!
    @IBOutlet weak var percentCompleteLabel: UILabel!
    @IBOutlet weak var totalItemCountLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    // MARK: - Update UI
    
    func update(subjectType: SubjectType, levelProgression: CurrentLevelProgression?) {
        self.subjectType = subjectType
        
        let fractionComplete: Double?
        let total: Int?
        switch subjectType {
        case .radical:
            subjectTypeLabel.text = "Radicals"
            fractionComplete = levelProgression?.radicalsFractionComplete
            total = levelProgression?.radicalsTotal
        case .kanji:
            subjectTypeLabel.text = "Kanji"
            fractionComplete = levelProgression?.kanjiFractionComplete
            total = levelProgression?.kanjiTotal
        case .vocabulary:
            fatalError("Vocabulary progression not supported")
        }
        
        let formattedFractionComplete = fractionComplete.flatMap { type(of: self).percentFormatter.string(from: $0 as NSNumber) } ?? "–%"
        percentCompleteLabel.text = formattedFractionComplete
        
        if let total = total {
            totalItemCountLabel.text = NumberFormatter.localizedString(from: total as NSNumber, number: .decimal)
        } else {
            totalItemCountLabel.text = "??"
        }
        
        progressView.tintColor = subjectType.backgroundColor
        
        if let fractionComplete = fractionComplete {
            progressView.setProgress(Float(fractionComplete), animated: fractionComplete > 0)
        } else {
            progressView.setProgress(0, animated: false)
        }
    }
    
}
