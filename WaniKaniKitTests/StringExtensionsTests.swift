//
//  StringExtensionsTests.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest

class StringExtensionsTests: XCTestCase {
    
    func testLevenshteinDistance() {
        let distance = "rosettacode".levenshteinDistance(to: "raisethysword")
        
        XCTAssertEqual(distance, 8)
    }
    
    func testLevenshteinDistanceEmptyToEmpty() {
        let distance = "".levenshteinDistance(to: "")
        
        XCTAssertEqual(distance, 0)
    }
    
    func testLevenshteinDistanceToEmpty() {
        let distance = "fjkslfjsaiounfjdasoiga".levenshteinDistance(to: "")
        
        XCTAssertEqual(distance, 22)
    }
    
    func testLevenshteinDistanceFromEmpty() {
        let distance = "".levenshteinDistance(to: "fjkslfjsaiounfjdasoiga")
        
        XCTAssertEqual(distance, 22)
    }
    
    func testLevenshteinDistanceSame() {
        let distance = "fjkslfjsaiounfjdasoiga".levenshteinDistance(to: "fjkslfjsaiounfjdasoiga")
        
        XCTAssertEqual(distance, 0)
    }
    
    func testLevenshteinDistanceInsert() {
        let distance = "fjkslfjsaiounfjdasoiga".levenshteinDistance(to: "fjkslfjsaioudnfjdasodiga")
        
        XCTAssertEqual(distance, 2)
    }
    
    func testLevenshteinDistanceDelete() {
        let distance = "fjkslfjsaiounfjdasoiga".levenshteinDistance(to: "fjsfjsaiounfjdasiga")
        
        XCTAssertEqual(distance, 3)
    }
    
    func testLevenshteinDistanceSubstitute() {
        let distance = "fjkslfjsaiounfjdasoiga".levenshteinDistance(to: "fjkslfjbaiounfjqasoiga")
        
        XCTAssertEqual(distance, 2)
    }
    
    func testLevenshteinDistanceAppend() {
        let distance = "fjkslfjsaiounfjdasoiga".levenshteinDistance(to: "fjkslfjsaiounfjdasoigalde")
        
        XCTAssertEqual(distance, 3)
    }
    
    func testLevenshteinDistancePrepend() {
        let distance = "fjkslfjsaiounfjdasoiga".levenshteinDistance(to: "effjkslfjsaiounfjdasoiga")
        
        XCTAssertEqual(distance, 2)
    }
    
    func testLevenshteinDistanceTotalReplacement() {
        let distance = "abcdefghijklm".levenshteinDistance(to: "nopqrstuvwxyz")
        
        XCTAssertEqual(distance, 13)
    }
    
}
