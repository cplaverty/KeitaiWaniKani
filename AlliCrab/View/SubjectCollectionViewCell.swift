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
    
    private(set) var subjectID: Int = 0
    
    func setSubject(_ subject: Subject, id: Int) {
        subjectID = id
        characterView.setSubject(subject, id: id)
        
        backgroundColor = subject.subjectType.backgroundColor
        
        if let primaryReadingLabel = primaryReadingLabel {
            primaryReadingLabel.text = subject.primaryReading
        }
        if let primaryMeaningLabel = primaryMeaningLabel {
            primaryMeaningLabel.text = subject.primaryMeaning
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var characterView: SubjectCharacterView!
    @IBOutlet weak var primaryReadingLabel: UILabel!
    @IBOutlet weak var primaryMeaningLabel: UILabel!
    
}
