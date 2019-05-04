//
//  ContextSentenceView.swift
//  AlliCrab
//
//  Copyright © 2019 Chris Laverty. All rights reserved.
//

import UIKit

class ContextSentenceView: UIView, XibLoadable {
    
    // MARK: - Properties
    
    @IBInspectable var japanese: String? {
        get {
            return japaneseSentenceLabel.text
        }
        set {
            japaneseSentenceLabel.text = newValue
        }
    }
    
    @IBInspectable var english: String? {
        get {
            return englishTranslationLabel.text
        }
        set {
            englishTranslationLabel.text = newValue
        }
    }
    
    // MARK: - Outlets
    
    var contentView : UIView!
    
    @IBOutlet weak var japaneseSentenceLabel: UILabel!
    @IBOutlet weak var englishTranslationLabel: UILabel!
    
    // MARK: - Initialisers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView = setupContentViewFromXib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        contentView = setupContentViewFromXib()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        contentView.prepareForInterfaceBuilder()
    }
    
}
