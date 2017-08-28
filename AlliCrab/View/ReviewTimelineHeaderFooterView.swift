//
//  ReviewTimelineHeaderFooterView.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit

class ReviewTimelineHeaderFooterView: UITableViewHeaderFooterView {
    
    private static let reviewDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .darkGray
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        if #available(iOS 10.0, *) {
            label.adjustsFontForContentSizeCategory = true
        }
        
        return label
    }()
    
    let countLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .darkGray
        label.font = UIFont.preferredFont(forTextStyle: .callout)
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
        
        preservesSuperviewLayoutMargins = true
        layoutMargins.top = 4
        layoutMargins.bottom = 4

        addSubview(titleLabel)
        addSubview(countLabel)
        
        titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        
        countLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        countLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        countLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateHeader(date: Date, totalForDay: Int) {
        if date.timeIntervalSince1970 == 0 {
            titleLabel.text = type(of: self).reviewDateFormatter.string(from: Date())
        } else {
            titleLabel.text = type(of: self).reviewDateFormatter.string(from: date)
        }
        countLabel.text = NumberFormatter.localizedString(from: totalForDay as NSNumber, number: .decimal)
    }
    
}
