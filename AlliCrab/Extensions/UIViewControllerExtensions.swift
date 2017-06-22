//
//  UIViewControllerExtensions.swift
//  AlliCrab
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import CocoaLumberjack

extension UIViewController {
    
    func showAlert(title: String? = nil, message: String, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            DDLogInfo("Displaying alert with title \(title ?? "<no title>") and message \(message)")
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            self.present(alert, animated: true, completion: completion)
        }
    }
    
}

extension UIStoryboardSegue {
    
    var destinationContentViewController: UIViewController {
        let dvc = self.destination
        if let nvc = dvc as? UINavigationController {
            return nvc.visibleViewController!
        } else {
            return dvc
        }
    }
    
}
