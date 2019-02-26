//
//  SubjectDetailViewController.swift
//  AlliCrab
//
//  Copyright © 2019 Chris Laverty. All rights reserved.
//

import os
import UIKit
import WaniKaniKit

private let enFont = UIFont.preferredFont(forTextStyle: .body)
private let jpFont = UIFont(name: "Hiragino Sans W3", size: enFont.pointSize) ?? enFont

class SubjectDetailViewController: UIViewController {
    
    // MARK: - Properties
    
    var repositoryReader: ResourceRepositoryReader?
    var subjectID: Int?
    
    // MARK: - Outlets
    
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var characterView: SubjectCharacterView!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var primaryMeaningLabel: UILabel!
    @IBOutlet weak var alternativeMeaningsLabel: UILabel!
    @IBOutlet weak var userSynonymsLabel: UILabel!
    
    @IBOutlet weak var onyomiTitleLabel: UILabel!
    @IBOutlet weak var onyomiLabel: UILabel!
    @IBOutlet weak var kunyomiTitleLabel: UILabel!
    @IBOutlet weak var kunyomiLabel: UILabel!
    @IBOutlet weak var nanoriTitleLabel: UILabel!
    @IBOutlet weak var nanoriLabel: UILabel!
    
    @IBOutlet weak var vocabularyReadingLabel: UILabel!
    
    @IBOutlet weak var meaningMnemonicTitleLabel: UILabel!
    @IBOutlet weak var meaningMnemonicLabel: UILabel!
    @IBOutlet weak var meaningNoteLabel: UILabel!
    @IBOutlet weak var readingMnemonicTitleLabel: UILabel!
    @IBOutlet weak var readingMnemonicLabel: UILabel!
    @IBOutlet weak var readingNoteLabel: UILabel!
    
    @IBOutlet weak var srsStageImageView: UIImageView!
    @IBOutlet weak var srsStageNameLabel: UILabel!
    
    @IBOutlet weak var combinedAnsweredCorrectProgressBarView: ProgressBarView!
    @IBOutlet weak var meaningAnsweredCorrectProgressBarView: ProgressBarView!
    @IBOutlet weak var readingAnsweredCorrectProgressBarView: ProgressBarView!
    
