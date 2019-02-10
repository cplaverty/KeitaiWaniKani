//
//  VocabularyTable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

final class VocabularyTable: Table, SubjectTable {
    let id = Column(name: "id", type: .int, nullable: false, primaryKey: true)
    let createdAt = Column(name: "created_at", type: .float, nullable: false)
    let level = Column(name: "level", type: .int, nullable: false)
    let slug = Column(name: "slug", type: .text, nullable: false)
    let hiddenAt = Column(name: "hidden_at", type: .float)
    let documentURL = Column(name: "document_url", type: .text, nullable: false)
    let characters = Column(name: "characters", type: .text, nullable: false)
    let meaningMnemonic = Column(name: "meaning_mnemonic", type: .text, nullable: false)
    let readingMnemonic = Column(name: "reading_mnemonic", type: .text, nullable: false)
    let lessonPosition = Column(name: "lesson_position", type: .int, nullable: false)
    
    init() {
        super.init(name: "vocabulary",
                   indexes: [TableIndex(name: "idx_vocabulary_by_level", columns: [level])])
    }
}

final class VocabularyContextSentencesTable: Table {
    let subjectID = Column(name: "subject_id", type: .int, nullable: false, primaryKey: true)
    let index = Column(name: "idx", type: .int, nullable: false, primaryKey: true)
    let english = Column(name: "en", type: .text, nullable: false)
    let japanese = Column(name: "ja", type: .text, nullable: false)
    
    init() {
        super.init(name: "vocabulary_context_sentences")
    }
}

final class VocabularyPartsOfSpeechTable: Table {
    let subjectID = Column(name: "subject_id", type: .int, nullable: false, primaryKey: true)
    let index = Column(name: "idx", type: .int, nullable: false, primaryKey: true)
    let partOfSpeech = Column(name: "part_of_speech", type: .text, nullable: false)
    
    init() {
        super.init(name: "vocabulary_parts_of_speech")
    }
}

final class VocabularyPronunciationAudiosTable: Table {
    let subjectID = Column(name: "subject_id", type: .int, nullable: false, primaryKey: true)
    let index = Column(name: "idx", type: .int, nullable: false, primaryKey: true)
    let url = Column(name: "url", type: .text, nullable: false)
    let contentType = Column(name: "content_type", type: .int, nullable: false)
    
    init() {
        super.init(name: "vocabulary_pronunciation_audios")
    }
}

final class VocabularyPronunciationAudiosMetadataTable: Table {
    let subjectID = Column(name: "subject_id", type: .int, nullable: false, primaryKey: true)
    let index = Column(name: "idx", type: .int, nullable: false, primaryKey: true)
    let key = Column(name: "key", type: .int, nullable: false, primaryKey: true)
    let value = Column(name: "value", type: .text, nullable: false)
    
    init() {
        super.init(name: "vocabulary_pronunciation_audios_metadata")
    }
}
