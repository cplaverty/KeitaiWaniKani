//
//  VocabularyTable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

final class VocabularyTable: Table {
    let id = Column(name: "id", type: .int, nullable: false, primaryKey: true)
    let level = Column(name: "level", type: .int, nullable: false)
    let createdAt = Column(name: "created_at", type: .float, nullable: false)
    let slug = Column(name: "slug", type: .text, nullable: false)
    let characters = Column(name: "characters", type: .text, nullable: false)
    let documentURL = Column(name: "document_url", type: .text, nullable: false)
    
    init() {
        super.init(name: "vocabulary",
                   indexes: [TableIndex(name: "idx_vocabulary_by_level", columns: [level])])
    }
}

final class VocabularyPartsOfSpeechTable: Table {
    let subjectID = Column(name: "subject_id", type: .int, nullable: false, primaryKey: true)
    let index = Column(name: "idx", type: .int, nullable: false, primaryKey: true)
    let partOfSpeech = Column(name: "part_of_speech", type: .text, nullable: false)
    
    init() {
        super.init(name: "vocabulary_parts_of_speech",
                   indexes: [TableIndex(name: "idx_vocabulary_parts_of_speech_by_subject_id", columns: [subjectID])])
    }
}
