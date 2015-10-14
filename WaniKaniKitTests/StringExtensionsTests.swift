//
//  StringExtensionsTests.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest

class StringExtensionsTests: XCTestCase {
    
    func testLevenshteinDistance() {
        let distance = "rosettacode".levenshteinDistanceToString("raisethysword")
        
        XCTAssertEqual(distance, 8)
    }
    
    func testLevenshteinDistanceEmptyToEmpty() {
        let distance = "".levenshteinDistanceToString("")
        
        XCTAssertEqual(distance, 0)
    }
    
    func testLevenshteinDistanceToEmpty() {
        let distance = "fjkslfjsaiounfjdasoiga".levenshteinDistanceToString("")
        
        XCTAssertEqual(distance, 22)
    }
    
    func testLevenshteinDistanceFromEmpty() {
        let distance = "".levenshteinDistanceToString("fjkslfjsaiounfjdasoiga")
        
        XCTAssertEqual(distance, 22)
    }
    
    func testLevenshteinDistanceSame() {
        let distance = "fjkslfjsaiounfjdasoiga".levenshteinDistanceToString("fjkslfjsaiounfjdasoiga")
        
        XCTAssertEqual(distance, 0)
    }
    
    func testLevenshteinDistanceInsert() {
        let distance = "fjkslfjsaiounfjdasoiga".levenshteinDistanceToString("fjkslfjsaioudnfjdasodiga")
        
        XCTAssertEqual(distance, 2)
    }
    
    func testLevenshteinDistanceDelete() {
        let distance = "fjkslfjsaiounfjdasoiga".levenshteinDistanceToString("fjsfjsaiounfjdasiga")
        
        XCTAssertEqual(distance, 3)
    }
    
    func testLevenshteinDistanceSubstitute() {
        let distance = "fjkslfjsaiounfjdasoiga".levenshteinDistanceToString("fjkslfjbaiounfjqasoiga")
        
        XCTAssertEqual(distance, 2)
    }
    
    func testLevenshteinDistanceAppend() {
        let distance = "fjkslfjsaiounfjdasoiga".levenshteinDistanceToString("fjkslfjsaiounfjdasoigalde")
        
        XCTAssertEqual(distance, 3)
    }
    
    func testLevenshteinDistancePrepend() {
        let distance = "fjkslfjsaiounfjdasoiga".levenshteinDistanceToString("effjkslfjsaiounfjdasoiga")
        
        XCTAssertEqual(distance, 2)
    }
    
    func testLevenshteinDistanceTotalReplacement() {
        let distance = "abcdefghijklm".levenshteinDistanceToString("nopqrstuvwxyz")
        
        XCTAssertEqual(distance, 13)
    }
    
}
