//
//  LevelProgressionTable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

final class LevelProgressionTable: Table {
    let id = Column(name: "id", type: .int, nullable: false, primaryKey: true)
    let level = Column(name: "level", type: .int, nullable: false, unique: true)
    let createdAt = Column(name: "created_at", type: .float)
    let unlockedAt = Column(name: "unlocked_at", type: .float)
    let startedAt = Column(name: "started_at", type: .float)
    let passedAt = Column(name: "passed_at", type: .float)
    let completedAt = Column(name: "completed_at", type: .float)
    let abandonedAt = Column(name: "abandoned_at", type: .float)
    
    init() {
        super.init(name: "level_progression")
    }
}
