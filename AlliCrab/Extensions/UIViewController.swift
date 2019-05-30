//
//  UIViewController.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os
import SafariServices
import UIKit

extension UIViewController {
    func showAlert(title: String? = nil, message: String, completion: (() -> Void)? = nil) {
        os_log("Displaying alert with title %@ and message %@", type: .debug, title ?? "<no title>", message)
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: completion)
    }
    
    func presentSafariViewController(url: URL) {
        let vc = SFSafariViewController(url: url)
        vc.preferredBarTintColor = .globalBarTintColor
        vc.preferredControlTintColor = .globalTintColor
        
        if #available(iOS 11.0, *) {
            vc.dismissButtonStyle = .close
        }
        present(vc, animated: true, completion: nil)
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
