//
//  HomeScreenViewController.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import CocoaLumberjack
import SwiftyJSON
import WaniKaniKit

class HomeScreenViewController: UIViewController, WebViewControllerDelegate {
    
    struct SegueIdentifiers {
        static let showDashboard = "Show Dashboard"
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var buttonView: UIVisualEffectView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Actions
    
    @IBAction func loginButtonTouched(sender: UIButton) {
        let wvc = WaniKaniLoginWebViewController.forURL(WaniKaniURLs.loginPage) { $0.delegate = self }
        
        presentViewController(wvc, animated: true, completion: nil)
    }
    
    @IBAction func apiKeySet(segue: UIStoryboardSegue) {
        ApplicationSettings.apiKeyVerified = true
    }
    
    // MARK: - WebViewControllerDelegate
    
    func webViewControllerDidFinish(controller: WebViewController) {
        controller.dismissViewControllerAnimated(true) {
            self.validateAPIKey()
        }
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        activityIndicator.startAnimating()
        validateAPIKey()
    }

    // Workaround to show the action sheet on WKWebView, which calls this on the root view controller
    override func presentViewController(viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        if let pvc = self.frontMostPresentedViewController {
            pvc.presentViewController(viewControllerToPresent, animated: flag, completion: completion)
        } else {
            super.presentViewController(viewControllerToPresent, animated: flag, completion: completion)
        }
    }

    // MARK: - Update UI
    
    func showLoginButtonsOnMainQueue() {
        ApplicationSettings.apiKeyVerified = false
        DDLogDebug("Background fetch interval = Never")
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
        dispatch_async(dispatch_get_main_queue()) {
            self.buttonView.hidden = false
        }
    }
    
    func validateAPIKey() {
        defer { activityIndicator.stopAnimating() }
        guard let apiKey = ApplicationSettings.apiKey where !apiKey.isEmpty && ApplicationSettings.apiKeyVerified else {
            DDLogDebug("We either do not have an API Key, or it hasn't been verified")
            showLoginButtonsOnMainQueue()
            return
        }
        
        DDLogInfo("API Key has been previously verified.  Showing dashboard...")
        showDashboardOnMainQueue()
    }
    
    func showDashboardOnMainQueue() {
        DDLogDebug("Background fetch interval = Minimum")
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        dispatch_async(dispatch_get_main_queue()) {
            self.performSegueWithIdentifier(SegueIdentifiers.showDashboard, sender: self)
        }
    }

}

private extension UIViewController {
    
    var frontMostPresentedViewController: UIViewController? {
        var vc: UIViewController? = presentedViewController
        while vc != nil {
            if let pvc = vc?.presentedViewController {
                vc = pvc
            } else {
                return vc
            }
        }
        
        return vc
    }
    
}