//
//  Kanji+DatabaseCodable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB

private let table = Tables.kanji

extension Kanji: DatabaseCodable {
    static func read(from database: FMDatabase, level: Int) throws -> [ResourceCollectionItem] {
        let query = "SELECT \(table.id) FROM \(table) WHERE \(table.level) = ? AND \(table.hiddenAt) IS NULL"
        
        let resultSet = try database.executeQuery(query, values: [level])
        
        var subjectIDs = [Int]()
        while resultSet.next() {
            subjectIDs.append(resultSet.long(forColumnIndex: 0))
        }
        resultSet.close()
        
        return try ResourceCollectionItem.read(from: database, ids: subjectIDs, type: .kanji)
    }
    
    static func read(from database: FMDatabase, ids: [Int]) throws -> [Int: Kanji] {
        var items = [Int: Kanji]()
        items.reserveCapacity(ids.count)
        
        for id in ids {
            items[id] = try Kanji(from: database, id: id)
        }
        
        return items
    }
    
    init(from database: FMDatabase, id: Int) throws {
        let meanings = try Meaning.read(from: database, id: id)
        let auxiliaryMeanings = try AuxiliaryMeaning.read(from: database, id: id)
        let readings = try Reading.read(from: database, id: id)
        let subjectComponents = try SubjectRelation.read(from: database, type: .component, id: id)
        let subjectAmalgamation = try SubjectRelation.read(from: database, type: .amalgamation, id: id)
        let visuallySimilarSubjectIDs = try SubjectRelation.read(from: database, type: .visuallySimilar, id: id)
        
        let query = """
        SELECT \(table.createdAt), \(table.level), \(table.slug), \(table.hiddenAt), \(table.documentURL), \(table.characters), \(table.meaningMnemonic), \(table.meaningHint), \(table.readingMnemonic), \(table.readingHint), \(table.lessonPosition)
        FROM \(table)
        WHERE \(table.id) = ?
        """
        
        let resultSet = try database.executeQuery(query, values: [id])
        defer { resultSet.close() }
        
        guard resultSet.next() else {
            throw DatabaseError.itemNotFound(id: id)
        }
        
        self.createdAt = resultSet.date(forColumn: table.createdAt.name)!
        self.level = resultSet.long(forColumn: table.level.name)
        self.slug = resultSet.string(forColumn: table.slug.name)!
        self.hiddenAt = resultSet.date(forColumn: table.hiddenAt.name)
        self.documentURL = resultSet.url(forColumn: table.documentURL.name)!
        self.characters = resultSet.string(forColumn: table.characters.name)!
        self.meanings = meanings
        self.auxiliaryMeanings = auxiliaryMeanings
        self.readings = readings
        self.componentSubjectIDs = subjectComponents
        self.amalgamationSubjectIDs = subjectAmalgamation
        self.visuallySimilarSubjectIDs = visuallySimilarSubjectIDs
        self.meaningMnemonic = resultSet.string(forColumn: table.meaningMnemonic.name)!
        self.meaningHint = resultSet.string(forColumn: table.meaningHint.name)
        self.readingMnemonic = resultSet.string(forColumn: table.readingMnemonic.name)!
        self.readingHint = resultSet.string(forColumn: table.readingHint.name)
        self.lessonPosition = resultSet.long(forColumn: table.lessonPosition.name)
    }
    
    func write(to database: FMDatabase, id: Int) throws {
        try Meaning.write(items: meanings, to: database, id: id)
        try AuxiliaryMeaning.write(items: auxiliaryMeanings, to: database, id: id)
        try Reading.write(items: readings, to: database, id: id)
        try SubjectRelation.write(items: componentSubjectIDs, to: database, type: .component, id: id)
        try SubjectRelation.write(items: amalgamationSubjectIDs, to: database, type: .amalgamation, id: id)
        try SubjectRelation.write(items: visuallySimilarSubjectIDs, to: database, type: .visuallySimilar, id: id)
        
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.id.name), \(table.createdAt.name), \(table.level.name), \(table.slug.name), \(table.hiddenAt.name), \(table.documentURL.name), \(table.characters.name), \(table.meaningMnemonic.name), \(table.meaningHint.name), \(table.readingMnemonic.name), \(table.readingHint.name), \(table.lessonPosition.name))
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        let values: [Any] = [
            id, createdAt, level, slug, hiddenAt as Any, documentURL.absoluteString, characters, meaningMnemonic, meaningHint as Any, readingMnemonic, readingHint as Any, lessonPosition
        ]
        try database.executeUpdate(query, values: values)
        
        try SubjectSearch.write(to: database, id: id, characters: characters, level: level, meanings: meanings, readings: readings, hidden: hiddenAt != nil)
    }
}
