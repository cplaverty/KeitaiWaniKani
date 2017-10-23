//
//  KanjiTests.swift
//  WaniKaniKitTests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import XCTest
@testable import WaniKaniKit

class KanjiTests: XCTestCase {
    
    func testDecode() {
        let data = """
            {"id":440,"object":"kanji","url":"https://www.wanikani.com/api/v2/subjects/440","data_updated_at":"2017-07-14T01:06:47.000000Z","data":{"level":1,"created_at":"2012-02-27T19:55:19.000000Z","slug":"一","document_url":"https://www.wanikani.com/kanji/%E4%B8%80","character":"一","meanings":[{"meaning":"One","primary":true}],"readings":[{"type":"Onyomi","primary":true,"reading":"いち"},{"type":"Kunyomi","primary":false,"reading":"ひと"},{"type":"Nanori","primary":false,"reading":"かず"}],"component_subject_ids":[1]}}
            """.data(using: .utf8)!
        
        let decoder = WaniKaniResourceDecoder()
        
        do {
            let resource = try decoder.decode(ResourceCollectionItem.self, from: data)
            
            let expected = ResourceCollectionItem(id: 440,
                                                  type: .kanji,
                                                  url: URL(string: "https://www.wanikani.com/api/v2/subjects/440")!,
                                                  dataUpdatedAt: makeUTCDate(year: 2017, month: 7, day: 14, hour: 1, minute: 6, second: 47),
                                                  data: Kanji(level: 1,
                                                              createdAt: makeUTCDate(year: 2012, month: 2, day: 27, hour: 19, minute: 55, second: 19),
                                                              slug: "一",
                                                              character: "一",
                                                              meanings: [Meaning(meaning: "One", isPrimary: true)],
                                                              readings: [Reading(type: "Onyomi", reading: "いち", isPrimary: true),
                                                                         Reading(type: "Kunyomi", reading: "ひと", isPrimary: false),
                                                                         Reading(type: "Nanori", reading: "かず", isPrimary: false)],
                                                              componentSubjectIDs: [1],
                                                              documentURL: URL(string: "https://www.wanikani.com/kanji/%E4%B8%80")!))
            
            XCTAssertEqual(resource, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
