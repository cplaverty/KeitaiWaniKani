//
//  UserInformation.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct UserInformation: StandaloneResourceData, Equatable {
    public let id: String
    public let username: String
    public let level: Int
    public let profileURL: URL
    public let startedAt: Date
    public let subscription: Subscription
    public let currentVacationStartedAt: Date?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case username
        case level
        case profileURL = "profile_url"
        case startedAt = "started_at"
        case subscription
        case currentVacationStartedAt = "current_vacation_started_at"
    }
}

extension UserInformation {
    public struct Subscription: Codable, Equatable {
        public let isActive: Bool
        public let type: String
        public let maxLevelGranted: Int
        public let periodEndsAt: Date?
        
        private enum CodingKeys: String, CodingKey {
            case isActive = "active"
            case type
            case maxLevelGranted = "max_level_granted"
            case periodEndsAt = "period_ends_at"
        }
    }
}
