//
//  SubjectsView.swift
//  WaniKaniKit
//
//  Copyright © 2018 Chris Laverty. All rights reserved.
//

final class SubjectsView: View {
    let id = Column(name: "id")
    let subjectType = Column(name: "subject_type")
    let level = Column(name: "level")
    let createdAt = Column(name: "created_at")
    let slug = Column(name: "slug")
    let characters = Column(name: "characters")
    let documentURL = Column(name: "document_url")
    let hiddenAt = Column(name: "hidden_at")
    
    init(radicals: RadicalTable, kanji: KanjiTable, vocabulary: VocabularyTable) {
        let selectStatement = """
        SELECT \(radicals.id), '\(SubjectType.radical.rawValue)', \(radicals.level), \(radicals.createdAt), \(radicals.slug), \(radicals.characters), \(radicals.documentURL), \(radicals.hiddenAt) FROM \(radicals)
        UNION ALL
        SELECT \(kanji.id), '\(SubjectType.kanji.rawValue)', \(kanji.level), \(kanji.createdAt), \(kanji.slug), \(kanji.characters), \(kanji.documentURL), \(kanji.hiddenAt) FROM \(kanji)
        UNION ALL
        SELECT \(vocabulary.id), '\(SubjectType.vocabulary.rawValue)', \(vocabulary.level), \(vocabulary.createdAt), \(vocabulary.slug), \(vocabulary.characters), \(vocabulary.documentURL), \(vocabulary.hiddenAt) FROM \(vocabulary)
        """
        
        super.init(name: "subjects", selectStatement: selectStatement)
    }
}
