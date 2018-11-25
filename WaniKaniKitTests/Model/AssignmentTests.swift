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
            {"id":2363694,"object":"assignment","url":"https://api.wanikani.com/v2/assignments/2363694","data_updated_at":"2018-05-09T21:21:30.000000Z","data":{"created_at":"2016-02-07T00:11:03.000000Z","subject_id":3234,"subject_type":"vocabulary","srs_stage":9,"srs_stage_name":"Burned","unlocked_at":"2016-02-07T00:11:03.000000Z","started_at":"2016-02-07T00:11:03.000000Z","passed_at":null,"burned_at":"2017-09-04T08:35:20.000000Z","available_at":null,"resurrected_at":null,"passed":true,"resurrected":false,"hidden":false}}
            """.data(using: .utf8)!
        
        let decoder = WaniKaniResourceDecoder()
        
        do {
            let resource = try decoder.decode(ResourceCollectionItem.self, from: data)
            
            let expected = ResourceCollectionItem(id: 2363694,
                                                  type: .assignment,
                                                  url: URL(string: "https://api.wanikani.com/v2/assignments/2363694")!,
                                                  dataUpdatedAt: makeUTCDate(year: 2018, month: 5, day: 9, hour: 21, minute: 21, second: 30),
                                                  data: Assignment(createdAt: makeUTCDate(year: 2016, month: 2, day: 7, hour: 0, minute: 11, second: 3),
                                                                   subjectID: 3234,
                                                                   subjectType: .vocabulary,
                                                                   srsStage: 9,
                                                                   srsStageName: "Burned",
                                                                   unlockedAt: makeUTCDate(year: 2016, month: 2, day: 7, hour: 0, minute: 11, second: 3),
                                                                   startedAt: makeUTCDate(year: 2016, month: 2, day: 7, hour: 0, minute: 11, second: 3),
                                                                   passedAt: nil,
                                                                   burnedAt: makeUTCDate(year: 2017, month: 9, day: 4, hour: 8, minute: 35, second: 20),
                                                                   availableAt: nil,
                                                                   resurrectedAt: nil,
                                                                   isPassed: true,
                                                                   isResurrected: false,
                                                                   isHidden: false))
            
            XCTAssertEqual(resource, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
