//
//  WaniKaniLoginWebViewController.swift
//  AlliCrab
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import WebKit
import CocoaLumberjack
import WaniKaniKit

private struct MessageHandlerNames {
    static let success = "apiKey"
    static let error = "apiKeyError"
}

class WaniKaniLoginWebViewController: WKWebViewController {
    
    // MARK: - WKNavigationDelegate
    
    override func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        super.webView(webView, didStartProvisionalNavigation: navigation)
        injectScript(name: "getapikey")
    }
    
    // MARK: - WKScriptMessageHandler
    
    override func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case MessageHandlerNames.success:
            DDLogVerbose("Received apiKey script message body \(message.body)")
            let apiKey = message.body as! String
            validate(apiKey: apiKey)
        case MessageHandlerNames.error:
            DDLogWarn("Received script message error: \(message.body)")
        default:
            super.userContentController(userContentController, didReceive: message)
        }
    }
    
    // MARK: - Implementation
    
    func validate(apiKey: String) {
        if !apiKey.isEmpty {
            DDLogVerbose("Received script message API Key \(apiKey)")
            ApplicationSettings.apiKey = apiKey
            ApplicationSettings.apiKeyVerified = true
            finish()
        } else {
            DDLogInfo("Got blank API key")
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "No API key found.  Would you like to generate one?", message: "A WaniKani API key could not be found for your account.  If you've never used a third-party app or user script, one may not have been generated and you should generate one now.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Generate API Key", style: .default) { _ in
                    self.webView.evaluateJavaScript("$('#edit_user_api_key').submit();", completionHandler: { (_, error) in
                        if let error = error {
                            DDLogWarn("Failed to click API Key generation button")
                            self.showAlert(title: "Failed to generate API Key", message: "API Key could not be generated: \(error).  Please try again later.") { self.finish() }
                        }
                    })
                })
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                    self.finish()
                })
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    override func registerMessageHandlers(_ userContentController: WKUserContentController) {
        userContentController.add(self, name: MessageHandlerNames.success)
        userContentController.add(self, name: MessageHandlerNames.error)
        super.registerMessageHandlers(userContentController)
    }
    
    override func unregisterMessageHandlers(_ userContentController: WKUserContentController) {
        userContentController.removeScriptMessageHandler(forName: MessageHandlerNames.success)
        userContentController.removeScriptMessageHandler(forName: MessageHandlerNames.error)
        super.unregisterMessageHandlers(userContentController)
    }
    
}
