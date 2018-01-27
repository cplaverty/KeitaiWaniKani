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
            {"object":"user","url":"https://www.wanikani.com/api/v2/user","data_updated_at":"2018-01-27T16:55:30.000000Z","data":{"username":"cplaverty","level":14,"max_level_granted_by_subscription":60,"profile_url":"https://www.wanikani.com/users/cplaverty","started_at":"2014-06-12T07:40:29.000000Z","subscribed":true,"current_vacation_started_at":null}}
            """.data(using: .utf8)!
        
        let decoder = WaniKaniResourceDecoder()
        
        do {
            let resource = try decoder.decode(StandaloneResource.self, from: data)
            
            let expected = StandaloneResource(type: .user,
                                              url: URL(string: "https://www.wanikani.com/api/v2/user")!,
                                              dataUpdatedAt: makeUTCDate(year: 2018, month: 1, day: 27, hour: 16, minute: 55, second: 30),
                                              data: UserInformation(username: "cplaverty",
                                                                    level: 14,
                                                                    maxLevelGrantedBySubscription: 60,
                                                                    startedAt: makeUTCDate(year: 2014, month: 6, day: 12, hour: 7, minute: 40, second: 29),
                                                                    isSubscribed: true,
                                                                    profileURL: URL(string: "https://www.wanikani.com/users/cplaverty")!,
                                                                    currentVacationStartedAt: nil))
            
            XCTAssertEqual(resource, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
