//
//  RadicalTable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

final class RadicalTable: Table {
    let id = Column(name: "id", type: .int, nullable: false, primaryKey: true)
    let level = Column(name: "level", type: .int, nullable: false)
    let createdAt = Column(name: "created_at", type: .float, nullable: false)
    let slug = Column(name: "slug", type: .text, nullable: false)
    let character = Column(name: "character", type: .text, nullable: true)
    let documentURL = Column(name: "document_url", type: .text, nullable: false)
    
    init() {
        super.init(name: "radicals",
                   indexes: [TableIndex(name: "idx_radicals_by_level", columns: [level])])
    }
}

final class RadicalCharacterImagesTable: Table {
    let subjectID = Column(name: "subject_id", type: .int, nullable: false)
    let contentType = Column(name: "content_type", type: .int, nullable: false)
    let url = Column(name: "url", type: .text, nullable: false)
    
    init() {
        super.init(name: "radical_character_images",
                   indexes: [TableIndex(name: "idx_radical_character_images_by_subject_id", columns: [subjectID])])
    }
}
