//
//  KanjiTable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

final class KanjiTable: Table, SubjectTable {
    let id = Column(name: "id", type: .int, nullable: false, primaryKey: true)
    let createdAt = Column(name: "created_at", type: .float, nullable: false)
    let level = Column(name: "level", type: .int, nullable: false)
    let slug = Column(name: "slug", type: .text, nullable: false)
    let hiddenAt = Column(name: "hidden_at", type: .float)
    let documentURL = Column(name: "document_url", type: .text, nullable: false)
    let characters = Column(name: "characters", type: .text, nullable: false)
    let meaningMnemonic = Column(name: "meaning_mnemonic", type: .text, nullable: false)
    let meaningHint = Column(name: "meaning_hint", type: .text, nullable: true)
    let readingMnemonic = Column(name: "reading_mnemonic", type: .text, nullable: false)
    let readingHint = Column(name: "reading_hint", type: .text, nullable: true)
    let lessonPosition = Column(name: "lesson_position", type: .int, nullable: false)
    
    init() {
        super.init(name: "kanji",
                   indexes: [TableIndex(name: "idx_kanji_by_level", columns: [level])])
    }
}
