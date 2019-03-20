//
//  WaniKaniLoginWebViewController.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os
import WaniKaniKit
import WebKit

private enum MessageHandlerName: String {
    case apiKey
}

private struct MessageKey {
    static let success = "apiKey"
    static let error = "apiKeyError"
}

private let getAPIKeyScript = """
    "use strict";
    $.get('/settings/personal_access_tokens').done(function(data, textStatus, jqXHR) {
        var apiKey = $(data).find('#personal-access-tokens-list .personal-access-token-description:contains("Default read-only")')
            .siblings('.personal-access-token-token')
            .children('code')
            .text();
        if (typeof apiKey === 'string') {
            window.webkit.messageHandlers.\(MessageHandlerName.apiKey.rawValue).postMessage({ '\(MessageKey.success)': apiKey });
        }
    }).fail(function(jqXHR, textStatus) {
        window.webkit.messageHandlers.\(MessageHandlerName.apiKey.rawValue).postMessage({ '\(MessageKey.error)': textStatus });
    });
    """

class WaniKaniLoginWebViewController: WebViewController {
    
    override func registerMessageHandlers(_ userContentController: WKUserContentController) {
        userContentController.add(self, name: MessageHandlerName.apiKey.rawValue)
        super.registerMessageHandlers(userContentController)
    }
    
    override func unregisterMessageHandlers(_ userContentController: WKUserContentController) {
        userContentController.removeScriptMessageHandler(forName: MessageHandlerName.apiKey.rawValue)
        super.unregisterMessageHandlers(userContentController)
    }
    
    // MARK: - Implementation
    
    func validate(apiKey: String) {
        if !apiKey.isEmpty {
            os_log("Received API Key %@", type: .debug, apiKey)
            ApplicationSettings.apiKey = apiKey
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let resourceRepository = appDelegate.makeResourceRepository(forAPIKey: apiKey)
            appDelegate.resourceRepository = resourceRepository
            appDelegate.presentDashboardViewController(animated: true)
            dismiss(animated: true, completion: nil)
        } else {
            os_log("Got blank API key", type: .info)
            self.showAlert(title: "No WaniKani API version 2 token found", message: "A WaniKani API version 2 personal access token could not be found for your account.  If you've never used a third-party app or user script, one may not have been generated and you should generate one now from the settings on the WaniKani web site.")
        }
    }
    
}

// MARK: - WKNavigationDelegate
extension WaniKaniLoginWebViewController {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        switch url {
        case WaniKaniURL.dashboard:
            os_log("Logged in: redirecting to settings", type: .debug)
            decisionHandler(.cancel)
            DispatchQueue.main.async {
                webView.load(URLRequest(url: WaniKaniURL.tokenSettings))
            }
        default:
            decisionHandler(.allow)
        }
    }
    
    override func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url, url == WaniKaniURL.tokenSettings else {
            super.webView(webView, didFinish: navigation)
            return
        }
        
        os_log("On settings page: fetching API Key", type: .debug)
        webView.evaluateJavaScript("""
            $('#personal-access-tokens-list .personal-access-token-description:contains("Default read-only")')
                .siblings('.personal-access-token-token')
                .children('code')
                .text();
            """) { apiKey, error in
                if let apiKey = apiKey as? String {
                    DispatchQueue.main.async {
                        self.validate(apiKey: apiKey)
                    }
                } else if let error = error {
                    os_log("Failed to execute API key fetch script: %@", type: .error, error as NSError)
                    webView.configuration.userContentController.addUserScript(WKUserScript(source: getAPIKeyScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
                }
        }
    }
}

// MARK: - WKScriptMessageHandler
extension WaniKaniLoginWebViewController {
    override func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let messageName = MessageHandlerName(rawValue: message.name) else {
            super.userContentController(userContentController, didReceive: message)
            return
        }
        
        switch messageName {
        case .apiKey:
            os_log("Received apiKey script message body %@", type: .debug, String(describing: message.body))
            let payload = message.body as! [String: Any]
            if let apiKey = payload[MessageKey.success] as? String {
                DispatchQueue.main.async {
                    self.validate(apiKey: apiKey)
                }
            } else if let error = payload[MessageKey.error] {
                os_log("Received script message error: %@", type: .debug, String(describing: error))
                DispatchQueue.main.async {
                    self.showAlert(title: "Unable to find WaniKani API tokens", message: "Please close this page and enter the API version 2 personal access token manually")
                }
            }
        }
    }
}
