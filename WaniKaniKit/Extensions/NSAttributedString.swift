//
//  NSAttributedString.swift
//  WaniKaniKit
//
//  Copyright © 2019 Chris Laverty. All rights reserved.
//

import Foundation

private let regex = try! NSRegularExpression(pattern: #"<([^>]+)>(.+?)</\1>"#, options: [.dotMatchesLineSeparators])

public extension NSAttributedString {
    convenience init(wkMarkup s: String, jpFont: UIFont? = nil, attributes attrs: [NSAttributedString.Key : Any]? = nil) {
        self.init(wkMarkup: s, attributes: attrs) { tag in
            switch tag.lowercased() {
            case "radical":
                return [
                    .backgroundColor: UIColor.waniKaniRadical,
                    .foregroundColor: UIColor.white,
                ]
            case "kanji":
                return [
                    .backgroundColor: UIColor.waniKaniKanji,
                    .foregroundColor: UIColor.white,
                ]
            case "vocabulary":
                return [
                    .backgroundColor: UIColor.waniKaniVocabulary,
                    .foregroundColor: UIColor.white,
                ]
            case "meaning", "reading":
                return [
                    .backgroundColor: UIColor.black,
                    .foregroundColor: UIColor.white,
                ]
            case "ja":
                guard let jpFont = jpFont else {
                    return nil
                }
                
                return [
                    .font: jpFont,
                ]
            default:
                return nil
            }
        }
    }
    
    internal convenience init(wkMarkup str: String, attributes attrs: [NSAttributedString.Key : Any]? = nil, attributesForTag: (String) -> [NSAttributedString.Key: Any]?) {
        let attributedString = NSMutableAttributedString(string: str, attributes: attrs)
        let matches = regex.matches(in: str, options: [], range: NSRange(str.startIndex..<str.endIndex, in: str))
        
        for match in matches.reversed() {
            let tag = String(str[Range(match.range(at: 1), in: str)!])
            let content = String(str[Range(match.range(at: 2), in: str)!])
            
            let mergedAttrs: [NSAttributedString.Key : Any]?
            if let tagAttributes = attributesForTag(tag) {
                if let attrs = attrs {
                    mergedAttrs = tagAttributes.merging(attrs, uniquingKeysWith: { (first, _) in first })
                } else {
                    mergedAttrs = tagAttributes
                }
            } else {
                mergedAttrs = attrs
            }
            
            let attributedContent = NSAttributedString(wkMarkup: content, attributes: mergedAttrs, attributesForTag: attributesForTag)
            attributedString.replaceCharacters(in: match.range, with: attributedContent)
        }
        
        self.init(attributedString: attributedString)
    }
}
