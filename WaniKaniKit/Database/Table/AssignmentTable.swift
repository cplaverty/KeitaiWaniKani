//
//  AssignmentTable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

final class AssignmentTable: Table {
    let id = Column(name: "id", type: .int, nullable: false, primaryKey: true)
    let subjectID = Column(name: "subject_id", type: .int, nullable: false, unique: true)
    let subjectType = Column(name: "subject_type", type: .text, nullable: false)
    let level = Column(name: "level", type: .int, nullable: false)
    let srsStage = Column(name: "srs_stage", type: .int, nullable: false)
    let srsStageName = Column(name: "srs_stage_name", type: .text, nullable: false)
    let unlockedAt = Column(name: "unlocked_at", type: .float)
    let startedAt = Column(name: "started_at", type: .float)
    let passedAt = Column(name: "passed_at", type: .float)
    let burnedAt = Column(name: "burned_at", type: .float)
    let availableAt = Column(name: "available_at", type: .float)
    let isPassed = Column(name: "is_passed", type: .int, nullable: false)
    let isResurrected = Column(name: "is_resurrected", type: .int, nullable: false)
    
    init() {
        super.init(name: "assignments",
                   indexes: [TableIndex(name: "idx_assignments_by_level", columns: [level]),
                             TableIndex(name: "idx_assignments_by_srs_stage", columns: [srsStage]),
                             TableIndex(name: "idx_assignments_by_available_at", columns: [availableAt])])
    }
}
