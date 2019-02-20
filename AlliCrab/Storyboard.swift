//
//  Storyboard.swift
//  AlliCrab
//
//  Copyright © 2019 Chris Laverty. All rights reserved.
//

import UIKit

enum Storyboard: String {
    case login = "Login"
    case main = "Main"
    
    var instance: UIStoryboard {
        return UIStoryboard(name: rawValue, bundle: Bundle.main)
    }
}
