//
//  AssignmentTests.swift
//  WaniKaniKitTests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import XCTest
@testable import WaniKaniKit

class AssignmentTests: XCTestCase {
    
    func testDecode() {
        let data = """
            {"id":2363694,"object":"assignment","url":"https://www.wanikani.com/api/v2/assignments/2363694","data_updated_at":"2017-05-06T10:18:56.000000Z","data":{"subject_id":3234,"subject_type":"vocabulary","level":10,"srs_stage":8,"srs_stage_name":"Enlightened","unlocked_at":"2016-02-07T00:11:03.000000Z","started_at":null,"passed_at":null,"burned_at":null,"available_at":"2017-09-03T09:00:00.000000Z","passed":true,"resurrected":false}}
            """.data(using: .utf8)!
        
        let decoder = WaniKaniResourceDecoder()
        
        do {
            let resource = try decoder.decode(ResourceCollectionItem.self, from: data)
            
            let expected = ResourceCollectionItem(id: 2363694,
                                                  type: .assignment,
                                                  url: URL(string: "https://www.wanikani.com/api/v2/assignments/2363694")!,
                                                  dataUpdatedAt: makeUTCDate(year: 2017, month: 5, day: 6, hour: 10, minute: 18, second: 56),
                                                  data: Assignment(subjectID: 3234,
                                                                   subjectType: .vocabulary,
                                                                   level: 10,
                                                                   srsStage: 8,
                                                                   srsStageName: "Enlightened",
                                                                   unlockedAt: makeUTCDate(year: 2016, month: 2, day: 7, hour: 0, minute: 11, second: 3),
                                                                   startedAt: nil,
                                                                   passedAt: nil,
                                                                   burnedAt: nil,
                                                                   availableAt: makeUTCDate(year: 2017, month: 9, day: 3, hour: 9, minute: 0, second: 0),
                                                                   isPassed: true,
                                                                   isResurrected: false))
            
            XCTAssertEqual(resource, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
