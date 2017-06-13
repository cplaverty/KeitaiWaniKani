//
//  SRSDataItemCollectionViewCell.swift
//  AlliCrab
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

private let dateComponentsFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.year, .month, .weekOfMonth, .day, .hour, .minute]
    formatter.maximumUnitCount = 1
    formatter.unitsStyle = .abbreviated
    formatter.zeroFormattingBehavior = [.dropLeading, .dropTrailing]
    
    return formatter
    }()

protocol SRSDataItemInfoURL {
    var srsDataItemInfoURL: URL? { get }
}

private protocol SRSDataItemGuruProgressCollectionViewCell {
    associatedtype DataItem: SRSDataItem, Equatable
    
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
        
        switch WaniKaniKit.Formatter.formatTimeIntervalSinceNow(from: dataItem.userSpecificSRSData?.dateAvailable, formatter: dateComponentsFormatter) {
        case .none:
            timeToNextReview.text = "Locked"
        case .now:
            timeToNextReview.text = "Review now"
        case .formattedString(let formattedInterval):
            timeToNextReview.text = "Review: \(formattedInterval)"
        case .unformattedInterval(let secondsUntilNextReview):
            timeToNextReview.text = "Review: \(NumberFormatter.localizedString(from: NSNumber(value: secondsUntilNextReview), number: .decimal))s"
        }
        
        switch WaniKaniKit.Formatter.formatTimeIntervalSinceNow(from: dataItem.guruDate(nil), formatter: dateComponentsFormatter) {
        case .none, .now:
            timeToGuru.text = nil
        case .formattedString(let formattedInterval):
            timeToGuru.text = "Guru: \(formattedInterval)"
        case .unformattedInterval(let secondsUntilNextReview):
            timeToGuru.text = "Guru: \(NumberFormatter.localizedString(from: NSNumber(value: secondsUntilNextReview), number: .decimal))s"
        }
        
        let guruLevel = SRSLevel.guru.numericLevelThreshold
        let currentLevel = dataItem.userSpecificSRSData?.srsLevelNumeric ?? 0
        let percentComplete = min(Float(currentLevel) / Float(guruLevel), 1.0)
        
        progressView.setProgress(percentComplete, animated: false)
    }
    
}

// MARK: - RadicalGuruProgressCollectionViewCell
class RadicalGuruProgressCollectionViewCell: UICollectionViewCell, SRSDataItemGuruProgressCollectionViewCell, SRSDataItemInfoURL {
    
    // MARK: - Properties
    
    var dataItem: Radical? {
        didSet {
            if dataItem != oldValue {
                updateUI()
            }
        }
    }
    
    var srsDataItemInfoURL: URL? {
        return dataItem.flatMap { URL(string: $0.meaning, relativeTo: WaniKaniURLs.radicalRoot) }
    }
    
    private var getImageOperation: GetRadicalImageOperation? {
        willSet {
            guard let formerOperation = getImageOperation else { return }
            if !formerOperation.isFinished { formerOperation.cancel() }
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
            if downloadProgressActivityIndicator.isAnimating { downloadProgressActivityIndicator.stopAnimating() }
            return
        }
        
        if let displayCharacter = dataItem.character {
            characterLabel.text = displayCharacter
            characterLabel.isHidden = false
            getImageOperation = nil
            displayImageView.image = nil
            displayImageView.isHidden = true
            if downloadProgressActivityIndicator.isAnimating { downloadProgressActivityIndicator.stopAnimating() }
        } else if let displayImageURL = dataItem.image {
            let operation = GetRadicalImageOperation(sourceURL: displayImageURL, networkObserver: NetworkObserver())
            operation.addObserver(BlockObserver { [weak self] operation, errors in
                guard let operation = operation as? GetRadicalImageOperation else { return }
                DispatchQueue.main.async {
                    // Only radicals have display images
                    if dataItem.image == operation.sourceURL {
                        self?.downloadProgressActivityIndicator.stopAnimating()
                        self?.displayImageView.image = UIImage(contentsOfFile: operation.destinationFileURL.path)
                        self?.displayImageView.tintColor = UIColor.black
                        self?.displayImageView.isHidden = false
                    }
                    self?.getImageOperation = nil
                }
                })
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.operationQueue.addOperation(operation)
            getImageOperation = operation
            displayImageView.isHidden = true
            characterLabel.isHidden = true
            downloadProgressActivityIndicator.startAnimating()
        } else {
            DDLogWarn("No display character nor image URL for radical \(dataItem)")
        }
        
        let currentLevel = dataItem.userSpecificSRSData?.srsLevelNumeric ?? 0
        backgroundColor = UIColor(red: 0.0 / 255.0, green: 161.0 / 255.0, blue: 241.0 / 255.0, alpha: currentLevel == 0 ? 0.5 : 1.0)
    }
    
}

// MARK: - KanjiGuruProgressCollectionViewCell
class KanjiGuruProgressCollectionViewCell: UICollectionViewCell, SRSDataItemGuruProgressCollectionViewCell, SRSDataItemInfoURL {
    
    // MARK: - Properties
    
    var dataItem: Kanji? {
        didSet {
            if dataItem != oldValue {
                updateUI()
            }
        }
    }
    
    var srsDataItemInfoURL: URL? {
        return dataItem.flatMap { URL(string: $0.character.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed)!, relativeTo: WaniKaniURLs.kanjiRoot) }
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
