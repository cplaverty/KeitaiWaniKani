//
//  NSAttributedStringTests.swift
//  WaniKaniKitTests
//
//  Copyright © 2019 Chris Laverty. All rights reserved.
//

import XCTest
@testable import WaniKaniKit

class NSAttributedStringTests: XCTestCase {
    
    func testSimple() {
        let content = "This is a simple string with no tags"
        let expected = NSAttributedString(string: content)
        
        let actual = NSAttributedString(wkMarkup: content, attributesForTag: attributes(for:))
        
        XCTAssertEqual(actual, expected)
    }
    
    func testTagAtStart() {
        let content = "<white>White</white> tag at start of string"
        let expected = NSMutableAttributedString(string: "White tag at start of string")
        expected.addAttribute(.backgroundColor, value: UIColor.white, range: NSRange(location: 0, length: 5))
        
        let actual = NSAttributedString(wkMarkup: content, attributesForTag: attributes(for:))
        
        XCTAssertEqual(actual, expected)
    }
    
    func testTagAtEnd() {
        let content = "Ends with tag <white>white</white>"
        let expected = NSMutableAttributedString(string: "Ends with tag white")
        expected.addAttribute(.backgroundColor, value: UIColor.white, range: NSRange(location: expected.length - 5, length: 5))
        
        let actual = NSAttributedString(wkMarkup: content, attributesForTag: attributes(for:))
        
        XCTAssertEqual(actual, expected)
    }

    func testTagInMiddle() {
        let content = "This is a simple string with a <black>black</black> tag"
        let expected = NSMutableAttributedString(string: "This is a simple string with a black tag")
        expected.addAttribute(.backgroundColor, value: UIColor.black, range: NSRange(location: 31, length: 5))
        
        let actual = NSAttributedString(wkMarkup: content, attributesForTag: attributes(for:))
        
        XCTAssertEqual(actual, expected)
    }
    
    func testMultipleTags() {
        let content = "Multiple tags like <black>black</black> and <white>white</white>"
        let expected = NSMutableAttributedString(string: "Multiple tags like black and white")
        expected.addAttribute(.backgroundColor, value: UIColor.black, range: NSRange(location: 19, length: 5))
        expected.addAttribute(.backgroundColor, value: UIColor.white, range: NSRange(location: 29, length: 5))
        
        let actual = NSAttributedString(wkMarkup: content, attributesForTag: attributes(for:))
        
        XCTAssertEqual(actual, expected)
    }

    func testNestedTag() {
        let content = "This text should be <black><whitetext>white on black</whitetext></black>"
        let expected = NSMutableAttributedString(string: "This text should be white on black")
        expected.addAttribute(.backgroundColor, value: UIColor.black, range: NSRange(location: 20, length: 14))
        expected.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 20, length: 14))

        let actual = NSAttributedString(wkMarkup: content, attributesForTag: attributes(for:))
        
        XCTAssertEqual(actual, expected)
    }

    private func attributes(for tag: String) -> [NSAttributedString.Key: Any]? {
        switch tag {
        case "white":
            return [
                .backgroundColor: UIColor.white,
            ]
        case "black":
            return [
                .backgroundColor: UIColor.black,
            ]
        case "whitetext":
            return [
                .foregroundColor: UIColor.white,
            ]
        default:
            return nil
        }
    }
}
