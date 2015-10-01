//
//  UIViewControllerExtensions.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import CocoaLumberjack

extension UIViewController {

    func showAlertWithTitle(title: String, message: String, completion: (() -> Void)? = nil) {
        dispatch_async(dispatch_get_main_queue()) {
            DDLogInfo("Displaying alert with title \(title) and message \(message)")
            let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            
            self.presentViewController(alert, animated: true, completion: completion)
        }
    }

}

extension UIStoryboardSegue {

    var destinationContentViewController: UIViewController {
        let dvc = self.destinationViewController
        if let nvc = dvc as? UINavigationController {
            return nvc.visibleViewController!
        } else {
            return dvc
        }
    }

}