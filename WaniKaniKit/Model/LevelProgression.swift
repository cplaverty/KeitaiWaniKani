//
//  LevelProgression.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct LevelProgression: ResourceCollectionItemData {
    public let level: Int
    public let createdAt: Date
    public let unlockedAt: Date?
    public let startedAt: Date?
    public let passedAt: Date?
    public let completedAt: Date?
    public let abandonedAt: Date?
    
    private enum CodingKeys: String, CodingKey {
        case level
        case createdAt = "created_at"
        case unlockedAt = "unlocked_at"
        case startedAt = "started_at"
        case passedAt = "passed_at"
        case completedAt = "completed_at"
        case abandonedAt = "abandoned_at"
    }
}

extension LevelProgression: Equatable {
    public static func ==(lhs: LevelProgression, rhs: LevelProgression) -> Bool {
        return lhs.level == rhs.level
            && lhs.createdAt == rhs.createdAt
            && lhs.unlockedAt == rhs.unlockedAt
            && lhs.startedAt == rhs.startedAt
            && lhs.passedAt == rhs.passedAt
            && lhs.completedAt == rhs.completedAt
            && lhs.abandonedAt == rhs.abandonedAt
    }
}
