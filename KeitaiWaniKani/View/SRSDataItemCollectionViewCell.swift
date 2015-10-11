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


private let dateComponentsFormatter: NSDateComponentsFormatter = {
    let formatter = Formatter.defaultFormatter.copy() as! NSDateComponentsFormatter
    formatter.maximumUnitCount = 1
    formatter.allowsFractionalUnits = true
    formatter.includesApproximationPhrase = false
    formatter.includesTimeRemainingPhrase = false
    
    return formatter
    }()

private protocol SRSDataItemGuruProgressCollectionViewCell {
    typealias DataItem: SRSDataItem, Equatable
    
    // MARK: - Properties
    
    var dataItem: DataItem? { get }
    
    // MARK: - Outlets
    
    var progressView: UIProgressView! { get }
    var timeToNextReview: UILabel! { get }
    var timeToGuru: UILabel! { get }
}

private extension SRSDataItemGuruProgressCollectionViewCell {
    
    func updateProgress() {
        guard let dataItem = self.dataItem else {
            timeToNextReview.text = nil
            timeToGuru.text = nil
            progressView.setProgress(0, animated: false)
            return
        }
        
        switch Formatter.formatTimeIntervalToDate(dataItem.userSpecificSRSData?.dateAvailable, formatter: dateComponentsFormatter) {
        case .None:
            timeToNextReview.text = "Locked"
        case .Now:
            timeToNextReview.text = "Review now"
        case .FormattedString(let formattedInterval):
            timeToNextReview.text = "Review: \(formattedInterval)"
        case .UnformattedInterval(let secondsUntilNextReview):
            timeToNextReview.text = "Review: \(NSNumberFormatter.localizedStringFromNumber(secondsUntilNextReview, numberStyle: .DecimalStyle))s"
        }
        
        switch Formatter.formatTimeIntervalToDate(dataItem.guruDate(nil), formatter: dateComponentsFormatter) {
        case .None, .Now:
            timeToGuru.text = nil
        case .FormattedString(let formattedInterval):
            timeToGuru.text = "Guru: \(formattedInterval)"
        case .UnformattedInterval(let secondsUntilNextReview):
            timeToGuru.text = "Guru: \(NSNumberFormatter.localizedStringFromNumber(secondsUntilNextReview, numberStyle: .DecimalStyle))s"
        }
        
        let guruLevel = SRSLevel.Guru.numericLevelThreshold
        let currentLevel = dataItem.userSpecificSRSData?.srsLevelNumeric ?? 0
        let percentComplete = min(Float(currentLevel) / Float(guruLevel), 1.0)
        
        progressView.setProgress(percentComplete, animated: false)
    }
    
}

class RadicalGuruProgressCollectionViewCell: UICollectionViewCell, SRSDataItemGuruProgressCollectionViewCell {
    
    // MARK: - Properties
    
    var dataItem: Radical? {
        didSet {
            if dataItem != oldValue {
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
    @IBOutlet weak var timeToNextReview: UILabel!
    @IBOutlet weak var timeToGuru: UILabel!
    
    // MARK: - Update UI
    
    func updateUI() {
        updateProgress()
        
        guard let dataItem = self.dataItem else {
            characterLabel.text = nil
            displayImageView.image = nil
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
                    if dataItem.image == operation.sourceURL {
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
        
        let currentLevel = dataItem.userSpecificSRSData?.srsLevelNumeric ?? 0
        backgroundColor = UIColor(red: 0.0 / 255.0, green: 161.0 / 255.0, blue: 241.0 / 255.0, alpha: currentLevel == 0 ? 0.5 : 1.0)
    }
    
}


class KanjiGuruProgressCollectionViewCell: UICollectionViewCell, SRSDataItemGuruProgressCollectionViewCell {
    
    // MARK: - Properties
    
    var dataItem: Kanji? {
        didSet {
            if dataItem != oldValue {
                updateUI()
            }
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var characterLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var timeToNextReview: UILabel!
    @IBOutlet weak var timeToGuru: UILabel!
    
    // MARK: - Update UI
    
    func updateUI() {
        updateProgress()
        
        guard let dataItem = self.dataItem else {
            characterLabel.text = nil
            return
        }
        
        characterLabel.text = dataItem.character
        
        let currentLevel = dataItem.userSpecificSRSData?.srsLevelNumeric ?? 0
        backgroundColor = UIColor(red: 241.0 / 255.0, green: 0.0 / 255.0, blue: 161.0 / 255.0, alpha: currentLevel == 0 ? 0.5 : 1.0)
    }
    
}
