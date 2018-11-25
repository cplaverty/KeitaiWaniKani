//
//  KanjiTable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

final class KanjiTable: Table, SubjectTable {
    let id = Column(name: "id", type: .int, nullable: false, primaryKey: true)
    let level = Column(name: "level", type: .int, nullable: false)
    let createdAt = Column(name: "created_at", type: .float, nullable: false)
    let slug = Column(name: "slug", type: .text, nullable: false)
    let characters = Column(name: "characters", type: .text, nullable: false)
    let documentURL = Column(name: "document_url", type: .text, nullable: false)
    let hiddenAt = Column(name: "hidden_at", type: .float)
    
    init() {
        super.init(name: "kanji",
                   indexes: [TableIndex(name: "idx_kanji_by_level", columns: [level])])
    }
}
