//
//  SubjectComponentsTable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

final class SubjectComponentsTable: Table {
    let subjectID = Column(name: "subject_id", type: .int, nullable: false, primaryKey: true)
    let index = Column(name: "idx", type: .int, nullable: false, primaryKey: true)
    let componentSubjectID = Column(name: "component_subject_id", type: .int, nullable: false)
    
    init() {
        super.init(name: "subject_components",
                   indexes: [TableIndex(name: "idx_subject_components_by_subject_id", columns: [subjectID])])
    }
}
