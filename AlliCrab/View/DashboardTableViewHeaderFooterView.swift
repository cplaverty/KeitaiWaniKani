//
//  DashboardTableViewHeaderFooterView.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit

class DashboardTableViewHeaderFooterView: UITableViewHeaderFooterView {
    
    private let backgroundBlurEffectStyle = UIBlurEffect.Style.extraLight
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.preferredFont(forTextStyle: .title2)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        if !UIAccessibility.isReduceTransparencyEnabled {
            label.shadowColor = .black
            label.shadowOffset = CGSize(width: 1, height: 1)
        }
        
        return label
    }()
    
    override var textLabel: UILabel? {
        return nil
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        if !UIAccessibility.isReduceTransparencyEnabled {
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
