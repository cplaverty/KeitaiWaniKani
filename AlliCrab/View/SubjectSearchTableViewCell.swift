//
//  SubjectSearchTableViewCell.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit
import WaniKaniKit

class SubjectSearchTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    
    var subject: Subject! {
        didSet {
            characterView.subject = subject
            meaningLabel.text = subject.meanings.lazy.filter({ $0.isPrimary }).map({ $0.meaning }).joined(separator: ", ")
            readingLabel.text = subject.readings.lazy.filter({ $0.isPrimary }).map({ $0.reading }).joined(separator: ", ")
            backgroundColor = subject.subjectType.backgroundColor
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var characterView: SubjectCharacterView!
    @IBOutlet weak var meaningLabel: UILabel!
    @IBOutlet weak var readingLabel: UILabel!
    
}
