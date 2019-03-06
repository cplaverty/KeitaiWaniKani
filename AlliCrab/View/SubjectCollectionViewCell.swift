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
                primaryReadingLabel.text = primaryReading
            }
            if let primaryMeaningLabel = primaryMeaningLabel {
                primaryMeaningLabel.text = primaryMeaning
            }
        }
    }
    
    var documentURL: URL {
        return subject.documentURL
    }
    
    private var primaryMeaning: String? {
        get {
            return subject.meanings.lazy.filter({ $0.isPrimary }).map({ $0.meaning }).first
        }
    }
    
    private var primaryReading: String? {
        get {
            return subject.readings.lazy.filter({ $0.isPrimary }).map({ $0.reading }).first
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var characterView: SubjectCharacterView!
    @IBOutlet weak var primaryReadingLabel: UILabel!
    @IBOutlet weak var primaryMeaningLabel: UILabel!
    
}
