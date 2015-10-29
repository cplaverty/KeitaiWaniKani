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
        webView.dataDetectorTypes = .None
        webView.keyboardDisplayRequiresUserAction = false
        if #available(iOS 9.0, *) {
            webView.allowsLinkPreview = false
        }
        
        return webView
    }

    // MARK: - Initialisers
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - UIWebViewDelegate
    
    override func webViewDidFinishLoad(webView: UIWebView) {
        super.webViewDidFinishLoad(webView)
        
        guard let URL = webView.request?.URL else { return }
        
        switch URL {
        case WaniKaniURLs.lessonSession:
            showBrowserInterface(false, animated: true)
            webView.removeInputAccessoryView()
            DDLogDebug("Loading user scripts")
            webView.stringByEvaluatingJavaScriptFromString(getUserScriptContent("common"))
            webView.stringByEvaluatingJavaScriptFromString(getUserScriptContent("resize"))
        case WaniKaniURLs.reviewSession:
            showBrowserInterface(false, animated: true)
            webView.removeInputAccessoryView()
            DDLogDebug("Loading user scripts")
            webView.stringByEvaluatingJavaScriptFromString(getUserScriptContent("common"))
            webView.stringByEvaluatingJavaScriptFromString(getUserScriptContent("resize"))
            if ApplicationSettings.userScriptIgnoreAnswerEnabled {
                webView.stringByEvaluatingJavaScriptFromString(getUserScriptContent("wkdoublecheck"))
            }
            if ApplicationSettings.userScriptWaniKaniImproveEnabled {
                webView.stringByEvaluatingJavaScriptFromString(getUserScriptContent("jquery.qtip.min"))
                webView.stringByEvaluatingJavaScriptFromString(getUserScriptContent("wkimprove"))
            }
        default: break
        }
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        showBrowserInterface(webView.request?.URL != WaniKaniURLs.lessonSession && webView.request?.URL != WaniKaniURLs.reviewSession, animated: true)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    // MARK: - Update UI
    
    func showBrowserInterface(showBrowserInterface: Bool, animated: Bool) {
        guard let nc = self.navigationController else { return }
        
        nc.setNavigationBarHidden(!showBrowserInterface, animated: animated)
        if self.toolbarItems?.isEmpty == false {
            nc.setToolbarHidden(!showBrowserInterface, animated: animated)
        }
    }
    
    func keyboardDidShow(notification: NSNotification) {
        guard let URL = webView.request?.URL where URL == WaniKaniURLs.lessonSession || URL == WaniKaniURLs.reviewSession else { return }
        
        showBrowserInterface(false, animated: false)
        webView.scrollToTop(false)
        webView.setScrollEnabled(false)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        webView.setScrollEnabled(true)
    }
    
}
