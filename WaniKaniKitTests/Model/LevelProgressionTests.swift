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
            {"id":3477,"object":"level_progression","url":"https://www.wanikani.com/api/v2/level_progressions/3477","data_updated_at":"2017-10-24T18:18:15.000000Z","data":{"created_at":"2017-09-27T22:06:12.000000Z","level":14,"unlocked_at":"2017-09-19T22:24:32.000000Z","started_at":"2017-09-27T22:06:12.000000Z","passed_at":null,"completed_at":null,"abandoned_at":null}}
            """.data(using: .utf8)!
        
        let decoder = WaniKaniResourceDecoder()
        
        do {
            let resource = try decoder.decode(ResourceCollectionItem.self, from: data)
            
            let expected = ResourceCollectionItem(id: 3477,
                                                  type: .levelProgression,
                                                  url: URL(string: "https://www.wanikani.com/api/v2/level_progressions/3477")!,
                                                  dataUpdatedAt: makeUTCDate(year: 2017, month: 10, day: 24, hour: 18, minute: 18, second: 15),
                                                  data: LevelProgression(level: 14,
                                                                         createdAt: makeUTCDate(year: 2017, month: 9, day: 27, hour: 22, minute: 6, second: 12),
                                                                         unlockedAt: makeUTCDate(year: 2017, month: 9, day: 19, hour: 22, minute: 24, second: 32),
                                                                         startedAt: makeUTCDate(year: 2017, month: 9, day: 27, hour: 22, minute: 6, second: 12),
                                                                         passedAt: nil,
                                                                         completedAt: nil,
                                                                         abandonedAt: nil))
            
            XCTAssertEqual(resource, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
