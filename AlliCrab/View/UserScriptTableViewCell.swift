//
//  UserScriptTableViewCell.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit

class UserScriptTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    
    var userScript: UserScript? {
        didSet {
            guard let userScript = userScript else {
                toggleSwitch.isEnabled = false
                toggleSwitch.isOn = false
                return
            }
            
            toggleSwitch.isEnabled = true
            toggleSwitch.isOn = userScript.isEnabled
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var enableTextLabel: UILabel!
    @IBOutlet weak var toggleSwitch: UISwitch!
    
    // MARK: - Actions
    
    @IBAction func toggleSwitch(_ sender: UISwitch) {
        userScript?.isEnabled = sender.isOn
    }
}
