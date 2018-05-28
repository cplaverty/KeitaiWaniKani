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
            {"id":440,"object":"kanji","url":"https://api.wanikani.com/v2/subjects/440","data_updated_at":"2018-05-21T21:51:46.000000Z","data":{"created_at":"2012-02-27T19:55:19.000000Z","level":1,"slug":"一","hidden_at":null,"document_url":"https://www.wanikani.com/kanji/%E4%B8%80","characters":"一","meanings":[{"meaning":"One","primary":true,"accepted_answer":true}],"readings":[{"type":"onyomi","primary":true,"reading":"いち","accepted_answer":true},{"type":"kunyomi","primary":false,"reading":"ひと","accepted_answer":false},{"type":"nanori","primary":false,"reading":"かず","accepted_answer":false}],"component_subject_ids":[1],"amalgamation_subject_ids":[2467,2468,2477,2510,2544,2588,2627,2660,2665,2672,2679,2721,2730,2751,2959,3048,3256,3335,3348,3349,3372,3481,3527,3528,3656,3663,4133,4173,4258,4282,4563,4615,4701,4823,4906,5050,5224,5237,5349,5362,5838,6010,6029,6150,6169,6209,6210,6346,6584,6614,6723,6811,6851,7037,7293,7305,7451,7561,7617,7734,7780,7927,8209,8214,8414,8456,8583,8709]}}
            """.data(using: .utf8)!
        
        let decoder = WaniKaniResourceDecoder()
        
        do {
            let resource = try decoder.decode(ResourceCollectionItem.self, from: data)
            
            let expected = ResourceCollectionItem(id: 440,
                                                  type: .kanji,
                                                  url: URL(string: "https://api.wanikani.com/v2/subjects/440")!,
                                                  dataUpdatedAt: makeUTCDate(year: 2018, month: 5, day: 21, hour: 21, minute: 51, second: 46),
                                                  data: Kanji(level: 1,
                                                              createdAt: makeUTCDate(year: 2012, month: 2, day: 27, hour: 19, minute: 55, second: 19),
                                                              slug: "一",
                                                              characters: "一",
                                                              meanings: [Meaning(meaning: "One", isPrimary: true, isAcceptedAnswer: true)],
                                                              readings: [
                                                                Reading(type: "onyomi", reading: "いち", isPrimary: true, isAcceptedAnswer: true),
                                                                Reading(type: "kunyomi", reading: "ひと", isPrimary: false, isAcceptedAnswer: false),
                                                                Reading(type: "nanori", reading: "かず", isPrimary: false, isAcceptedAnswer: false),
                                                                ],
                                                              componentSubjectIDs: [1],
                                                              amalgamationSubjectIDs: [2467,2468,2477,2510,2544,2588,2627,2660,2665,2672,2679,2721,2730,2751,2959,3048,3256,3335,3348,3349,3372,3481,3527,3528,3656,3663,4133,4173,4258,4282,4563,4615,4701,4823,4906,5050,5224,5237,5349,5362,5838,6010,6029,6150,6169,6209,6210,6346,6584,6614,6723,6811,6851,7037,7293,7305,7451,7561,7617,7734,7780,7927,8209,8214,8414,8456,8583,8709],
                                                              documentURL: URL(string: "https://www.wanikani.com/kanji/%E4%B8%80")!,
                                                              hiddenAt: nil))
            
            XCTAssertEqual(resource, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
