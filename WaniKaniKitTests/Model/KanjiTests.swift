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
        let data = #"""
            {"id":440,"object":"kanji","url":"https://api.wanikani.com/v2/subjects/440","data_updated_at":"2019-02-07T00:28:35.000000Z","data":{"created_at":"2012-02-27T19:55:19.000000Z","level":1,"slug":"一","hidden_at":null,"document_url":"https://www.wanikani.com/kanji/%E4%B8%80","characters":"一","meanings":[{"meaning":"One","primary":true,"accepted_answer":true}],"auxiliary_meanings":[{"type":"whitelist","meaning":"1"}],"readings":[{"type":"onyomi","primary":true,"reading":"いち","accepted_answer":true},{"type":"kunyomi","primary":false,"reading":"ひと","accepted_answer":false},{"type":"nanori","primary":false,"reading":"かず","accepted_answer":false},{"type":"onyomi","primary":true,"reading":"いつ","accepted_answer":true}],"component_subject_ids":[1],"amalgamation_subject_ids":[2467,2468,2477,2510,2544,2588,2627,2660,2665,2672,2679,2721,2730,2751,2959,3048,3256,3335,3348,3349,3372,3481,3527,3528,3656,3663,4133,4173,4258,4282,4563,4615,4701,4823,4906,5050,5224,5237,5349,5362,5838,6010,6029,6150,6169,6209,6210,6346,6584,6614,6723,6811,6851,7037,7293,7305,7451,7561,7617,7734,7780,7927,8209,8214,8414,8456,8583,8709],"visually_similar_subject_ids":[],"meaning_mnemonic":"Lying on the \u003cradical\u003eground\u003c/radical\u003e is something that looks just like the ground, the number \u003ckanji\u003eOne\u003c/kanji\u003e. Why is this One lying down? It's been shot by the number two. It's lying there, bleeding out and dying. The number One doesn't have long to live.","meaning_hint":"To remember the meaning of \u003ckanji\u003eOne\u003c/kanji\u003e, imagine yourself there at the scene of the crime. You grab \u003ckanji\u003eOne\u003c/kanji\u003e in your arms, trying to prop it up, trying to hear its last words. Instead, it just splatters some blood on your face. \"Who did this to you?\" you ask. The number One points weakly, and you see number Two running off into an alleyway. He's always been jealous of number One and knows he can be number one now that he's taken the real number one out.","reading_mnemonic":"As you're sitting there next to \u003ckanji\u003eOne\u003c/kanji\u003e, holding him up, you start feeling a weird sensation all over your skin. From the wound comes a fine powder (obviously coming from the special bullet used to kill One) that causes the person it touches to get extremely \u003creading\u003eitchy\u003c/reading\u003e (\u003cja\u003eいち\u003c/ja\u003e).","reading_hint":"Make sure you feel the ridiculously \u003creading\u003eitchy\u003c/reading\u003e sensation covering your body. It climbs from your hands, where you're holding the number \u003ckanji\u003eOne\u003c/kanji\u003e up, and then goes through your arms, crawls up your neck, goes down your body, and then covers everything. It becomes uncontrollable, and you're scratching everywhere, writhing on the ground. It's so itchy that it's the most painful thing you've ever experienced (you should imagine this vividly, so you remember the reading of this kanji).","lesson_position":26}}
            """#.data(using: .utf8)!
        
        let decoder = WaniKaniResourceDecoder()
        
        do {
            let resource = try decoder.decode(ResourceCollectionItem.self, from: data)
            
            let expected = ResourceCollectionItem(id: 440,
                                                  type: .kanji,
                                                  url: URL(string: "https://api.wanikani.com/v2/subjects/440")!,
                                                  dataUpdatedAt: makeUTCDate(year: 2019, month: 2, day: 7, hour: 0, minute: 28, second: 35),
                                                  data: Kanji(createdAt: makeUTCDate(year: 2012, month: 2, day: 27, hour: 19, minute: 55, second: 19),
                                                              level: 1,
                                                              slug: "一",
                                                              hiddenAt: nil,
                                                              documentURL: URL(string: "https://www.wanikani.com/kanji/%E4%B8%80")!,
                                                              characters: "一",
                                                              meanings: [Meaning(meaning: "One", isPrimary: true, isAcceptedAnswer: true)],
                                                              auxiliaryMeanings: [AuxiliaryMeaning(type: "whitelist", meaning: "1")],
                                                              readings: [
                                                                Reading(type: .onyomi, reading: "いち", isPrimary: true, isAcceptedAnswer: true),
                                                                Reading(type: .kunyomi, reading: "ひと", isPrimary: false, isAcceptedAnswer: false),
                                                                Reading(type: .nanori, reading: "かず", isPrimary: false, isAcceptedAnswer: false),
                                                                Reading(type: .onyomi, reading: "いつ", isPrimary: true, isAcceptedAnswer: true),
                                                                ],
                                                              componentSubjectIDs: [1],
                                                              amalgamationSubjectIDs: [2467, 2468, 2477, 2510, 2544, 2588, 2627, 2660, 2665, 2672, 2679, 2721, 2730, 2751, 2959, 3048, 3256, 3335, 3348, 3349, 3372, 3481, 3527, 3528, 3656, 3663, 4133, 4173, 4258, 4282, 4563, 4615, 4701, 4823, 4906, 5050, 5224, 5237, 5349, 5362, 5838, 6010, 6029, 6150, 6169, 6209, 6210, 6346, 6584, 6614, 6723, 6811, 6851, 7037, 7293, 7305, 7451, 7561, 7617, 7734, 7780, 7927, 8209, 8214, 8414, 8456, 8583, 8709],
                                                              visuallySimilarSubjectIDs: [],
                                                              meaningMnemonic: "Lying on the <radical>ground</radical> is something that looks just like the ground, the number <kanji>One</kanji>. Why is this One lying down? It's been shot by the number two. It's lying there, bleeding out and dying. The number One doesn't have long to live.",
                                                              meaningHint: #"To remember the meaning of <kanji>One</kanji>, imagine yourself there at the scene of the crime. You grab <kanji>One</kanji> in your arms, trying to prop it up, trying to hear its last words. Instead, it just splatters some blood on your face. "Who did this to you?" you ask. The number One points weakly, and you see number Two running off into an alleyway. He's always been jealous of number One and knows he can be number one now that he's taken the real number one out."#,
                                                              readingMnemonic: "As you're sitting there next to <kanji>One</kanji>, holding him up, you start feeling a weird sensation all over your skin. From the wound comes a fine powder (obviously coming from the special bullet used to kill One) that causes the person it touches to get extremely <reading>itchy</reading> (<ja>いち</ja>).",
                                                              readingHint: "Make sure you feel the ridiculously <reading>itchy</reading> sensation covering your body. It climbs from your hands, where you're holding the number <kanji>One</kanji> up, and then goes through your arms, crawls up your neck, goes down your body, and then covers everything. It becomes uncontrollable, and you're scratching everywhere, writhing on the ground. It's so itchy that it's the most painful thing you've ever experienced (you should imagine this vividly, so you remember the reading of this kanji).",
                                                              lessonPosition: 26))
            
            XCTAssertEqual(resource, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
