//
//  SRSProgressTableViewCell.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit
import WaniKaniKit

class SRSProgressTableViewCell: UITableViewCell {
    
    private(set) var srsStage: SRSStage?
    
    func update(srsStage: SRSStage, srsDistribution: SRSDistribution?) {
        self.srsStage = srsStage
        
        imageView?.image = UIImage(named: srsStage.rawValue)?.withRenderingMode(.alwaysTemplate)
        imageView?.tintColor = srsStage.backgroundColor
        
        textLabel?.text = srsStage.rawValue
        textLabel?.textColor = srsStage.backgroundColor
        
        if let srsDistribution = srsDistribution {
            let itemCounts = srsDistribution.countsBySRSStage[srsStage] ?? SRSItemCounts.zero
            let formattedCount = NumberFormatter.localizedString(from: itemCounts.total as NSNumber, number: .decimal)
            detailTextLabel!.text = formattedCount
            detailTextLabel!.textColor = .black
        } else {
            detailTextLabel!.text = "-"
            detailTextLabel!.textColor = .lightGray
        }
    }
    
}
