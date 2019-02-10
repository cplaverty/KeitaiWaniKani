//
//  UserInformationTable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

final class UserInformationTable: Table {
    let id = Column(name: "id", type: .text, nullable: false, primaryKey: true)
    let username = Column(name: "username", type: .text, nullable: false)
    let level = Column(name: "level", type: .int, nullable: false)
    let profileURL = Column(name: "profile_url", type: .text)
    let startedAt = Column(name: "started_at", type: .float, nullable: false)
    let isSubscriptionActive = Column(name: "is_subscription_active", type: .int, nullable: false)
    let subscriptionType = Column(name: "subscription_type", type: .text, nullable: false)
    let subscriptionMaxLevelGranted = Column(name: "subscription_max_level_granted", type: .int, nullable: false)
    let subscriptionPeriodEndsAt = Column(name: "subscription_period_ends_at", type: .float, nullable: true)
    let currentVacationStartedAt = Column(name: "current_vacation_started_at", type: .float)
    
    init() {
        super.init(name: "user_information")
    }
}
