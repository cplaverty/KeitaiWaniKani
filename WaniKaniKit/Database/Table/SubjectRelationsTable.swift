//
//  RelatedSubjectsTable.swift
//  WaniKaniKit
//
//  Copyright © 2018 Chris Laverty. All rights reserved.
//

final class SubjectRelationsTable: Table {
    let relationType = Column(name: "relation_type", type: .text, nullable: false, primaryKey: true)
    let subjectID = Column(name: "subject_id", type: .int, nullable: false, primaryKey: true)
    let index = Column(name: "idx", type: .int, nullable: false, primaryKey: true)
    let relatedSubjectID = Column(name: "related_subject_id", type: .int, nullable: false)
    
    init() {
        super.init(name: "related_subjects")
    }
}
