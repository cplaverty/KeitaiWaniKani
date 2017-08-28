//
//  StudyMaterialsTable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

final class StudyMaterialsTable: Table {
    let id = Column(name: "id", type: .int, nullable: false, primaryKey: true)
    let createdAt = Column(name: "created_at", type: .float, nullable: false)
    let subjectID = Column(name: "subject_id", type: .int, nullable: false, unique: true)
    let subjectType = Column(name: "subject_type", type: .text, nullable: false)
    let meaningNote = Column(name: "meaning_note", type: .text, nullable: false)
    let readingNote = Column(name: "reading_note", type: .text, nullable: false)
    
    init() {
        super.init(name: "study_materials")
    }
}

final class StudyMaterialsMeaningSynonymsTable: Table {
    let studyMaterialsID = Column(name: "study_materials_id", type: .int, nullable: false, primaryKey: true)
    let index = Column(name: "idx", type: .int, nullable: false, primaryKey: true)
    let synonym = Column(name: "synonym", type: .text, nullable: false)
    
    init() {
        super.init(name: "study_materials_meaning_synonyms",
                   indexes: [TableIndex(name: "idx_readings_by_study_materials_id", columns: [studyMaterialsID])])
    }
}
