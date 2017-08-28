//
//  DashboardTableViewHeaderFooterView.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit

class DashboardTableViewHeaderFooterView: UITableViewHeaderFooterView {
    
    private let backgroundBlurEffectStyle = UIBlurEffectStyle.extraLight
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.font = UIFont.preferredFont(forTextStyle: .title2)
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            label.shadowColor = .black
            label.shadowOffset = CGSize(width: 1, height: 1)
        }
        if #available(iOS 10.0, *) {
            label.adjustsFontForContentSizeCategory = true
        }
        
        return label
    }()
    
    override var textLabel: UILabel? {
        return nil
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            let visualEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: backgroundBlurEffectStyle)))
            visualEffectView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            visualEffectView.preservesSuperviewLayoutMargins = true
            visualEffectView.contentView.preservesSuperviewLayoutMargins = true
            visualEffectView.contentView.addSubview(titleLabel)
            contentView.addSubview(visualEffectView)
        } else {
            contentView.addSubview(titleLabel)
        }
        
        layoutMarginsGuide.topAnchor.constraint(greaterThanOrEqualTo: titleLabel.topAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
