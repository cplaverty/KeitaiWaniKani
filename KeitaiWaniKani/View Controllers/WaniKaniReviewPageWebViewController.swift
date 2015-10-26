//
//  WaniKaniReviewPageWebViewController.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import WebKit
import CocoaLumberjack
import WaniKaniKit

class WaniKaniReviewPageWebViewController: WebViewController, WKScriptMessageHandler {
    
    // MARK: - Properties
    
    override var allowsBackForwardNavigationGestures: Bool { return false }
    
    // MARK: - Initialisers
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        guard let URL = webView.URL else { return }
        
        switch URL {
        case WaniKaniURLs.lessonSession, WaniKaniURLs.reviewSession:
            showBrowserInterface(false, animated: true)
        default: break
        }
    }
    
    // MARK: - WKScriptMessageHandler
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        DDLogDebug("Received script message body \(message.body)")
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.removeInputAccessoryView()
        self.webView.configuration.userContentController.addScriptMessageHandler(self, name: "debuglog")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        showBrowserInterface(webView.URL != WaniKaniURLs.lessonSession && webView.URL != WaniKaniURLs.reviewSession, animated: true)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func getUserScripts() -> [String]? {
        var scripts = [getUserScriptContent("common"), getUserScriptContent("resize")]
    
        if ApplicationSettings.userScriptIgnoreAnswerEnabled {
            scripts.append(getUserScriptContent("wkoverride.user"))
        }
        if ApplicationSettings.userScriptWaniKaniImproveEnabled {
            scripts.append(getUserScriptContent("jquery.qtip.min"))
            scripts.append(getUserScriptContent("wkimprove"))
        }
        
        return scripts
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
        showBrowserInterface(false, animated: false)
        webView.scrollToTop(false)
        webView.setScrollEnabled(false)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        webView.setScrollEnabled(true)
    }
    
}
