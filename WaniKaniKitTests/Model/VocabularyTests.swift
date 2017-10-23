//
//  VocabularyTests.swift
//  WaniKaniKitTests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import XCTest
@testable import WaniKaniKit

class VocabularyTests: XCTestCase {
    
    func testDecode() {
        let data = """
            {"id":2467,"object":"vocabulary","url":"https://www.wanikani.com/api/v2/subjects/2467","data_updated_at":"2017-07-14T01:11:03.000000Z","data":{"level":1,"created_at":"2012-02-28T08:04:47.000000Z","slug":"一","document_url":"https://www.wanikani.com/vocabulary/%E4%B8%80","characters":"一","meanings":[{"meaning":"One","primary":true}],"readings":[{"primary":true,"reading":"いち"}],"parts_of_speech":["numeral"],"component_subject_ids":[440]}}
            """.data(using: .utf8)!
        
        let decoder = WaniKaniResourceDecoder()
        
        do {
            let resource = try decoder.decode(ResourceCollectionItem.self, from: data)
            
            let expected = ResourceCollectionItem(id: 2467,
                                                  type: .vocabulary,
                                                  url: URL(string: "https://www.wanikani.com/api/v2/subjects/2467")!,
                                                  dataUpdatedAt: makeUTCDate(year: 2017, month: 7, day: 14, hour: 1, minute: 11, second: 3),
                                                  data: Vocabulary(level: 1,
                                                                   createdAt: makeUTCDate(year: 2012, month: 2, day: 28, hour: 8, minute: 4, second: 47),
                                                                   slug: "一",
                                                                   characters: "一",
                                                                   meanings: [Meaning(meaning: "One", isPrimary: true)],
                                                                   readings: [Reading(reading: "いち", isPrimary: true)],
                                                                   partsOfSpeech: ["numeral"],
                                                                   componentSubjectIDs: [440],
                                                                   documentURL: URL(string: "https://www.wanikani.com/vocabulary/%E4%B8%80")!))
            
            XCTAssertEqual(resource, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
