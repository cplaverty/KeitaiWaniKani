//
//  SubjectCharacterView.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os
import UIKit
import WaniKaniKit

@IBDesignable
class SubjectCharacterView: UIView, XibLoadable {
    
    var contentView : UIView!
    
    @IBOutlet weak var characterLabel: UILabel!
    @IBOutlet weak var displayImageView: UIImageView!
    @IBOutlet weak var downloadProgressActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var displayImageViewHeightConstraints: [NSLayoutConstraint]!
    
    @IBInspectable var fontSize: CGFloat {
        get {
            return characterLabel.font.pointSize
        }
        set {
            characterLabel.font = characterLabel.font.withSize(newValue)
            displayImageViewHeightConstraints.forEach { constraint in
                constraint.constant = characterLabel.font.lineHeight
            }
        }
    }
    
    var subject: Subject? {
        didSet {
            guard let subject = subject else {
                characterLabel.text = nil
                displayImageView.image = nil
                imageLoader = nil
                return
            }
            
            switch subject {
            case let r as Radical:
                if let characters = r.characters {
                    setCharacters(characters)
                } else {
                    setImage(r.characterImages)
                }
            case let k as Kanji:
                setCharacters(k.characters)
            case let v as Vocabulary:
                setCharacters(v.characters)
            default:
                fatalError("Unknown subject type")
            }
        }
    }
    
    private var imageLoader: RadicalCharacterImageLoader? {
        didSet {
            if imageLoader != nil {
                downloadProgressActivityIndicator.startAnimating()
            } else {
                downloadProgressActivityIndicator.stopAnimating()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        xibSetup()
        contentView.prepareForInterfaceBuilder()
    }
    
    func xibSetup() {
        contentView = loadViewFromXib()
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addSubview(contentView)
    }
    
    func setCharacters(_ characters: String) {
        imageLoader = nil
        characterLabel.text = characters
        characterLabel.isHidden = false
        displayImageView.image = nil
        displayImageView.isHidden = true
        displayImageViewHeightConstraints.forEach { constraint in
            constraint.isActive = false
        }
    }
    
    func setImage(_ imageChoices: [SubjectImage]) {
        characterLabel.isHidden = true
        characterLabel.text = nil
        displayImageView.isHidden = false
        displayImageViewHeightConstraints.forEach { constraint in
            constraint.isActive = true
        }
        
        let imageLoader = RadicalCharacterImageLoader(characterImages: imageChoices)
        self.imageLoader = imageLoader
        imageLoader.loadImage { [weak self] (image, error) in
            guard let image = image else {
                os_log("Failed to fetch subject image %@: %@", type: .error, imageLoader.characterImage?.url.absoluteString ?? "<no renderable image>", error?.localizedDescription ?? "<no error>")
                return
            }
            
            self?.imageLoader = nil
            self?.displayImageView.image = image
            self?.displayImageView.isHidden = false
        }
    }
}
