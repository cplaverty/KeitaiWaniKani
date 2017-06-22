//
//  HomeScreenViewController.swift
//  AlliCrab
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import CocoaLumberjack
import SwiftyJSON
import WaniKaniKit

class HomeScreenViewController: UIViewController, WebViewControllerDelegate, WKWebViewControllerDelegate {
    
    struct SegueIdentifiers {
        static let showDashboard = "Show Dashboard"
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var buttonView: UIVisualEffectView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Actions
    
    @IBAction func loginButtonTouched(_ sender: UIButton) {
        let wvc = WaniKaniLoginWebViewController.wrapped(url: WaniKaniURLs.loginPage) { $0.delegate = self }
        
        present(wvc, animated: true, completion: nil)
    }
    
    @IBAction func apiKeySet(_ segue: UIStoryboardSegue) {
        ApplicationSettings.apiKeyVerified = true
    }
    
    // MARK: - WebViewControllerDelegate
    
    func webViewControllerDidFinish(_ controller: WebViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - WKWebViewControllerDelegate
    
    func wkWebViewControllerDidFinish(_ controller: WKWebViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        activityIndicator.startAnimating()
        validateAPIKey()
    }
    
    // Workaround to show the action sheet on WKWebView, which calls this on the root view controller
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        if let pvc = self.frontMostPresentedViewController {
            pvc.present(viewControllerToPresent, animated: flag, completion: completion)
        } else {
            super.present(viewControllerToPresent, animated: flag, completion: completion)
        }
    }
    
    // MARK: - Update UI
    
    func showLoginButtonsOnMainQueue() {
        ApplicationSettings.apiKeyVerified = false
        DDLogDebug("Background fetch interval = Never")
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
        DispatchQueue.main.async {
            self.buttonView.isHidden = false
        }
    }
    
    func validateAPIKey() {
        defer { activityIndicator.stopAnimating() }
        guard let apiKey = ApplicationSettings.apiKey, !apiKey.isEmpty && ApplicationSettings.apiKeyVerified else {
            DDLogDebug("We either do not have an API Key, or it hasn't been verified")
            showLoginButtonsOnMainQueue()
            return
        }
        
        DDLogInfo("API Key has been previously verified.  Showing dashboard...")
        showDashboardOnMainQueue()
    }
    
    func showDashboardOnMainQueue() {
        DDLogDebug("Background fetch interval = Minimum")
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: SegueIdentifiers.showDashboard, sender: self)
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
