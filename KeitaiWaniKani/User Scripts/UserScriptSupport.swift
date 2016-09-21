//
//  SupportsUserScripts.swift
//  KeitaiWaniKani
//
//  Copyright © 2016 Chris Laverty. All rights reserved.
//

import CocoaLumberjack
import WebKit
import WaniKaniKit

protocol UserScriptSupport {
    func injectScript(name: String)
    func injectStyleSheet(name: String)
    
    func injectUserScripts(for: URL) -> Bool
}

extension UserScriptSupport {
    func injectUserScripts(for url: URL) -> Bool {
        switch url {
        case WaniKaniURLs.loginPage:
            DDLogDebug("Loading user scripts")
            injectStyleSheet(name: "common")
            injectScript(name: "common")
            return true
        case WaniKaniURLs.lessonSession:
            DDLogDebug("Loading user scripts")
            injectStyleSheet(name: "common")
            injectScript(name: "common")
            injectStyleSheet(name: "resize")
            if ApplicationSettings.disableLessonSwipe {
                injectScript(name: "noswipe")
            }
            if ApplicationSettings.userScriptHideMnemonicsEnabled {
                injectScript(name: "wkhidem.user")
            }
            if ApplicationSettings.userScriptReorderUltimateEnabled {
                injectScript(name: "WKU.user")
            }
            return true
        case WaniKaniURLs.reviewSession:
            DDLogDebug("Loading user scripts")
            injectStyleSheet(name: "common")
            injectScript(name: "common")
            injectStyleSheet(name: "resize")
            if ApplicationSettings.userScriptJitaiEnabled {
                injectScript(name: "jitai.user")
            }
            if ApplicationSettings.userScriptIgnoreAnswerEnabled {
                injectScript(name: "wkoverride.user")
            }
            if ApplicationSettings.userScriptDoubleCheckEnabled {
                injectScript(name: "wkdoublecheck")
            }
            if ApplicationSettings.userScriptWaniKaniImproveEnabled {
                injectStyleSheet(name: "jquery.qtip.min")
                injectScript(name: "jquery.qtip.min")
                injectScript(name: "wkimprove")
            }
            if ApplicationSettings.userScriptMarkdownNotesEnabled {
                injectScript(name: "showdown.min")
                injectScript(name: "markdown.user")
            }
            if ApplicationSettings.userScriptHideMnemonicsEnabled {
                injectScript(name: "wkhidem.user")
            }
            if ApplicationSettings.userScriptReorderUltimateEnabled {
                injectScript(name: "WKU.user")
            }
            return true
        case _ where url.path.hasPrefix(WaniKaniURLs.levelRoot.path) || url.path.hasPrefix(WaniKaniURLs.radicalRoot.path) || url.path.hasPrefix(WaniKaniURLs.kanjiRoot.path) || url.path.hasPrefix(WaniKaniURLs.vocabularyRoot.path):
            if ApplicationSettings.userScriptMarkdownNotesEnabled {
                injectScript(name: "showdown.min")
                injectScript(name: "markdown.user")
            }
            if ApplicationSettings.userScriptHideMnemonicsEnabled {
                injectScript(name: "wkhidem.user")
            }
            return true
        default:
            return false
        }
    }
}

// MARK: - UIWebView

protocol UIWebViewUserScriptSupport: UserScriptSupport, BundleResourceLoader {
    var webView: UIWebView? { get }
}

extension UIWebViewUserScriptSupport {
    func injectStyleSheet(name: String) {
        guard let webView = self.webView else { return }
        
        DDLogDebug("Loading stylesheet \(name).css")
        let contents = loadBundleResource(name: name, withExtension: "css", javascriptEncode: true)
        
        let script = "var style = document.createElement('style');style.setAttribute('type', 'text/css');style.appendChild(document.createTextNode('\(contents)'));document.head.appendChild(document.createComment('\(name).css'));document.head.appendChild(style);"
        
        if webView.stringByEvaluatingJavaScript(from: script) == nil {
            DDLogError("Failed to add style sheet \(name).css")
        }
    }
    
    func injectScript(name: String) {
        guard let webView = self.webView else { return }
        
        DDLogDebug("Loading script \(name).js")
        let contents = loadBundleResource(name: name, withExtension: "js", javascriptEncode: true)
        
        let script = "var script = document.createElement('script');script.setAttribute('type', 'text/javascript');script.appendChild(document.createTextNode('\(contents)'));document.head.appendChild(document.createComment('\(name).js'));document.head.appendChild(script);"
        if webView.stringByEvaluatingJavaScript(from: script) == nil {
            DDLogError("Failed to add script \(name).js")
        }
    }
}

// MARK: - WKWebView

protocol WKWebViewUserScriptSupport: UserScriptSupport, BundleResourceLoader {
    var webView: WKWebView! { get }
}

extension WKWebViewUserScriptSupport {
    func injectStyleSheet(name: String) {
        DDLogDebug("Loading stylesheet \(name).css")
        let cssContents = loadBundleResource(name: name, withExtension: "css", javascriptEncode: true)
        let contents = "var style = document.createElement('style');style.setAttribute('type', 'text/css');style.appendChild(document.createTextNode('\(cssContents)'));document.head.appendChild(document.createComment('\(name).css'));document.head.appendChild(style);"
        let script = WKUserScript(source: contents, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        webView.configuration.userContentController.addUserScript(script)
    }
    
    func injectScript(name: String) {
        DDLogDebug("Loading script \(name).js")
        let contents = loadBundleResource(name: name, withExtension: "js", javascriptEncode: false)
        let script = WKUserScript(source: contents, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        webView.configuration.userContentController.addUserScript(script)
    }
}
