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
    $.get('/settings/account').done(function(data, textStatus, jqXHR) {
        var apiKey = $(data).find('#user_api_key_v2').attr('value');
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
            if #available(iOS 10.0, *) {
                os_log("Received API Key %@", type: .debug, apiKey)
            }
            ApplicationSettings.apiKey = apiKey
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let resourceRepository = appDelegate.makeResourceRepository(forAPIKey: apiKey)
            appDelegate.resourceRepository = resourceRepository
            appDelegate.presentDashboardViewController(animated: true)
            dismiss(animated: true, completion: nil)
        } else {
            if #available(iOS 10.0, *) {
                os_log("Got blank API key", type: .info)
            }
            let alert = UIAlertController(title: "No API version 2 key found.  Would you like to generate one?", message: "A WaniKani API version 2 key could not be found for your account.  If you've never used a third-party app or user script, one may not have been generated and you should generate one now.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Generate API Version 2 Key", style: .default) { _ in
                self.webView.evaluateJavaScript("$('#edit_user_api_key_v2').submit();", completionHandler: { (_, error) in
                    if let error = error {
                        if #available(iOS 10.0, *) {
                            os_log("Failed to click API version 2 key generation button: %@", type: .error, error as NSError)
                        }
                        self.showAlert(title: "Failed to generate API version 2 key", message: "API version 2 key could not be generated: \(error.localizedDescription).  Please try again later.") { self.finish() }
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

// MARK: - WKNavigationDelegate
extension WaniKaniLoginWebViewController {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        switch url {
        case WaniKaniURL.dashboard:
            if #available(iOS 10.0, *) {
                os_log("Logged in: redirecting to settings", type: .debug)
            }
            decisionHandler(.cancel)
            DispatchQueue.main.async {
                webView.load(URLRequest(url: WaniKaniURL.accountSettings))
            }
        default:
            decisionHandler(.allow)
        }
    }
    
    override func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url, url == WaniKaniURL.accountSettings else {
            super.webView(webView, didFinish: navigation)
            return
        }
        
        if #available(iOS 10.0, *) {
            os_log("On settings page: fetching API Key", type: .debug)
        }
        webView.evaluateJavaScript("$('#user_api_key_v2').attr('value');") { apiKey, error in
            if let apiKey = apiKey as? String {
                DispatchQueue.main.async {
                    self.validate(apiKey: apiKey)
                }
            }
            else if let error = error {
                if #available(iOS 10.0, *) {
                    os_log("Failed to execute API key fetch script: %@", type: .error, error as NSError)
                }
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
            if #available(iOS 10.0, *) {
                os_log("Received apiKey script message body %@", type: .debug, String(describing: message.body))
            }
            let payload = message.body as! [String: Any]
            if let apiKey = payload[MessageKey.success] as? String {
                DispatchQueue.main.async {
                    self.validate(apiKey: apiKey)
                }
            } else if let error = payload[MessageKey.error] {
                if #available(iOS 10.0, *) {
                    os_log("Received script message error: %@", type: .debug, String(describing: error))
                }
            }
        }
    }
}
