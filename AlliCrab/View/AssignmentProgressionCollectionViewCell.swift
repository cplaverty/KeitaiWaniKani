//
//  AssignmentProgressionCollectionViewCell.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os
import UIKit
import WaniKaniKit

private let dateComponentsFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.year, .month, .weekOfMonth, .day, .hour, .minute]
    formatter.maximumUnitCount = 2
    formatter.unitsStyle = .abbreviated
    formatter.zeroFormattingBehavior = [.dropAll]
    
    return formatter
}()

protocol AssignmentProgressionCollectionViewCell {
    
    // MARK: - Properties
    
    var availableAt: NextReviewTime? { get }
    var guruTime: NextReviewTime? { get }
    var percentComplete: Float? { get }
    
    var infoURL: URL? { get }
    
    // MARK: - Outlets
    
    var progressView: UIProgressView! { get }
    var timeToNextReviewLabel: UILabel! { get }
    var timeToGuruLabel: UILabel! { get }
    
}

private extension AssignmentProgressionCollectionViewCell {
    func updateProgress() {
        switch availableAt {
        case .none:
            timeToNextReviewLabel.text = "Locked"
        case .some(.none):
            timeToNextReviewLabel.text = "Burned"
        case .some(.now):
            timeToNextReviewLabel.text = "Now"
        case .some(.date(let date)) where date.timeIntervalSinceNow <= 0:
            timeToNextReviewLabel.text = "Now"
        case .some(.date(let date)):
            let formattedInterval = dateComponentsFormatter.string(from: date.timeIntervalSinceNow, roundingUpwardToNearest: .oneMinute) ?? "???"
            timeToNextReviewLabel.text = formattedInterval
        }
        
        switch guruTime {
        case .none, .some(.none), .some(.now):
            timeToGuruLabel.text = "-"
        case .some(.date(let date)) where date.timeIntervalSinceNow <= 0:
            timeToGuruLabel.text = "-"
        case .some(.date(let date)):
            let formattedInterval = dateComponentsFormatter.string(from: date.timeIntervalSinceNow, roundingUpwardToNearest: .oneMinute) ?? "???"
            timeToGuruLabel.text = formattedInterval
        }
        
        progressView.setProgress(percentComplete ?? 0, animated: false)
    }
}

// MARK: - RadicalAssignmentProgressionCollectionViewCell
class RadicalAssignmentProgressionCollectionViewCell: UICollectionViewCell, AssignmentProgressionCollectionViewCell {
    
    // MARK: - Properties
    
    var availableAt: NextReviewTime?
    var guruTime: NextReviewTime?
    var percentComplete: Float?
    var radical: Radical?
    
    var infoURL: URL? {
        return radical.flatMap { WaniKaniURL.radicalRoot.appendingPathComponent($0.slug) }
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
    
    // MARK: - Outlets
    
    @IBOutlet weak var characterLabel: UILabel!
    @IBOutlet weak var displayImageView: UIImageView!
    @IBOutlet weak var downloadProgressActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var timeToNextReviewLabel: UILabel!
    @IBOutlet weak var timeToGuruLabel: UILabel!
    
    // MARK: - Update UI
    
    func updateUI() {
        updateProgress()
        
        guard let radical = self.radical else {
            characterLabel.text = nil
            displayImageView.image = nil
            imageLoader = nil
            return
        }
        
        if let displayCharacter = radical.character {
            characterLabel.text = displayCharacter
            characterLabel.isHidden = false
            displayImageView.image = nil
            displayImageView.isHidden = true
            imageLoader = nil
        } else {
            characterLabel.isHidden = true
            displayImageView.isHidden = true
            
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
                self?.displayImageView.tintColor = .white
                self?.displayImageView.isHidden = false
            }
        }
        
        let isLocked = availableAt == nil
        backgroundColor = UIColor.waniKaniRadical.withAlphaComponent(isLocked ? 0.5 : 1.0)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoader = nil
    }
    
}

// MARK: - KanjiAssignmentProgressionCollectionViewCell
class KanjiAssignmentProgressionCollectionViewCell: UICollectionViewCell, AssignmentProgressionCollectionViewCell {
    
    // MARK: - Properties
    
    var availableAt: NextReviewTime?
    var guruTime: NextReviewTime?
    var percentComplete: Float?
    var kanji: Kanji?
    
    var infoURL: URL? {
        return kanji.flatMap { WaniKaniURL.kanjiRoot.appendingPathComponent($0.character) }
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var characterLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var timeToNextReviewLabel: UILabel!
    @IBOutlet weak var timeToGuruLabel: UILabel!
    
    // MARK: - Update UI
    
    func updateUI() {
        updateProgress()
        
        guard let kanji = self.kanji else {
            characterLabel.text = nil
            return
        }
        
        characterLabel.text = kanji.character
        let isLocked = availableAt == nil
        backgroundColor = UIColor.waniKaniKanji.withAlphaComponent(isLocked ? 0.5 : 1.0)
    }
    
}