    @IBOutlet var visibleViewsForRadical: [UIView]!
    @IBOutlet var visibleViewsForKanji: [UIView]!
    @IBOutlet var visibleViewsForVocabulary: [UIView]!
    @IBOutlet var reviewStatisticsViews: [UIView]!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        try! updateSubjectDetail()
    }
    
    // MARK: - Update UI
    
    private func updateSubjectDetail() throws {
        guard let repositoryReader = repositoryReader, let subjectID = subjectID else {
            fatalError("SubjectDetailViewController: repositoryReader or subjectID nil")
        }
        
        os_log("Fetching subject detail for %d", type: .info, subjectID)
        
        let (subject, studyMaterials, assignment, reviewStatistics) = try repositoryReader.subjectDetail(id: subjectID)
        
        characterView.subject = subject
        headerView.backgroundColor = subject.subjectType.backgroundColor
        
        levelLabel.text = String(subject.level)
        
        switch subject {
        case let r as Radical:
            navigationItem.title = r.slug
            removeSubviews(from: stackView, ifNotIn: visibleViewsForRadical)
            
            meaningMnemonicTitleLabel.text = "Name Mnemonic"
            meaningMnemonicLabel.attributedText = createFromMarkup(r.meaningMnemonic)
        case let k as Kanji:
            navigationItem.title = k.characters
            removeSubviews(from: stackView, ifNotIn: visibleViewsForKanji)
            
            updateKanjiReading(kanji: k, type: .onyomi, titleLabel: onyomiTitleLabel, label: onyomiLabel)
            updateKanjiReading(kanji: k, type: .kunyomi, titleLabel: kunyomiTitleLabel, label: kunyomiLabel)
            updateKanjiReading(kanji: k, type: .nanori, titleLabel: nanoriTitleLabel, label: nanoriLabel)
            
            meaningMnemonicTitleLabel.text = "Meaning Mnemonic"
            meaningMnemonicLabel.attributedText = createFromMarkup(k.meaningMnemonic)
            readingMnemonicTitleLabel.text = "Reading Mnemonic"
            readingMnemonicLabel.attributedText = createFromMarkup(k.readingMnemonic)
        case let v as Vocabulary:
            navigationItem.title = v.characters
            removeSubviews(from: stackView, ifNotIn: visibleViewsForVocabulary)
            
            vocabularyReadingLabel.text = v.allReadings
            vocabularyReadingLabel.font = jpFont
            
            meaningMnemonicTitleLabel.text = "Meaning Explanation"
            meaningMnemonicLabel.attributedText = createFromMarkup(v.meaningMnemonic)
            readingMnemonicTitleLabel.text = "Reading Explanation"
            readingMnemonicLabel.attributedText = createFromMarkup(v.readingMnemonic)
        default:
            fatalError("Unknown subject type")
        }
        
        let primaryMeaning = subject.meanings.lazy.filter({ $0.isPrimary }).map({ $0.meaning }).first!
        primaryMeaningLabel.text = primaryMeaning
        let alternativeMeanings = subject.meanings.lazy.filter({ !$0.isPrimary }).map({ $0.meaning }).joined(separator: ", ")
        if alternativeMeanings.isEmpty {
            alternativeMeaningsLabel.isHidden = true
        } else {
            alternativeMeaningsLabel.text = alternativeMeanings
        }
        
        if let meaningSynonyms = studyMaterials?.meaningSynonyms {
            let boldFont = UIFont(descriptor: userSynonymsLabel.font.fontDescriptor.withSymbolicTraits(.traitBold)!, size: userSynonymsLabel.font.pointSize)
            let userSynonymsText = NSMutableAttributedString(string: "User Synonyms", attributes: [.font: boldFont])
            userSynonymsText.append(NSAttributedString(string: " " + meaningSynonyms.joined(separator: ", ")))
            userSynonymsLabel.attributedText = userSynonymsText
        } else {
            userSynonymsLabel.isHidden = true
        }
        
        // TODO Can only do meaning notes on items which are unlocked
        if let meaningNote = studyMaterials?.meaningNote {
            meaningNoteLabel.text = meaningNote
        } else {
            meaningNoteLabel.attributedText = NSAttributedString(string: "None",
                                                                 attributes: [.foregroundColor: UIColor.darkGray.withAlphaComponent(0.75)])
        }
        if let readingNote = studyMaterials?.readingNote {
            readingNoteLabel.text = readingNote
        } else {
            readingNoteLabel.attributedText = NSAttributedString(string: "None",
                                                                 attributes: [.foregroundColor: UIColor.darkGray.withAlphaComponent(0.75)])
        }
        
        if let assignment = assignment,
            let srsStage = SRSStage(numericLevel: assignment.srsStage), srsStage != .initiate {
            srsStageNameLabel.text = srsStage.rawValue
            srsStageImageView.image = UIImage(named: srsStage.rawValue)!.withRenderingMode(.alwaysOriginal)
        }
        
        if let reviewStatistics = reviewStatistics, reviewStatistics.total > 0 {
            meaningAnsweredCorrectProgressBarView.progress = Float(reviewStatistics.meaningPercentageCorrect) / 100.0
            meaningAnsweredCorrectProgressBarView.totalCount = reviewStatistics.meaningTotal
            
            if subject is Radical {
                meaningAnsweredCorrectProgressBarView.title = "Name Answered Correct"
            } else {
                combinedAnsweredCorrectProgressBarView.progress = Float(reviewStatistics.percentageCorrect) / 100.0
                combinedAnsweredCorrectProgressBarView.totalCount = reviewStatistics.total
                readingAnsweredCorrectProgressBarView.progress = Float(reviewStatistics.readingPercentageCorrect) / 100.0
                readingAnsweredCorrectProgressBarView.totalCount = reviewStatistics.readingTotal
            }
        } else {
            reviewStatisticsViews.forEach { view in
                view.removeFromSuperview()
            }
        }
    }
    
    private func updateKanjiReading(kanji: Kanji, type: ReadingType, titleLabel: UILabel, label: UILabel) {
        let textColour = kanji.isPrimary(type: type) ? .black : UIColor.darkGray.withAlphaComponent(0.75)
        titleLabel.textColor = textColour
        label.textColor = textColour
        
        if let readings = kanji.readings(type: type), readings != "None" {
            label.text = readings
            label.font = jpFont
        } else {
            label.text = "None"
            label.font = enFont
        }
    }
    
    private func createFromMarkup(_ str: String) -> NSAttributedString {
        return NSAttributedString(wkMarkup: str, attributes: [.font: enFont])
    }
    
    private func removeSubviews(from stackView: UIStackView, ifNotIn visibleViews: [UIView]) {
        stackView.arrangedSubviews.forEach { view in
            if !visibleViews.contains(view) {
                view.removeFromSuperview()
            }
        }
    }
}
