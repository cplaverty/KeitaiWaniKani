//
//  SupportsUserScripts.swift
//  AlliCrab
//
//  Copyright © 2016 Chris Laverty. All rights reserved.
//

import CocoaLumberjack
import WebKit
import WaniKaniKit

protocol UserScriptSupport {
    func injectScript(name: String)
    func injectStyleSheet(name: String)
    func injectBundledFontReferences()
    
    func injectUserScripts(for: URL) -> Bool
}

extension UserScriptSupport {
    func injectUserScripts(for url: URL) -> Bool {
        DDLogDebug("Loading user scripts")
        var scriptsInjected = false
        var bundledFontReferencesInjected = false
        
        for script in UserScriptDefinitions.all where script.canBeInjected(toPageAt: url) {
            if script.requiresFonts && !bundledFontReferencesInjected {
                injectBundledFontReferences()
                bundledFontReferencesInjected = true
            }
            script.inject(into: self)
            scriptsInjected = true
        }
        
        return scriptsInjected
    }
}

private let fonts = [
    "ChihayaGothic": "chigfont.ttf",
    "cinecaption": "cinecaption2.28.ttf",
    "darts font": "dartsfont.ttf",
    "FC-Flower": "fc_fl.ttf",
    "HakusyuKaisyoExtraBold_kk": "hkgokukaikk.ttf",
    "Hosofuwafont": "Hosohuwafont.ttf",
    "Nchifont+": "n_chifont+.ttf",
    "santyoume-font": "santyoume.otf"
]

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
    
    func injectBundledFontReferences() {
        // Nothing to do for UIWebView since this is in-process
    }
}

// MARK: - WKWebView

protocol WKWebViewUserScriptSupport: UserScriptSupport, BundleResourceLoader {
    var webView: WKWebView! { get }
}

extension WKWebViewUserScriptSupport {
    func injectStyleSheet(name: String) {
        DDLogDebug("Loading stylesheet \(name).css")
        let contents = loadBundleResource(name: name, withExtension: "css", javascriptEncode: true)
        injectStyleSheet(title: "\(name).css", contents: contents)
    }
    
    func injectScript(name: String) {
        DDLogDebug("Loading script \(name).js")
        let source = loadBundleResource(name: name, withExtension: "js", javascriptEncode: false)
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        webView.configuration.userContentController.addUserScript(script)
    }
    
    func injectBundledFontReferences() {
        for (fontFamily, font) in fonts {
            if let path = Bundle.main.path(forResource: font, ofType: nil) {
                let isOpentype = font.hasSuffix("otf")
                let mimeType = isOpentype ? "font/opentype" : "font/ttf"
                let fontFormat = isOpentype ? "opentype" : "truetype"
                let url = URL(fileURLWithPath: path)
                if let data = try? Data(contentsOf: url) {
                    DDLogDebug("Adding \(fontFamily)...")
                    let source = "@font-face { font-family: \"\(fontFamily)\"; src: local(\"\(fontFamily)\") url(data:\(mimeType);base64,\(data.base64EncodedString())) format(\"\(fontFormat)\"); }"
                    injectStyleSheet(title: "font: \(fontFamily)", contents: source)
                }
            }
        }
    }
    
    private func injectStyleSheet(title: String, contents: String) {
        let source = "var style = document.createElement('style');style.setAttribute('type', 'text/css');style.appendChild(document.createTextNode('\(contents)'));document.head.appendChild(document.createComment('\(title)'));document.head.appendChild(style);"
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        webView.configuration.userContentController.addUserScript(script)
    }
}
