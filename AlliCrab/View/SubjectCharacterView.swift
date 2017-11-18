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
    
    private lazy var heightConstraints = [
        displayImageView.heightAnchor.constraint(lessThanOrEqualToConstant: characterLabel.font.lineHeight),
        downloadProgressActivityIndicator.heightAnchor.constraint(lessThanOrEqualToConstant: characterLabel.font.lineHeight)
    ]
    
    @IBInspectable var fontSize: Double {
        get {
            return Double(characterLabel.font.pointSize)
        }
        set {
            characterLabel.font = characterLabel.font.withSize(CGFloat(newValue))
            heightConstraints.forEach { $0.constant = characterLabel.font.lineHeight }
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
    
    @IBInspectable var minimumScaleFactor: Double {
        get {
            return Double(characterLabel.minimumScaleFactor)
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
            
            switch subject.characterRepresentation {
            case let .unicode(character):
                setCharacters(character)
            case let .image(imageChoices):
                setImage(imageChoices)
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
        
        NSLayoutConstraint.activate([
            characterLabel.topAnchor.constraint(equalTo: topAnchor),
            characterLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            characterLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            characterLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            displayImageView.topAnchor.constraint(equalTo: topAnchor),
            displayImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            displayImageView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            displayImageView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            displayImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            displayImageView.widthAnchor.constraint(equalTo: displayImageView.heightAnchor),
            
            downloadProgressActivityIndicator.topAnchor.constraint(equalTo: topAnchor),
            downloadProgressActivityIndicator.bottomAnchor.constraint(equalTo: bottomAnchor),
            downloadProgressActivityIndicator.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            downloadProgressActivityIndicator.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            downloadProgressActivityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            downloadProgressActivityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            downloadProgressActivityIndicator.widthAnchor.constraint(equalTo: downloadProgressActivityIndicator.heightAnchor)
            ])
        
        NSLayoutConstraint.activate(heightConstraints)
    }
    
    func setCharacters(_ characters: String) {
        imageLoader = nil
        characterLabel.text = characters
        characterLabel.isHidden = false
        displayImageView.image = nil
        displayImageView.isHidden = true
    }
    
    func setImage(_ imageChoices: [SubjectImage]) {
        characterLabel.isHidden = true
        characterLabel.text = nil
        displayImageView.isHidden = false
        
        let imageLoader = RadicalCharacterImageLoader(characterImages: imageChoices)
        self.imageLoader = imageLoader
        imageLoader.loadImage { [weak self] (image, error) in
            guard let image = image else {
                if #available(iOS 10.0, *) {
                    os_log("Failed to fetch subject image %@: %@", type: .error, imageLoader.characterImage?.url.absoluteString ?? "<no renderable image>", error?.localizedDescription ?? "<no error>")
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
