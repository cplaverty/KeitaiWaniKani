//
//  UserInformationTable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

final class UserInformationTable: Table {
    let username = Column(name: "username", type: .text, nullable: false, primaryKey: true)
    let level = Column(name: "level", type: .int, nullable: false)
    let startedAt = Column(name: "started_at", type: .float, nullable: false)
    let isSubscribed = Column(name: "is_subscribed", type: .int, nullable: false)
    let profileURL = Column(name: "profile_url", type: .text)
    let currentVacationStartedAt = Column(name: "current_vacation_started_at", type: .float)
    
    init() {
        super.init(name: "user_information")
    }
}
