//
//  WaniKaniReviewPageWebViewController.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import CocoaLumberjack
import WaniKaniKit

class WaniKaniReviewPageWebViewController: WebViewController {
    
    // MARK: - Properties
    
    override func createWebView() -> UIWebView {
        let webView = super.createWebView()
        webView.dataDetectorTypes = UIDataDetectorTypes()
        webView.keyboardDisplayRequiresUserAction = false
        if #available(iOS 9.0, *) {
            webView.allowsLinkPreview = false
        }
        
        return webView
    }
    
    override var allowsBackForwardNavigationGestures: Bool { return false }
    
    // MARK: - Initialisers
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UIWebViewDelegate
    
    override func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard super.webView(webView, shouldStartLoadWith: request, navigationType: navigationType) else {
            return false
        }
        
        guard let url = request.url,
            url.path != WaniKaniURLs.reviewHome.path && url.path != WaniKaniURLs.reviewSession.path &&
                url.path != WaniKaniURLs.lessonHome.path && url.path != WaniKaniURLs.lessonSession.path else {
                    return true
        }
        
        guard let referer = request.value(forHTTPHeaderField: "Referer"),
            let refererURL = Foundation.URL(string: referer),
            (refererURL == WaniKaniURLs.reviewSession || refererURL == WaniKaniURLs.lessonSession) && navigationType == .linkClicked else {
                return true
        }
        
        let newVC = type(of: self).init(url: url)
        newVC.delegate = self
        self.navigationController?.pushViewController(newVC, animated: true)
        
        return false
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView?.removeInputAccessoryView()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showBrowserInterface(webView?.request?.url != WaniKaniURLs.lessonSession && webView?.request?.url != WaniKaniURLs.reviewSession, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ApplicationSettings.forceRefresh = true
    }
    
    // MARK: - Update UI
    
    func keyboardDidShow(_ notification: Notification) {
        guard let webView = self.webView, let URL = webView.request?.url, URL == WaniKaniURLs.lessonSession || URL == WaniKaniURLs.reviewSession else { return }
        
        showBrowserInterface(false, animated: false)
    }
    
}
