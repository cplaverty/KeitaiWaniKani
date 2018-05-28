//
//  SubjectAmalgamationsTable.swift
//  WaniKaniKit
//
//  Copyright © 2018 Chris Laverty. All rights reserved.
//

final class SubjectAmalgamationsTable: Table {
    let subjectID = Column(name: "subject_id", type: .int, nullable: false, primaryKey: true)
    let index = Column(name: "idx", type: .int, nullable: false, primaryKey: true)
    let amalgamationSubjectID = Column(name: "amalgamation_subject_id", type: .int, nullable: false)
    
    init() {
        super.init(name: "subject_amalgamations")
    }
}
