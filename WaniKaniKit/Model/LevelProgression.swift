//
//  LevelProgression.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct LevelProgression: ResourceCollectionItemData, Equatable {
    public let level: Int
    public let createdAt: Date
    public let unlockedAt: Date?
    public let startedAt: Date?
    public let passedAt: Date?
    public let completedAt: Date?
    public let abandonedAt: Date?
    
    public var duration: TimeInterval? {
        guard let unlockedAt = unlockedAt, let passedAt = passedAt else { return nil }
        return passedAt.timeIntervalSince(unlockedAt)
    }
    
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
