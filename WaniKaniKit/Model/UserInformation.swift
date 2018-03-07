//
//  UserInformation.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct UserInformation: StandaloneResourceData, Equatable {
    public let username: String
    public let level: Int
    public let maxLevelGrantedBySubscription: Int
    public let startedAt: Date
    public let isSubscribed: Bool
    public let profileURL: URL?
    public let currentVacationStartedAt: Date?
    
    private enum CodingKeys: String, CodingKey {
        case username
        case level
        case maxLevelGrantedBySubscription = "max_level_granted_by_subscription"
        case startedAt = "started_at"
        case isSubscribed = "subscribed"
        case profileURL = "profile_url"
        case currentVacationStartedAt = "current_vacation_started_at"
    }
}
