//
//  NumericDetailTableViewCell.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit

class NumericDetailTableViewCell: UITableViewCell {
    
    var availableColour: UIColor = .black
    var unavailableColour: UIColor = .lightGray
    
    func update(text: String, value: Int?) {
        textLabel!.text = text
        if let value = value {
            detailTextLabel!.text = NumberFormatter.localizedString(from: value as NSNumber, number: .decimal)
            detailTextLabel!.textColor = value > 0 ? availableColour : unavailableColour
        } else {
            detailTextLabel!.text = "-"
            detailTextLabel!.textColor = unavailableColour
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        availableColour = .black
        unavailableColour = .lightGray
    }
}
