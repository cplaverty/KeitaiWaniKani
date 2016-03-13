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
                DDLogInfo("Got blank API key")
                dispatch_async(dispatch_get_main_queue()) {
                    let alert = UIAlertController(title: "No API key found.  Would you like to generate one now?", message: "A WaniKani API key could not be found for your account.  If you've never used a third-party app or user script, one may not have been generated and you should generate one now.", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "Generate API Key", style: .Default) { _ in
                        if let result = self.webView!.stringByEvaluatingJavaScriptFromString("$('#api-button').click();") {
                            DDLogVerbose("Received script message API Key generation button \(result)")
                        } else {
                            DDLogWarn("Failed to click API Key generation button")
                            self.showAlertWithTitle("Failed to generate API Key", message: "API Key could not be generated.  Please try again later.") { self.delegate?.webViewControllerDidFinish(self) }
                        }
                        })
                    alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel) { _ in
                        self.delegate?.webViewControllerDidFinish(self)
                        })
                    
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
        default: break
        }
    }
    
}
