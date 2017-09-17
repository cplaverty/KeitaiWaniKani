//
//  DurationDetailTableViewCell.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit

class DurationDetailTableViewCell: UITableViewCell {
    
    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.allowsFractionalUnits = true
        formatter.collapsesLargestUnit = true
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        return formatter
    }()
    
    func update(text: String, duration: TimeInterval?) {
        textLabel!.text = text
        
        if let duration = duration {
            if duration <= 0 {
                detailTextLabel!.text = "Now"
            } else {
                let formattedTimeSinceLevelStart = type(of: self).durationFormatter.string(from: duration, roundingUpwardToNearest: .oneMinute) ?? "???"
                detailTextLabel!.text = formattedTimeSinceLevelStart
            }
            detailTextLabel!.textColor = .black
        } else {
            detailTextLabel!.text = "-"
            detailTextLabel!.textColor = .lightGray
        }
    }
    
}
