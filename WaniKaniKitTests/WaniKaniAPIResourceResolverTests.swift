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
        let expected = NSURL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/user-information")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(forAPIKey: apiKey)
        let url = resourceResolver.URLForResource(.UserInformation, withArgument: nil)
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testStudyQueue() {
        let expected = NSURL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/study-queue")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(forAPIKey: apiKey)
        let url = resourceResolver.URLForResource(.StudyQueue, withArgument: nil)
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testLevelProgression() {
        let expected = NSURL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/level-progression")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(forAPIKey: apiKey)
        let url = resourceResolver.URLForResource(.LevelProgression, withArgument: nil)
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testSRSDistribution() {
        let expected = NSURL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/srs-distribution")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(forAPIKey: apiKey)
        let url = resourceResolver.URLForResource(.SRSDistribution, withArgument: nil)
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testRadicalsWithoutArgument() {
        let expected = NSURL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/radicals")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(forAPIKey: apiKey)
        let url = resourceResolver.URLForResource(.Radicals, withArgument: nil)
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testRadicalsWithBlankArgument() {
        let expected = NSURL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/radicals")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(forAPIKey: apiKey)
        let url = resourceResolver.URLForResource(.Radicals, withArgument: "")
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testRadicalsWithArgument() {
        let expected = NSURL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/radicals/1")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(forAPIKey: apiKey)
        let url = resourceResolver.URLForResource(.Radicals, withArgument: "1")
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testKanjiWithoutArgument() {
        let expected = NSURL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/kanji")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(forAPIKey: apiKey)
        let url = resourceResolver.URLForResource(.Kanji, withArgument: nil)
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testKanjiWithBlankArgument() {
        let expected = NSURL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/kanji")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(forAPIKey: apiKey)
        let url = resourceResolver.URLForResource(.Kanji, withArgument: "")
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testKanjiWithArgument() {
        let expected = NSURL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/kanji/5")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(forAPIKey: apiKey)
        let url = resourceResolver.URLForResource(.Kanji, withArgument: "5")
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testVocabularyWithoutArgument() {
        let expected = NSURL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/vocabulary")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(forAPIKey: apiKey)
        let url = resourceResolver.URLForResource(.Vocabulary, withArgument: nil)
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testVocabularyWithBlankArgument() {
        let expected = NSURL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/vocabulary")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(forAPIKey: apiKey)
        let url = resourceResolver.URLForResource(.Vocabulary, withArgument: "")
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
    
    func testVocabularyWithArgument() {
        let expected = NSURL(string: "https://www.wanikani.com/api/\(apiVersion)/user/\(apiKey)/vocabulary/1,5,7")
        XCTAssertNotNil(expected)
        
        let resourceResolver = WaniKaniAPIResourceResolver(forAPIKey: apiKey)
        let url = resourceResolver.URLForResource(.Vocabulary, withArgument: "1,5,7")
        
        XCTAssertEqual(url.absoluteString, expected!.absoluteString)
    }
}
