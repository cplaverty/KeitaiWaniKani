//
//  LevelProgressionTests.swift
//  WaniKaniKitTests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import XCTest
@testable import WaniKaniKit

class LevelProgressionTests: XCTestCase {
    
    func testDecode() {
        let data = """
            {"id":3887,"object":"level_progression","url":"https://api.wanikani.com/v2/level_progressions/3887","data_updated_at":"2017-09-27T22:42:48.000000Z","data":{"created_at":"2017-09-27T22:42:48.000000Z","level":2,"unlocked_at":"2017-09-03T20:57:54.000000Z","started_at":"2017-09-03T20:59:40.000000Z","passed_at":null,"completed_at":null,"abandoned_at":null}}
            """.data(using: .utf8)!
        
        let decoder = WaniKaniResourceDecoder()
        
        do {
            let resource = try decoder.decode(ResourceCollectionItem.self, from: data)
            
            let expected = ResourceCollectionItem(id: 3887,
                                                  type: .levelProgression,
                                                  url: URL(string: "https://api.wanikani.com/v2/level_progressions/3887")!,
                                                  dataUpdatedAt: makeUTCDate(year: 2017, month: 9, day: 27, hour: 22, minute: 42, second: 48),
                                                  data: LevelProgression(level: 2,
                                                                         createdAt: makeUTCDate(year: 2017, month: 9, day: 27, hour: 22, minute: 42, second: 48),
                                                                         unlockedAt: makeUTCDate(year: 2017, month: 9, day: 3, hour: 20, minute: 57, second: 54),
                                                                         startedAt: makeUTCDate(year: 2017, month: 9, day: 3, hour: 20, minute: 59, second: 40),
                                                                         passedAt: nil,
                                                                         completedAt: nil,
                                                                         abandonedAt: nil))
            
            XCTAssertEqual(resource, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
