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
    let isAcceptedAnswer = Column(name: "is_accepted_answer", type: .int, nullable: false)
    
    init() {
        super.init(name: "meanings")
    }
}
