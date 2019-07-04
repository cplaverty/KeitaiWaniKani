//
//  SubjectSearchTableViewCell.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit
import WaniKaniKit

class SubjectSearchTableViewCell: UITableViewCell, SubjectCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var characterView: SubjectCharacterView!
    @IBOutlet weak var primaryReadingLabel: UILabel!
    @IBOutlet weak var primaryMeaningLabel: UILabel!
    
    // MARK: - UICollectionReusableView
    
    override func prepareForReuse() {
        super.prepareForReuse()
        characterView.cancelImageDownloadIfRequested()
    }
}
