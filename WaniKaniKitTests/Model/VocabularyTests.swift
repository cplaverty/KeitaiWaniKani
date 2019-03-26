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
        let data = #"""
            {"id":2467,"object":"vocabulary","url":"https://api.wanikani.com/v2/subjects/2467","data_updated_at":"2019-02-07T00:28:35.000000Z","data":{"created_at":"2012-02-28T08:04:47.000000Z","level":1,"slug":"一","hidden_at":null,"document_url":"https://www.wanikani.com/vocabulary/%E4%B8%80","characters":"一","meanings":[{"meaning":"One","primary":true,"accepted_answer":true}],"auxiliary_meanings":[{"type":"whitelist","meaning":"1"}],"readings":[{"primary":true,"reading":"いち","accepted_answer":true}],"parts_of_speech":["numeral"],"component_subject_ids":[440],"meaning_mnemonic":"As is the case with most vocab words that consist of a single kanji, this vocab word has the same meaning as the kanji it parallels, which is \u003cvocabulary\u003eone\u003c/vocabulary\u003e.","reading_mnemonic":"When a vocab word is all alone and has no okurigana (hiragana attached to kanji) connected to it, it usually uses the kun'yomi reading. Numbers are an exception, however. When a number is all alone, with no kanji or okurigana, it is going to be the on'yomi reading, which you learned with the kanji.  Just remember this exception for alone numbers and you'll be able to read future number-related vocab to come.","context_sentences":[{"en":"Let’s meet up once.","ja":"一ど、あいましょう。"},{"en":"First place was an American.","ja":"一いはアメリカ人でした。"},{"en":"I’m the weakest man in the world.","ja":"ぼくはせかいで一ばんよわい。"}],"pronunciation_audios":[{"url":"https://cdn.wanikani.com/audios/3020-subject-2467.mp3?1547862356","metadata":{"gender":"male","source_id":2711,"pronunciation":"いち","voice_actor_id":2,"voice_actor_name":"Kenichi","voice_description":"Tokyo accent"},"content_type":"audio/mpeg"},{"url":"https://cdn.wanikani.com/audios/3018-subject-2467.ogg?1547862356","metadata":{"gender":"male","source_id":2711,"pronunciation":"いち","voice_actor_id":2,"voice_actor_name":"Kenichi","voice_description":"Tokyo accent"},"content_type":"audio/ogg"}],"lesson_position":44}}
            """#.data(using: .utf8)!
        
        let decoder = WaniKaniResourceDecoder()
        
        do {
            let resource = try decoder.decode(ResourceCollectionItem.self, from: data)
            
            let expected = ResourceCollectionItem(id: 2467,
                                                  type: .vocabulary,
                                                  url: URL(string: "https://api.wanikani.com/v2/subjects/2467")!,
                                                  dataUpdatedAt: makeUTCDate(year: 2019, month: 2, day: 7, hour: 0, minute: 28, second: 35),
                                                  data: Vocabulary(createdAt: makeUTCDate(year: 2012, month: 2, day: 28, hour: 8, minute: 4, second: 47),
                                                                   level: 1,
                                                                   slug: "一",
                                                                   hiddenAt: nil,
                                                                   documentURL: URL(string: "https://www.wanikani.com/vocabulary/%E4%B8%80")!,
                                                                   characters: "一",
                                                                   meanings: [Meaning(meaning: "One", isPrimary: true, isAcceptedAnswer: true)],
                                                                   auxiliaryMeanings: [AuxiliaryMeaning(type: "whitelist", meaning: "1")],
                                                                   readings: [Reading(reading: "いち", isPrimary: true, isAcceptedAnswer: true)],
                                                                   partsOfSpeech: ["numeral"],
                                                                   componentSubjectIDs: [440],
                                                                   meaningMnemonic: "As is the case with most vocab words that consist of a single kanji, this vocab word has the same meaning as the kanji it parallels, which is <vocabulary>one</vocabulary>.",
                                                                   readingMnemonic: "When a vocab word is all alone and has no okurigana (hiragana attached to kanji) connected to it, it usually uses the kun'yomi reading. Numbers are an exception, however. When a number is all alone, with no kanji or okurigana, it is going to be the on'yomi reading, which you learned with the kanji.  Just remember this exception for alone numbers and you'll be able to read future number-related vocab to come.",
                                                                   contextSentences: [
                                                                    Vocabulary.ContextSentence(english: "Let’s meet up once.", japanese: "一ど、あいましょう。"),
                                                                    Vocabulary.ContextSentence(english: "First place was an American.", japanese: "一いはアメリカ人でした。"),
                                                                    Vocabulary.ContextSentence(english: "I’m the weakest man in the world.", japanese: "ぼくはせかいで一ばんよわい。"),
                                                                    ],
                                                                   pronunciationAudios: [
                                                                    Vocabulary.PronunciationAudio(url: URL(string: "https://cdn.wanikani.com/audios/3020-subject-2467.mp3?1547862356")!,
                                                                                                  metadata: Vocabulary.PronunciationAudio.Metadata(gender: "male", sourceID: 2711, pronunciation: "いち", voiceActorID: 2, voiceActorName: "Kenichi", voiceDescription: "Tokyo accent"),
                                                                                                  contentType: "audio/mpeg"),
                                                                    Vocabulary.PronunciationAudio(url: URL(string: "https://cdn.wanikani.com/audios/3018-subject-2467.ogg?1547862356")!,
                                                                                                  metadata: Vocabulary.PronunciationAudio.Metadata(gender: "male", sourceID: 2711, pronunciation: "いち", voiceActorID: 2, voiceActorName: "Kenichi", voiceDescription: "Tokyo accent"),
                                                                                                  contentType: "audio/ogg"),
                                                                    ],
                                                                   lessonPosition: 44))
            
            XCTAssertEqual(resource, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
