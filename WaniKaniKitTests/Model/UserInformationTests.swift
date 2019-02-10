//
//  UserInformationTests.swift
//  WaniKaniKitTests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import XCTest
@testable import WaniKaniKit

class UserInformationTests: XCTestCase {
    
    func testDecode() {
        let data = """
            {"object":"user","url":"https://api.wanikani.com/v2/user","data_updated_at":"2019-02-09T18:21:51.000000Z","data":{"id":"7d1742c5-c493-444b-97ae-c495bec9d850","username":"cplaverty","level":14,"profile_url":"https://www.wanikani.com/users/cplaverty","started_at":"2014-06-12T07:40:29.000000Z","subscription":{"active":true,"type":"lifetime","max_level_granted":60,"period_ends_at":null},"current_vacation_started_at":null}}
            """.data(using: .utf8)!
        
        let decoder = WaniKaniResourceDecoder()
        
        do {
            let resource = try decoder.decode(StandaloneResource.self, from: data)
            
            let expected = StandaloneResource(type: .user,
                                              url: URL(string: "https://api.wanikani.com/v2/user")!,
                                              dataUpdatedAt: makeUTCDate(year: 2019, month: 2, day: 9, hour: 18, minute: 21, second: 51),
                                              data: UserInformation(id: "7d1742c5-c493-444b-97ae-c495bec9d850",
                                                                    username: "cplaverty",
                                                                    level: 14,
                                                                    profileURL: URL(string: "https://www.wanikani.com/users/cplaverty")!,
                                                                    startedAt: makeUTCDate(year: 2014, month: 6, day: 12, hour: 7, minute: 40, second: 29),
                                                                    subscription: UserInformation.Subscription(isActive: true,
                                                                                                               type: "lifetime",
                                                                                                               maxLevelGranted: 60,
                                                                                                               periodEndsAt: nil),
                                                                    currentVacationStartedAt: nil))
            
            XCTAssertEqual(resource, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
