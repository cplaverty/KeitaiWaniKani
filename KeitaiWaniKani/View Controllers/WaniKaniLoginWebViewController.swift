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
    
    override func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard super.webView(webView, shouldStartLoadWith: request, navigationType: navigationType) else {
            return false
        }
        
        if request.url == WaniKaniURLs.dashboard {
            // Wait half a second for the request to be cancelled
            let when = DispatchTime.now() + 0.5
            DispatchQueue.main.asyncAfter(deadline: when) {
                webView.loadRequest(URLRequest(url: WaniKaniURLs.account))
            }
            return false
        }
        
        return true
    }
    
    override func webViewDidFinishLoad(_ webView: UIWebView) {
        super.webViewDidFinishLoad(webView)
        guard let URL = webView.request?.url else {
            return
        }
        
        switch URL {
        case WaniKaniURLs.account:
            if let apiKey = webView.stringByEvaluatingJavaScript(from: getApiKeyScriptSource), !apiKey.isEmpty {
                DDLogVerbose("Received script message API Key \(apiKey)")
                ApplicationSettings.apiKey = apiKey
                ApplicationSettings.apiKeyVerified = true
                delegate?.webViewControllerDidFinish(self)
            } else {
                DDLogInfo("Got blank API key")
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "No API key found.  Would you like to generate one now?", message: "A WaniKani API key could not be found for your account.  If you've never used a third-party app or user script, one may not have been generated and you should generate one now.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Generate API Key", style: .default) { _ in
                        if let result = self.webView!.stringByEvaluatingJavaScript(from: "$('#api-button').click();") {
                            DDLogVerbose("Received script message API Key generation button \(result)")
                        } else {
                            DDLogWarn("Failed to click API Key generation button")
                            self.showAlert(title: "Failed to generate API Key", message: "API Key could not be generated.  Please try again later.") { self.delegate?.webViewControllerDidFinish(self) }
                        }
                        })
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                        self.delegate?.webViewControllerDidFinish(self)
                        })
                    
                    self.present(alert, animated: true, completion: nil)
                }
            }
        default: break
        }
    }
    
}
