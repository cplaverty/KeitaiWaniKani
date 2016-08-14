//
//  WaniKaniAPIResourceResolverTests.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
@testable import WaniKaniKit

class WaniKaniAPIResourceResolverTests: XCTestCase {
    let apiVersion = "v1.4"
    let apiKey = "TEST_API_KEY"
    
    func testUserInformation() {
        let expected = URL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/user-information")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(apiKey: apiKey)
        let url = resourceResolver.resolveURL(resource: .userInformation, withArgument: nil)
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testStudyQueue() {
        let expected = URL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/study-queue")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(apiKey: apiKey)
        let url = resourceResolver.resolveURL(resource: .studyQueue, withArgument: nil)
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testLevelProgression() {
        let expected = URL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/level-progression")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(apiKey: apiKey)
        let url = resourceResolver.resolveURL(resource: .levelProgression, withArgument: nil)
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testSRSDistribution() {
        let expected = URL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/srs-distribution")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(apiKey: apiKey)
        let url = resourceResolver.resolveURL(resource: .srsDistribution, withArgument: nil)
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testRadicalsWithoutArgument() {
        let expected = URL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/radicals")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(apiKey: apiKey)
        let url = resourceResolver.resolveURL(resource: .radicals, withArgument: nil)
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testRadicalsWithBlankArgument() {
        let expected = URL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/radicals")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(apiKey: apiKey)
        let url = resourceResolver.resolveURL(resource: .radicals, withArgument: "")
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testRadicalsWithArgument() {
        let expected = URL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/radicals/1")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(apiKey: apiKey)
        let url = resourceResolver.resolveURL(resource: .radicals, withArgument: "1")
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testKanjiWithoutArgument() {
        let expected = URL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/kanji")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(apiKey: apiKey)
        let url = resourceResolver.resolveURL(resource: .kanji, withArgument: nil)
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testKanjiWithBlankArgument() {
        let expected = URL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/kanji")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(apiKey: apiKey)
        let url = resourceResolver.resolveURL(resource: .kanji, withArgument: "")
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testKanjiWithArgument() {
        let expected = URL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/kanji/5")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(apiKey: apiKey)
        let url = resourceResolver.resolveURL(resource: .kanji, withArgument: "5")
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testVocabularyWithoutArgument() {
        let expected = URL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/vocabulary")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(apiKey: apiKey)
        let url = resourceResolver.resolveURL(resource: .vocabulary, withArgument: nil)
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testVocabularyWithBlankArgument() {
        let expected = URL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/vocabulary")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(apiKey: apiKey)
        let url = resourceResolver.resolveURL(resource: .vocabulary, withArgument: "")
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testVocabularyWithArgument() {
        let expected = URL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/vocabulary/1,5,7")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(apiKey: apiKey)
        let url = resourceResolver.resolveURL(resource: .vocabulary, withArgument: "1,5,7")
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
}
