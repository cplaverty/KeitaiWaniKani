//
//  SubjectCell.swift
//  AlliCrab
//
//  Copyright © 2019 Chris Laverty. All rights reserved.
//

import UIKit
import WaniKaniKit

protocol SubjectCell {
    var characterView: SubjectCharacterView! { get }
    var primaryReadingLabel: UILabel! { get }
    var primaryMeaningLabel: UILabel! { get }
    var subjectID: Int { get }
    
    func setSubject(_ subject: Subject, id: Int)
}

extension SubjectCell {
    var subjectID: Int {
        return characterView.subjectID
    }
}

extension SubjectCell where Self: UIView {
    func setSubject(_ subject: Subject, id: Int) {
        characterView.setSubject(subject, id: id)
        
        backgroundColor = subject.subjectType.backgroundColor
        
        setText(subject.primaryReading, for: primaryReadingLabel)
        setText(subject.primaryMeaning, for: primaryMeaningLabel)
        
        // Fix for self-sizing cells on iOS 12
        updateConstraintsIfNeeded()
    }
    
    private func setText(_ text: String?, for label: UILabel?) {
        guard let label = label else { return }
        
        if let text = text {
            label.text = text
            label.isHidden = false
        } else {
            label.isHidden = true
        }
    }
}
