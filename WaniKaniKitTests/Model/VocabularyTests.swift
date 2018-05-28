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
            {"id":2467,"object":"vocabulary","url":"https://api.wanikani.com/v2/subjects/2467","data_updated_at":"2018-05-21T21:52:43.000000Z","data":{"created_at":"2012-02-28T08:04:47.000000Z","level":1,"slug":"一","hidden_at":null,"document_url":"https://www.wanikani.com/vocabulary/%E4%B8%80","characters":"一","meanings":[{"meaning":"One","primary":true,"accepted_answer":true}],"readings":[{"primary":true,"reading":"いち","accepted_answer":true}],"parts_of_speech":["numeral"],"component_subject_ids":[440]}}
            """.data(using: .utf8)!
        
        let decoder = WaniKaniResourceDecoder()
        
        do {
            let resource = try decoder.decode(ResourceCollectionItem.self, from: data)
            
            let expected = ResourceCollectionItem(id: 2467,
                                                  type: .vocabulary,
                                                  url: URL(string: "https://api.wanikani.com/v2/subjects/2467")!,
                                                  dataUpdatedAt: makeUTCDate(year: 2018, month: 5, day: 21, hour: 21, minute: 52, second: 43),
                                                  data: Vocabulary(level: 1,
                                                                   createdAt: makeUTCDate(year: 2012, month: 2, day: 28, hour: 8, minute: 4, second: 47),
                                                                   slug: "一",
                                                                   characters: "一",
                                                                   meanings: [Meaning(meaning: "One", isPrimary: true, isAcceptedAnswer: true)],
                                                                   readings: [Reading(reading: "いち", isPrimary: true, isAcceptedAnswer: true)],
                                                                   partsOfSpeech: ["numeral"],
                                                                   componentSubjectIDs: [440],
                                                                   documentURL: URL(string: "https://www.wanikani.com/vocabulary/%E4%B8%80")!,
                                                                   hiddenAt: nil))
            
            XCTAssertEqual(resource, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
