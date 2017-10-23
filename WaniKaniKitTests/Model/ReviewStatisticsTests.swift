//
//  ReviewStatisticsTests.swift
//  WaniKaniKitTests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import XCTest
@testable import WaniKaniKit

class ReviewStatisticsTests: XCTestCase {
    
    func testDecode() {
        let data = """
            {"id":2364240,"object":"review_statistic","url":"https://www.wanikani.com/api/v2/review_statistics/2364240","data_updated_at":"2017-06-26T22:19:23.000000Z","data":{"created_at":"2016-09-23T08:13:49.000000Z","subject_id":889,"subject_type":"kanji","meaning_correct":8,"meaning_incorrect":1,"meaning_max_streak":5,"meaning_current_streak":3,"reading_correct":8,"reading_incorrect":3,"reading_max_streak":5,"reading_current_streak":2,"percentage_correct":80}}
            """.data(using: .utf8)!
        
        let decoder = WaniKaniResourceDecoder()
        
        do {
            let resource = try decoder.decode(ResourceCollectionItem.self, from: data)
            
            let expected = ResourceCollectionItem(id: 2364240,
                                                  type: .reviewStatistic,
                                                  url: URL(string: "https://www.wanikani.com/api/v2/review_statistics/2364240")!,
                                                  dataUpdatedAt: makeUTCDate(year: 2017, month: 6, day: 26, hour: 22, minute: 19, second: 23),
                                                  data: ReviewStatistics(createdAt: makeUTCDate(year: 2016, month: 9, day: 23, hour: 8, minute: 13, second: 49),
                                                                         subjectID: 889,
                                                                         subjectType: .kanji,
                                                                         meaningCorrect: 8,
                                                                         meaningIncorrect: 1,
                                                                         meaningMaxStreak: 5,
                                                                         meaningCurrentStreak: 3,
                                                                         readingCorrect: 8,
                                                                         readingIncorrect: 3,
                                                                         readingMaxStreak: 5,
                                                                         readingCurrentStreak: 2,
                                                                         percentageCorrect: 80))
            
            XCTAssertEqual(resource, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
