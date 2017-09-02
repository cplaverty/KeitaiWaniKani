//
//  SupportsUserScripts.swift
//  AlliCrab
//
//  Copyright © 2016 Chris Laverty. All rights reserved.
//

import os
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
        if #available(iOS 10.0, *) {
            os_log("Loading user scripts for %@", type: .info, url as NSURL)
        }
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

// MARK: - WKWebView

protocol WebViewUserScriptSupport: UserScriptSupport, BundleResourceLoader {
    var webView: WKWebView! { get }
}

extension WebViewUserScriptSupport {
    func injectStyleSheet(name: String) {
        if #available(iOS 10.0, *) {
            os_log("Loading stylesheet %@", type: .debug, name + ".css")
        }
        let contents = loadBundleResource(name: name, withExtension: "css", javascriptEncode: true)
        injectStyleSheet(title: "\(name).css", contents: contents)
    }
    
    func injectScript(name: String) {
        if #available(iOS 10.0, *) {
            os_log("Loading script %@", type: .debug, name + ".js")
        }
        let source = loadBundleResource(name: name, withExtension: "js", javascriptEncode: false)
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        webView.configuration.userContentController.addUserScript(script)
    }
    
    func injectBundledFontReferences() {
        for (fontFamily, font) in fonts {
            guard let path = Bundle.main.path(forResource: font, ofType: nil), let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
                continue
            }
            
            let isOpenType = font.hasSuffix("otf")
            let mimeType = isOpenType ? "font/otf" : "font/ttf"
            let fontFormat = isOpenType ? "opentype" : "truetype"
            
            if #available(iOS 10.0, *) {
                os_log("Adding %@", type: .debug, fontFamily)
            }
            let source = "@font-face { font-family: \"\(fontFamily)\"; src: url(data:\(mimeType);base64,\(data.base64EncodedString())) format(\"\(fontFormat)\"); }"
            
            injectStyleSheet(title: "font: \(fontFamily)", contents: source)
        }
    }
    
    private func injectStyleSheet(title: String, contents: String) {
        let source = """
        var style = document.createElement('style');
        style.setAttribute('type', 'text/css');
        style.appendChild(document.createTextNode('\(contents)'));
        document.head.appendChild(document.createComment('\(title)'));
        document.head.appendChild(style);
        """
        
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        webView.configuration.userContentController.addUserScript(script)
    }
}
