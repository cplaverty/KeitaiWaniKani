//
//  SubjectCollectionViewCell.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit
import WaniKaniKit

class SubjectCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    var subjectID: Int!
    
    var subject: Subject! {
        didSet {
            characterView.subject = subject
            backgroundColor = subject.subjectType.backgroundColor
            
            if let primaryReadingLabel = primaryReadingLabel {
                primaryReadingLabel.text = subject.primaryReading
            }
            if let primaryMeaningLabel = primaryMeaningLabel {
                primaryMeaningLabel.text = subject.primaryMeaning
            }
        }
    }
    
    var documentURL: URL {
        return subject.documentURL
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var characterView: SubjectCharacterView!
    @IBOutlet weak var primaryReadingLabel: UILabel!
    @IBOutlet weak var primaryMeaningLabel: UILabel!
    
}
