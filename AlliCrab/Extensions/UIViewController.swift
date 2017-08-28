//
//  UIViewController.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os
import UIKit

extension UIViewController {
    func showAlert(title: String? = nil, message: String, completion: (() -> Void)? = nil) {
        if #available(iOS 10.0, *) {
            os_log("Displaying alert with title %@ and message %@", type: .debug, title ?? "<no title>", message)
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: completion)
    }
    
    var topPresentedViewController: UIViewController {
        guard var vc = presentedViewController else {
            return self
        }
        
        while true {
            guard let pvc = vc.presentedViewController else {
                return vc
            }
            vc = pvc
        }
    }
}
