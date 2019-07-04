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
    
    private(set) var subjectID: Int = 0
    
    func setSubject(_ subject: Subject, id: Int) {
        subjectID = id
        
        switch subject {
        case let r as Radical:
            if let image = UIImage(named: "Radicals/\(id)") {
                setImage(image)
            } else if let characters = r.characters {
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
    
    private var imageLoader: RadicalCharacterImageLoader? {
        didSet {
            if let imageLoader = imageLoader {
                let id = ObjectIdentifier(imageLoader)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                    guard let self = self else { return }
                    
                    if let imageLoader = self.imageLoader, ObjectIdentifier(imageLoader) == id {
                        self.downloadProgressActivityIndicator.startAnimating()
                    }
                }
            } else {
                downloadProgressActivityIndicator.stopAnimating()
            }
        }
    }
    
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
    
    func cancelImageDownloadIfRequested() {
        imageLoader = nil
    }
    
    private func setCharacters(_ characters: String) {
        imageLoader = nil
        characterLabel.isHidden = false
        characterLabel.text = characters
        displayImageView.image = nil
        displayImageView.isHidden = true
        displayImageViewHeightConstraints.forEach { constraint in
            constraint.isActive = false
        }
    }
    
    private func setImage(_ image: UIImage) {
        imageLoader = nil
        characterLabel.isHidden = true
        characterLabel.text = nil
        displayImageView.image = image.withRenderingMode(.alwaysTemplate)
        displayImageView.isHidden = false
        displayImageViewHeightConstraints.forEach { constraint in
            constraint.isActive = true
        }
    }
    
    private func setImage(_ imageChoices: [Radical.CharacterImage]) {
        imageLoader = nil
        characterLabel.isHidden = true
        characterLabel.text = nil
        displayImageView.image = nil
        displayImageView.isHidden = false
        displayImageViewHeightConstraints.forEach { constraint in
            constraint.isActive = true
        }
        
        let imageLoader = RadicalCharacterImageLoader()
        self.imageLoader = imageLoader
        imageLoader.loadImage(from: imageChoices) { [weak self] result in
            guard let self = self else { return }
            
            guard let currentImageLoader = self.imageLoader, imageLoader === currentImageLoader else {
                os_log("Ignoring outdated image load request", type: .info)
                return
            }
            
            self.imageLoader = nil
            
            switch result {
            case let .failure(error):
                os_log("Failed to fetch subject image: %@", type: .error, error as NSError)
            case let .success(image):
                self.displayImageView.image = image.withRenderingMode(.alwaysTemplate)
                self.displayImageView.isHidden = false
            }
        }
    }
}

