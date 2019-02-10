//
//  RadicalTable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

final class RadicalTable: Table, SubjectTable {
    let id = Column(name: "id", type: .int, nullable: false, primaryKey: true)
    let createdAt = Column(name: "created_at", type: .float, nullable: false)
    let level = Column(name: "level", type: .int, nullable: false)
    let slug = Column(name: "slug", type: .text, nullable: false)
    let hiddenAt = Column(name: "hidden_at", type: .float)
    let documentURL = Column(name: "document_url", type: .text, nullable: false)
    let characters = Column(name: "characters", type: .text)
    let meaningMnemonic = Column(name: "meaning_mnemonic", type: .text, nullable: false)
    let lessonPosition = Column(name: "lesson_position", type: .int, nullable: false)

    init() {
        super.init(name: "radicals",
                   indexes: [TableIndex(name: "idx_radicals_by_level", columns: [level])])
    }
}

final class RadicalCharacterImagesTable: Table {
    let subjectID = Column(name: "subject_id", type: .int, nullable: false, primaryKey: true)
    let index = Column(name: "idx", type: .int, nullable: false, primaryKey: true)
    let url = Column(name: "url", type: .text, nullable: false)
    let contentType = Column(name: "content_type", type: .int, nullable: false)
    
    init() {
        super.init(name: "radical_character_images")
    }
}

final class RadicalCharacterImagesMetadataTable: Table {
    let subjectID = Column(name: "subject_id", type: .int, nullable: false, primaryKey: true)
    let index = Column(name: "idx", type: .int, nullable: false, primaryKey: true)
    let key = Column(name: "key", type: .int, nullable: false, primaryKey: true)
    let value = Column(name: "value", type: .text, nullable: false)
    
    init() {
        super.init(name: "radical_character_image_metadata")
    }
}
