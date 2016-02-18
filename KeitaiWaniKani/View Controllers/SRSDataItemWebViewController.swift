//
//  SRSDataItemWebViewController.swift
//  KeitaiWaniKani
//
//  Copyright © 2016 Chris Laverty. All rights reserved.
//

import UIKit
import WebKit

class SRSDataItemWebViewController: WKWebViewController {
    
    override func getUserScripts() -> [WKUserScript]? {
        var scripts: [WKUserScript] = []
        if ApplicationSettings.userScriptMarkdownNotesEnabled {
            scripts.append(WKUserScript(source: loadBundleResource("showdown.min", withExtension: "js", javascriptEncode: false), injectionTime: .AtDocumentEnd, forMainFrameOnly: true))
            scripts.append(WKUserScript(source: loadBundleResource("markdown.user", withExtension: "js", javascriptEncode: false), injectionTime: .AtDocumentEnd, forMainFrameOnly: true))
        }
        if ApplicationSettings.userScriptHideMnemonicsEnabled {
            scripts.append(WKUserScript(source: loadBundleResource("wkhidem.user", withExtension: "js", javascriptEncode: false), injectionTime: .AtDocumentEnd, forMainFrameOnly: true))
        }
        
        return scripts.isEmpty ? nil : scripts
    }
    
}
