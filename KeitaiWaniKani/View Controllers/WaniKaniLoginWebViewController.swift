//
//  WaniKaniLoginWebViewController.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import CocoaLumberjack
import WaniKaniKit

class WaniKaniLoginWebViewController: WebViewController {
    
    // MARK: - Properties
    
    private let getApiKeyScriptSource: String = "$('#api-button').parent().find('input').attr('value');"
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - WKScriptMessageHandler
    
    override func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard super.webView(webView, shouldStartLoadWithRequest: request, navigationType: navigationType) else {
            return false
        }
        
        if request.URL == WaniKaniURLs.dashboard {
            // Wait half a second for the request to be cancelled
            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
            dispatch_after(when, dispatch_get_main_queue()) {
                webView.loadRequest(NSURLRequest(URL: WaniKaniURLs.account))
            }
            return false
        }
        
        return true
    }
    
    override func webViewDidFinishLoad(webView: UIWebView) {
        super.webViewDidFinishLoad(webView)
        guard let URL = webView.request?.URL else {
            return
        }
        
        switch URL {
        case WaniKaniURLs.account:
            if let apiKey = webView.stringByEvaluatingJavaScriptFromString(getApiKeyScriptSource) where !apiKey.isEmpty {
                DDLogVerbose("Received script message API Key \(apiKey)")
                ApplicationSettings.apiKey = apiKey
                ApplicationSettings.apiKeyVerified = true
                delegate?.webViewControllerDidFinish(self)
            } else {
                DDLogWarn("Got blank API key")
                showAlertWithTitle("No API key found", message: "Check your account page to ensure an API key has been generated and reload the page to try again.")
            }
        default: break
        }
    }
    
}
