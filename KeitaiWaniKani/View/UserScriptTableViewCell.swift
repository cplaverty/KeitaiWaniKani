//
//  UserScriptTableViewCell.swift
//  AlliCrab
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit

class UserScriptTableViewCell: UITableViewCell {
    
    // MARK: Properties
    
    var userScript: UserScript? {
        didSet {
            settingNameLabel.text = userScript?.name
            settingDescriptionLabel.text = userScript?.description
            toggleSwitch.isEnabled = userScript != nil
            toggleSwitch.isOn = userScript?.isEnabled ?? false
        }
    }
    
    // MARK: Outlets
    
    @IBOutlet weak var settingNameLabel: UILabel!
    @IBOutlet weak var settingDescriptionLabel: UILabel!
    @IBOutlet weak var toggleSwitch: UISwitch!
    @IBOutlet weak var nameToDescriptionLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var descriptionHeightConstraint: NSLayoutConstraint!
    
    // MARK: Actions
    
    @IBAction func toggleSwitch(_ sender: UISwitch) {
        userScript?.isEnabled = sender.isOn
    }
    
    func toggleDescriptionVisibility() {
        if descriptionHeightConstraint.constant == 0 {
            // show
            nameToDescriptionLayoutConstraint.constant = 8
            descriptionHeightConstraint.constant = 1000
            settingDescriptionLabel.alpha = 1
        } else {
            // hide
            nameToDescriptionLayoutConstraint.constant = 0
            descriptionHeightConstraint.constant = 0
            settingDescriptionLabel.alpha = 0
        }
        contentView.setNeedsUpdateConstraints()
    }
    
    func setToDefault() {
        settingDescriptionLabel.alpha = 0
        nameToDescriptionLayoutConstraint.constant = 0
        descriptionHeightConstraint.constant = 0
        contentView.setNeedsUpdateConstraints()
    }
    
}
