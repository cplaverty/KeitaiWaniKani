//
//  WaniKaniReviewPageWebViewController.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import WebKit
import WaniKaniKit

class WaniKaniReviewPageWebViewController: WebViewController {
    
    // MARK: - WKNavigationDelegate
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        guard let URL = webView.URL else { return }
        
        switch URL {
        case WaniKaniURLs.lessonSession, WaniKaniURLs.reviewSession:
            showBrowserInterface(false)
        default: break
        }
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        showBrowserInterface(webView.URL != WaniKaniURLs.lessonSession && webView.URL != WaniKaniURLs.reviewSession)
    }
    
    // MARK: - Update UI
    
    func showBrowserInterface(showBrowserInterface: Bool) {
        self.navigationController?.setNavigationBarHidden(!showBrowserInterface, animated: true)
        self.navigationController?.setToolbarHidden(!showBrowserInterface, animated: true)
    }
    
}
