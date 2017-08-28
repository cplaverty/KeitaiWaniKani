//
//  MeaningTable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

final class MeaningTable: Table {
    let subjectID = Column(name: "subject_id", type: .int, nullable: false, primaryKey: true)
    let index = Column(name: "idx", type: .int, nullable: false, primaryKey: true)
    let meaning = Column(name: "meaning", type: .text, nullable: false)
    let isPrimary = Column(name: "is_primary", type: .int, nullable: false)
    
    init() {
        super.init(name: "meanings",
                   indexes: [TableIndex(name: "idx_meanings_by_subject_id", columns: [subjectID])])
    }
}
