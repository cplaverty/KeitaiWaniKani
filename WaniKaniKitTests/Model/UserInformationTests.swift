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
            {"object":"user","url":"https://www.wanikani.com/api/v2/user","data_updated_at":"2017-07-25T08:08:06.000000Z","data":{"username":"cplaverty","level":13,"profile_url":"https://www.wanikani.com/users/cplaverty","started_at":"2014-06-12T07:40:29.000000Z","subscribed":true,"current_vacation_started_at":null}}
            """.data(using: .utf8)!
        
        let decoder = WaniKaniResourceDecoder()
        
        do {
            let resource = try decoder.decode(StandaloneResource.self, from: data)
            
            let expected = StandaloneResource(type: .user,
                                              url: URL(string: "https://www.wanikani.com/api/v2/user")!,
                                              dataUpdatedAt: makeUTCDate(year: 2017, month: 7, day: 25, hour: 8, minute: 8, second: 6),
                                              data: UserInformation(username: "cplaverty",
                                                                    level: 13,
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
