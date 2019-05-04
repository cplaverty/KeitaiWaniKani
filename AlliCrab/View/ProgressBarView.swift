//
//  ProgressBarView.swift
//  AlliCrab
//
//  Copyright © 2019 Chris Laverty. All rights reserved.
//

import UIKit

@IBDesignable
class ProgressBarView: UIView, XibLoadable {
    
    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.roundingMode = .down
        formatter.roundingIncrement = 0.01
        return formatter
    }()
    
    // MARK: - Properties
    
    @IBInspectable var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }
    
    @IBInspectable var progress: Float {
        get {
            return progressView.progress
        }
        set {
            progressView.setProgress(newValue, animated: newValue > 0)
            let formattedFractionComplete = type(of: self).percentFormatter.string(from: newValue as NSNumber)
            percentCompleteLabel.text = formattedFractionComplete
        }
    }
    
    @IBInspectable var totalCount: Int = 0 {
        didSet {
            totalItemCountLabel.text = NumberFormatter.localizedString(from: totalCount as NSNumber, number: .decimal)
        }
    }
    
    // MARK: - Outlets
    
    var contentView : UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var percentCompleteLabel: UILabel!
    @IBOutlet weak var totalItemCountLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    // MARK: - Initialisers
    
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
    
}
