//
//  AssignmentProgressionCollectionReusableView.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit

class AssignmentProgressionCollectionReusableView: UICollectionReusableView {
    
    private let backgroundBlurEffectStyle = UIBlurEffectStyle.extraLight
    
    let headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.font = UIFont.preferredFont(forTextStyle: .title1)
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            label.shadowColor = .black
            label.shadowOffset = CGSize(width: 1, height: 1)
        }
        if #available(iOS 10.0, *) {
            label.adjustsFontForContentSizeCategory = true
        }
        
        return label
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            let visualEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: backgroundBlurEffectStyle)))
            visualEffectView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            visualEffectView.frame = self.frame
            visualEffectView.preservesSuperviewLayoutMargins = true
            visualEffectView.contentView.preservesSuperviewLayoutMargins = true
            visualEffectView.contentView.addSubview(headerLabel)
            addSubview(visualEffectView)
        } else {
            addSubview(headerLabel)
        }
        
        headerLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        headerLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        headerLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
    
}
