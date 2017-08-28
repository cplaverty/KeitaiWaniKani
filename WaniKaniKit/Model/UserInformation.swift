//
//  UserInformation.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct UserInformation: StandaloneResourceData {
    public let username: String
    public let level: Int
    public let startedAt: Date
    public let isSubscribed: Bool
    public let profileURL: URL?
    public let currentVacationStartedAt: Date?
    
    private enum CodingKeys: String, CodingKey {
        case username
        case level
        case startedAt = "started_at"
        case isSubscribed = "subscribed"
        case profileURL = "profile_url"
        case currentVacationStartedAt = "current_vacation_started_at"
    }
}

extension UserInformation: Equatable {
    public static func ==(lhs: UserInformation, rhs: UserInformation) -> Bool {
        return lhs.username == rhs.username
            && lhs.level == rhs.level
            && lhs.startedAt == rhs.startedAt
            && lhs.isSubscribed == rhs.isSubscribed
            && lhs.profileURL == rhs.profileURL
            && lhs.currentVacationStartedAt == rhs.currentVacationStartedAt
    }
}
