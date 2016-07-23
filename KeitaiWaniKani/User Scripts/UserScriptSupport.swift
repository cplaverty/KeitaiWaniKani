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
    
    func injectUserScriptsForURL(URL: NSURL) -> Bool
}

extension UserScriptSupport {
    func injectUserScriptsForURL(URL: NSURL) -> Bool {
        switch URL {
        case WaniKaniURLs.loginPage:
            DDLogDebug("Loading user scripts")
            injectScript("common")
            return true
        case WaniKaniURLs.lessonSession:
            DDLogDebug("Loading user scripts")
            injectScript("common")
            injectStyleSheet("resize")
            if ApplicationSettings.disableLessonSwipe {
                injectScript("noswipe")
            }
            if ApplicationSettings.userScriptHideMnemonicsEnabled {
                injectScript("wkhidem.user")
            }
            if ApplicationSettings.userScriptReorderUltimateEnabled {
                injectScript("WKU.user")
            }
            return true
        case WaniKaniURLs.reviewSession:
            DDLogDebug("Loading user scripts")
            injectScript("common")
            injectStyleSheet("resize")
            if ApplicationSettings.userScriptJitaiEnabled {
                injectScript("jitai.user")
            }
            if ApplicationSettings.userScriptIgnoreAnswerEnabled {
                injectScript("wkoverride.user")
            }
            if ApplicationSettings.userScriptDoubleCheckEnabled {
                injectScript("wkdoublecheck")
            }
            if ApplicationSettings.userScriptWaniKaniImproveEnabled {
                injectStyleSheet("jquery.qtip.min")
                injectScript("jquery.qtip.min")
                injectScript("wkimprove")
            }
            if ApplicationSettings.userScriptMarkdownNotesEnabled {
                injectScript("showdown.min")
                injectScript("markdown.user")
            }
            if ApplicationSettings.userScriptHideMnemonicsEnabled {
                injectScript("wkhidem.user")
            }
            if ApplicationSettings.userScriptReorderUltimateEnabled {
                injectScript("WKU.user")
            }
            return true
        case _ where URL.path!.hasPrefix(WaniKaniURLs.levelRoot.path!) || URL.path!.hasPrefix(WaniKaniURLs.radicalRoot.path!) || URL.path!.hasPrefix(WaniKaniURLs.kanjiRoot.path!) || URL.path!.hasPrefix(WaniKaniURLs.vocabularyRoot.path!):
            if ApplicationSettings.userScriptMarkdownNotesEnabled {
                injectScript("showdown.min")
                injectScript("markdown.user")
            }
            if ApplicationSettings.userScriptHideMnemonicsEnabled {
                injectScript("wkhidem.user")
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
        let contents = loadBundleResource(name, withExtension: "css", javascriptEncode: true)
        
        let script = "var style = document.createElement('style');style.setAttribute('type', 'text/css');style.appendChild(document.createTextNode('\(contents)'));document.head.appendChild(document.createComment('\(name).css'));document.head.appendChild(style);"
        
        if webView.stringByEvaluatingJavaScriptFromString(script) == nil {
            DDLogError("Failed to add style sheet \(name).css")
        }
    }
    
    func injectScript(name: String) {
        guard let webView = self.webView else { return }
        
        DDLogDebug("Loading script \(name).js")
        let contents = loadBundleResource(name, withExtension: "js", javascriptEncode: true)
        
        let script = "var script = document.createElement('script');script.setAttribute('type', 'text/javascript');script.appendChild(document.createTextNode('\(contents)'));document.head.appendChild(document.createComment('\(name).js'));document.head.appendChild(script);"
        if webView.stringByEvaluatingJavaScriptFromString(script) == nil {
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
        let cssContents = loadBundleResource(name, withExtension: "css", javascriptEncode: true)
        let contents = "var style = document.createElement('style');style.setAttribute('type', 'text/css');style.appendChild(document.createTextNode('\(cssContents)'));document.head.appendChild(document.createComment('\(name).css'));document.head.appendChild(style);"
        let script = WKUserScript(source: contents, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
        
        webView.configuration.userContentController.addUserScript(script)
    }
    
    func injectScript(name: String) {
        DDLogDebug("Loading script \(name).js")
        let contents = loadBundleResource(name, withExtension: "js", javascriptEncode: false)
        let script = WKUserScript(source: contents, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
        
        webView.configuration.userContentController.addUserScript(script)
    }
}