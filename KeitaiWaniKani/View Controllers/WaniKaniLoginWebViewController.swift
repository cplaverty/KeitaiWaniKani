//
//  WaniKaniLoginWebViewController.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import WebKit
import CocoaLumberjack

class WaniKaniLoginWebViewController: WebViewController, WKScriptMessageHandler {
    
    // MARK: - Properties
    
    private lazy var getApiKeyScriptSource: String = {
        return
        "$.get('/account').done(function(data, textStatus, jqXHR) {" +
            "var apiKey = $(data).find('#api-button').parent().find('input').attr('value');" +
            "if (typeof apiKey === 'string') {" +
            "window.webkit.messageHandlers.apiKey.postMessage({ apiKey: apiKey });" +
            "}" +
            "}).fail(function(jqXHR, textStatus) {" +
            "window.webkit.messageHandlers.apiKey.postMessage({ error: textStatus });" +
        "});"
    }()
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.configuration.userContentController.addScriptMessageHandler(self, name: "apiKey")
    }
    
    // MARK: - WKScriptMessageHandler
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        DDLogVerbose("Received script message body \(message.body)")
        if let responseDictionary = message.body as? [String: NSObject] {
            if let apiKey = responseDictionary["apiKey"] as? String {
                DDLogVerbose("Received script message API Key \(apiKey)")
                ApplicationSettings.apiKey = apiKey
                ApplicationSettings.apiKeyVerified = true
                delegate?.webViewControllerDidFinish(self)
            }
            if let error = responseDictionary["error"] {
                DDLogWarn("Received script message error: \(error)")
            }
        }
    }
    
    // MARK: - User Scripts
    
    override func getUserScripts() -> [String]? {
        return [getApiKeyScriptSource]
    }
    
}
