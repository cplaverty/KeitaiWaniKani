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
    
    var subject: Subject! {
        didSet {
            characterView.subject = subject
            backgroundColor = subject.subjectType.backgroundColor
        }
    }
    
    var documentURL: URL {
        return subject.documentURL
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var characterView: SubjectCharacterView!
    
}
