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
class SubjectCharacterView: UIView {
    
    let characterLabel: UILabel! = {
        var label = UILabel()
        label.font = UIFont(name: "HiraginoSans-W6", size: 50)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    let displayImageView: UIImageView! = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        return imageView
    }()
    
    private let downloadProgressActivityIndicator: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        
        return activityIndicatorView
    }()
    
    @IBInspectable var fontSize: Float {
        get {
            return Float(characterLabel.font.pointSize)
        }
        set {
            characterLabel.font = characterLabel.font.withSize(CGFloat(newValue))
        }
    }
    
    @IBInspectable var adjustsFontSizeToFitWidth: Bool {
        get {
            return characterLabel.adjustsFontSizeToFitWidth
        }
        set {
            characterLabel.adjustsFontSizeToFitWidth = newValue
        }
    }
    
    @IBInspectable var minimumScaleFactor: Float {
        get {
            return Float(characterLabel.minimumScaleFactor)
        }
        set {
            characterLabel.minimumScaleFactor = CGFloat(newValue)
        }
    }
    
    @IBInspectable var textColor: UIColor! {
        get {
            return characterLabel.textColor
        }
        set {
            characterLabel.textColor = newValue
            displayImageView.tintColor = newValue
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
            case let radical as Radical:
                if let displayCharacter = radical.character {
                    setCharacters(displayCharacter)
                } else {
                    setImage(radical)
                }
            case let kanji as Kanji:
                setCharacters(kanji.character)
            case let vocabulary as Vocabulary:
                setCharacters(vocabulary.characters)
            default:
                fatalError()
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        commonInit()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        commonInit()
        setCharacters("入")
    }
    
    private func commonInit() {
        addSubview(characterLabel)
        addSubview(displayImageView)
        addSubview(downloadProgressActivityIndicator)
        
        characterLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        layoutMarginsGuide.bottomAnchor.constraint(equalTo: characterLabel.bottomAnchor).isActive = true
        characterLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        layoutMarginsGuide.trailingAnchor.constraint(equalTo: characterLabel.trailingAnchor).isActive = true
        characterLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        characterLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        displayImageView.topAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor).isActive = true
        layoutMarginsGuide.bottomAnchor.constraint(greaterThanOrEqualTo: displayImageView.bottomAnchor).isActive = true
        displayImageView.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor).isActive = true
        layoutMarginsGuide.trailingAnchor.constraint(greaterThanOrEqualTo: displayImageView.trailingAnchor).isActive = true
        displayImageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        displayImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        displayImageView.widthAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        downloadProgressActivityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        downloadProgressActivityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    func setCharacters(_ characters: String) {
        imageLoader = nil
        characterLabel.text = characters
        characterLabel.isHidden = false
        displayImageView.image = nil
        displayImageView.isHidden = true
    }
    
    func setImage(_ radical: Radical) {
        characterLabel.isHidden = true
        displayImageView.isHidden = false
        
        let imageLoader = RadicalCharacterImageLoader(characterImages: radical.characterImages)
        self.imageLoader = imageLoader
        imageLoader.loadImage { [weak self] (image, error) in
            guard let image = image else {
                if #available(iOS 10.0, *) {
                    os_log("Failed to fetch radical image %@: %@", type: .error, radical.slug, error?.localizedDescription ?? "<no error>")
                }
                return
            }
            
            self?.imageLoader = nil
            self?.displayImageView.image = image
            self?.displayImageView.tintColor = self?.textColor
            self?.displayImageView.isHidden = false
        }
    }
}
