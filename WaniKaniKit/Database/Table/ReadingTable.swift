//
//  ReadingTable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

final class ReadingTable: Table {
    let subjectID = Column(name: "subject_id", type: .int, nullable: false, primaryKey: true)
    let index = Column(name: "idx", type: .int, nullable: false, primaryKey: true)
    let readingType = Column(name: "type", type: .text)
    let reading = Column(name: "reading", type: .text, nullable: false)
    let isPrimary = Column(name: "is_primary", type: .int, nullable: false)
    
    init() {
        super.init(name: "readings",
                   indexes: [TableIndex(name: "idx_readings_by_subject_id", columns: [subjectID])])
    }
}
