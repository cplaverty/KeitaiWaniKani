//
//  SRSDataItemCollectionViewCell.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import CocoaLumberjack
import OperationKit
import WaniKaniKit

class SRSItemHeaderCollectionReusableView: UICollectionReusableView {
    
    // MARK: - Outlets
    
    @IBOutlet weak var headerLabel: UILabel!
    
}

class RadicalGuruProgressCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    var radical: Radical? {
        didSet {
            if radical != oldValue {
                updateUI()
            }
        }
    }
    
    private var getImageOperation: GetRadicalImageOperation? {
        willSet {
            guard let formerOperation = getImageOperation else { return }
            if !formerOperation.finished { formerOperation.cancel() }
        }
    }
    
    // MARK: - Initialisers
    
    deinit {
        getImageOperation?.cancel()
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var characterLabel: UILabel!
    @IBOutlet weak var displayImageView: UIImageView!
    @IBOutlet weak var downloadProgressActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var progressView: UIProgressView!
    
    // MARK: - Update UI
    
    func updateUI() {
        guard let dataItem = self.radical else {
            characterLabel.text = nil
            displayImageView.image = nil
            progressView.setProgress(0, animated: false)
            if downloadProgressActivityIndicator.isAnimating() { downloadProgressActivityIndicator.stopAnimating() }
            return
        }
        
        if let displayCharacter = dataItem.character {
            characterLabel.text = displayCharacter
            characterLabel.hidden = false
            getImageOperation = nil
            displayImageView.image = nil
            displayImageView.hidden = true
            if downloadProgressActivityIndicator.isAnimating() { downloadProgressActivityIndicator.stopAnimating() }
        } else if let displayImageURL = dataItem.image {
            let operation = GetRadicalImageOperation(sourceURL: displayImageURL, networkObserver: NetworkObserver())
            operation.addObserver(BlockObserver { [weak self] operation, errors in
                guard let operation = operation as? GetRadicalImageOperation else { return }
                dispatch_async(dispatch_get_main_queue()) {
                    // Only radicals have display images
                    if self?.radical?.image == operation.sourceURL {
                        self?.downloadProgressActivityIndicator.stopAnimating()
                        self?.displayImageView.image = UIImage(contentsOfFile: operation.destinationFileURL.path!)
                        self?.displayImageView.tintColor = UIColor.blackColor()
                        self?.displayImageView.hidden = false
                    }
                    self?.getImageOperation = nil
                }
                })
            let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
            delegate.operationQueue.addOperation(operation)
            getImageOperation = operation
            displayImageView.hidden = true
            characterLabel.hidden = true
            downloadProgressActivityIndicator.startAnimating()
        } else {
            DDLogWarn("No display character nor image URL for radical \(dataItem)")
        }
        
        let guruLevel = SRSLevel.Guru.numericLevelThreshold
        let currentLevel = dataItem.userSpecificSRSData?.srsLevelNumeric ?? 0
        let percentComplete = min(Float(currentLevel) / Float(guruLevel), 1.0)
        
        progressView.setProgress(percentComplete, animated: false)
        backgroundColor = UIColor(red: 0.0 / 255.0, green: 161.0 / 255.0, blue: 241.0 / 255.0, alpha: currentLevel == 0 ? 0.5 : 1.0)
    }
    
}


class KanjiGuruProgressCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    var kanji: Kanji? {
        didSet {
            if kanji != oldValue {
                updateUI()
            }
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var characterLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    // MARK: - Update UI
    
    func updateUI() {
        guard let kanji = self.kanji else {
            characterLabel.text = nil
            progressView.setProgress(0, animated: false)
            return
        }
        
        characterLabel.text = kanji.character
        
        let guruLevel = SRSLevel.Guru.numericLevelThreshold
        let currentLevel = kanji.userSpecificSRSData?.srsLevelNumeric ?? 0
        let percentToGuru = min(Float(currentLevel) / Float(guruLevel), 1.0)
        
        progressView.setProgress(percentToGuru, animated: false)
        backgroundColor = UIColor(red: 241.0 / 255.0, green: 0.0 / 255.0, blue: 161.0 / 255.0, alpha: currentLevel == 0 ? 0.5 : 1.0)
    }
    
}
