//
//  ReviewTimelineEntryTableViewCell.swift
//  AlliCrab
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import WaniKaniKit

class ReviewTimelineEntryTableViewCell: UITableViewCell {
    
    // MARK: Properties
    
    var reviewCounts: SRSReviewCounts? {
        didSet {
            updateUI()
        }
    }
    
    // MARK: Outlets
    
    @IBOutlet weak var reviewTimeLabel: UILabel!
    @IBOutlet weak var radicalCountLabel: UILabel!
    @IBOutlet weak var kanjiCountLabel: UILabel!
    @IBOutlet weak var vocabularyCountLabel: UILabel!
    @IBOutlet weak var totalCountLabel: UILabel!
    
    // MARK: Update UI
    
    func updateUI() {
        guard let reviewCounts = self.reviewCounts else {
            reviewTimeLabel?.text = nil
            radicalCountLabel?.text = nil
            kanjiCountLabel?.text = nil
            vocabularyCountLabel?.text = nil
            totalCountLabel?.text = nil
            return
        }
        
        reviewTimeLabel?.text = formatTime(reviewCounts.dateAvailable)
        radicalCountLabel?.text = formatInteger(reviewCounts.itemCounts.radicals)
        kanjiCountLabel?.text = formatInteger(reviewCounts.itemCounts.kanji)
        vocabularyCountLabel?.text = formatInteger(reviewCounts.itemCounts.vocabulary)
        totalCountLabel?.text = formatInteger(reviewCounts.itemCounts.total)
    }
    
    private func formatTime(_ date: Date) -> String {
        if date.timeIntervalSince1970 == 0 {
            return "Now"
        } else {
            return DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
        }
    }
    
    private func formatInteger(_ number: Int) -> String {
        return NumberFormatter.localizedString(from: NSNumber(value: number), number: .decimal)
    }
    
}
