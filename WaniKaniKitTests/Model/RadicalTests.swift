//
//  RadicalTests.swift
//  WaniKaniKitTests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import XCTest
@testable import WaniKaniKit

class RadicalTests: XCTestCase {
    
    func testDecode() {
        let data = """
            {"id":1,"object":"radical","url":"https://www.wanikani.com/api/v2/subjects/1","data_updated_at":"2017-06-12T23:21:17.000000Z","data":{"level":1,"created_at":"2012-02-27T18:08:16.000000Z","slug":"ground","document_url":"https://www.wanikani.com/radicals/ground","character":"一","character_images":[],"meanings":[{"meaning":"Ground","primary":true}]}}
            """.data(using: .utf8)!
        
        let decoder = WaniKaniResourceDecoder()
        
        do {
            let resource = try decoder.decode(ResourceCollectionItem.self, from: data)
            
            let expected = ResourceCollectionItem(id: 1,
                                                  type: .radical,
                                                  url: URL(string: "https://www.wanikani.com/api/v2/subjects/1")!,
                                                  dataUpdatedAt: makeUTCDate(year: 2017, month: 6, day: 12, hour: 23, minute: 21, second: 17),
                                                  data: Radical(level: 1,
                                                                createdAt: makeUTCDate(year: 2012, month: 2, day: 27, hour: 18, minute: 8, second: 16),
                                                                slug: "ground",
                                                                character: "一",
                                                                characterImages: [],
                                                                meanings: [Meaning(meaning: "Ground", isPrimary: true)],
                                                                documentURL: URL(string: "https://www.wanikani.com/radicals/ground")!))
            
            XCTAssertEqual(resource, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
