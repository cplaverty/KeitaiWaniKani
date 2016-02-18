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
    
    private var userScriptsInjected = false
    
    // MARK: - Initialisers
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - UIWebViewDelegate
    
    override func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard super.webView(webView, shouldStartLoadWithRequest: request, navigationType: navigationType) else {
            return false
        }
        
        guard let URL = request.URL
            where URL.path != WaniKaniURLs.reviewHome.path && URL.path != WaniKaniURLs.reviewSession.path &&
                URL.path != WaniKaniURLs.lessonHome.path && URL.path != WaniKaniURLs.lessonSession.path else {
                    return true
        }
        
        guard let referer = request.valueForHTTPHeaderField("Referer"),
            let refererURL = NSURL(string: referer)
            where (refererURL == WaniKaniURLs.reviewSession || refererURL == WaniKaniURLs.lessonSession) && navigationType == .LinkClicked else {
                return true
        }
        
        let newVC = self.dynamicType.init(URL: URL)
        newVC.delegate = self
        self.navigationController?.pushViewController(newVC, animated: true)
        
        return false
    }
    
    override func webViewDidStartLoad(webView: UIWebView) {
        super.webViewDidStartLoad(webView)
        if let requestURLStarted = requestStack.last?.URL
            where requestURLStarted == WaniKaniURLs.lessonSession || requestURLStarted == WaniKaniURLs.reviewSession {
                userScriptsInjected = false
        }
    }
    
    override func webViewDidFinishLoad(webView: UIWebView) {
        super.webViewDidFinishLoad(webView)
        
        guard let URL = webView.request?.URL else { return }
        guard !userScriptsInjected else { return }
        
        switch URL {
        case WaniKaniURLs.lessonSession:
            showBrowserInterface(false, animated: true)
            DDLogDebug("Loading user scripts")
            injectScript("common", inWebView: webView)
            injectStyleSheet("resize", inWebView: webView)
            userScriptsInjected = true
        case WaniKaniURLs.reviewSession:
            showBrowserInterface(false, animated: true)
            DDLogDebug("Loading user scripts")
            injectScript("common", inWebView: webView)
            injectStyleSheet("resize", inWebView: webView)
            if ApplicationSettings.userScriptIgnoreAnswerEnabled {
                injectScript("wkoverride.user", inWebView: webView)
            }
            if ApplicationSettings.userScriptDoubleCheckEnabled {
                injectScript("wkdoublecheck", inWebView: webView)
            }
            if ApplicationSettings.userScriptWaniKaniImproveEnabled {
                injectStyleSheet("jquery.qtip.min", inWebView: webView)
                injectScript("jquery.qtip.min", inWebView: webView)
                injectScript("wkimprove", inWebView: webView)
            }
            if ApplicationSettings.userScriptMarkdownNotesEnabled {
                injectScript("showdown.min", inWebView: webView)
                injectScript("markdown.user", inWebView: webView)
            }
            userScriptsInjected = true
        default: break
        }
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        allowsBackForwardNavigationGestures = false
        super.viewDidLoad()
        webView.removeInputAccessoryView()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        showBrowserInterface(webView.request?.URL != WaniKaniURLs.lessonSession && webView.request?.URL != WaniKaniURLs.reviewSession, animated: true)
    }
    
    // MARK: - Update UI
    
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
