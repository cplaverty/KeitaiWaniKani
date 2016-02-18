//
//  BundleResourceLoader.swift
//  KeitaiWaniKani
//
//  Copyright © 2016 Chris Laverty. All rights reserved.
//

import Foundation

protocol BundleResourceLoader {
    func loadBundleResource(name: String, withExtension: String, javascriptEncode: Bool) -> String
}

extension BundleResourceLoader {
    func loadBundleResource(name: String, withExtension: String, javascriptEncode: Bool) -> String {
        guard let scriptURL = NSBundle.mainBundle().URLForResource(name, withExtension: withExtension) else {
            fatalError("Count not find resource \(name).\(withExtension) in main bundle")
        }
        
        let contents = try! String(contentsOfURL: scriptURL)
        return javascriptEncode ? encodeForJavascript(contents) : contents
    }
    
    private func encodeForJavascript(string: String) -> String {
        return string.unicodeScalars.map { $0.escape(asASCII: false) }.joinWithSeparator("")
    }
}
