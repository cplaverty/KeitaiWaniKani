//
//  Vocabulary+DatabaseCodable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB

private let table = Tables.vocabulary

extension Vocabulary: DatabaseCodable {
    static func read(from database: FMDatabase, level: Int) throws -> [ResourceCollectionItem] {
        let query = "SELECT \(table.id) FROM \(table) WHERE \(table.level) = ?"
        
        let resultSet = try database.executeQuery(query, values: [level])
        
        var subjectIDs = [Int]()
        while resultSet.next() {
            subjectIDs.append(resultSet.long(forColumnIndex: 0))
        }
        resultSet.close()
        
        return try ResourceCollectionItem.read(from: database, ids: subjectIDs)
    }
    
    static func read(from database: FMDatabase, ids: [Int]) throws -> [Int: Vocabulary] {
        var items = [Int: Vocabulary]()
        items.reserveCapacity(ids.count)
        
        for id in ids {
            items[id] = try Vocabulary(from: database, id: id)
        }
        
        return items
    }
    
    init(from database: FMDatabase, id: Int) throws {
        let meanings = try Meaning.read(from: database, id: id)
        let readings = try Reading.read(from: database, id: id)
        let partsOfSpeech = try PartOfSpeech.read(from: database, id: id)
        let subjectComponents = try SubjectComponent.read(from: database, id: id)
        
        let query = """
        SELECT \(table.level), \(table.createdAt), \(table.slug), \(table.characters), \(table.documentURL)
        FROM \(table)
        WHERE \(table.id) = ?
        """
        
        let resultSet = try database.executeQuery(query, values: [id])
        defer { resultSet.close() }
        
        guard resultSet.next() else {
            throw DatabaseError.itemNotFound(id: id)
        }
        
        self.level = resultSet.long(forColumn: table.level.name)
        self.createdAt = resultSet.date(forColumn: table.createdAt.name)!
        self.slug = resultSet.string(forColumn: table.slug.name)!
        self.characters = resultSet.string(forColumn: table.characters.name)!
        self.meanings = meanings
        self.readings = readings
        self.partsOfSpeech = partsOfSpeech
        self.componentSubjectIDs = subjectComponents
        self.documentURL = resultSet.url(forColumn: table.documentURL.name)!
    }
    
    func write(to database: FMDatabase, id: Int) throws {
        try Meaning.write(items: meanings, to: database, id: id)
        try Reading.write(items: readings, to: database, id: id)
        try PartOfSpeech.write(items: partsOfSpeech, to: database, id: id)
        try SubjectComponent.write(items: componentSubjectIDs, to: database, id: id)
        
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.id.name), \(table.level.name), \(table.createdAt.name), \(table.slug.name), \(table.characters.name), \(table.documentURL.name))
        VALUES (?, ?, ?, ?, ?, ?)
        """
        
        let values: [Any] = [
            id, level, createdAt, slug, characters, documentURL.absoluteString
        ]
        try database.executeUpdate(query, values: values)
        
        try SubjectSearch.write(to: database, id: id, character: characters, level: level, meanings: meanings, readings: readings)
    }
}

struct PartOfSpeech: BulkDatabaseCodable {
    private static let table = Tables.vocabularyPartsOfSpeech
    
    static func read(from database: FMDatabase, id: Int) throws -> [String] {
        let query = """
        SELECT \(table.partOfSpeech)
        FROM \(table)
        WHERE \(table.subjectID) = ?
        ORDER BY \(table.index)
        """
        
        let resultSet = try database.executeQuery(query, values: [id])
        defer { resultSet.close() }
        
        var items = [String]()
        while resultSet.next() {
            items.append(resultSet.string(forColumn: table.partOfSpeech.name)!)
        }
        
        return items
    }
    
    static func read(from database: FMDatabase, ids: [Int]) throws -> [Int: [String]] {
        var items = [Int: [String]]()
        items.reserveCapacity(ids.count)
        
        for id in ids {
            items[id] = try read(from: database, id: id)
        }
        
        return items
    }
    
    static func write(items: [String], to database: FMDatabase, id: Int) throws {
        try database.executeUpdate("DELETE FROM \(table) WHERE \(table.subjectID) = ?", values: [id])
        
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.subjectID.name), \(table.index.name), \(table.partOfSpeech.name))
        VALUES (?, ?, ?)
        """
        
        for (index, item) in items.enumerated() {
            let values: [Any] = [
                id, index, item
            ]
            try database.executeUpdate(query, values: values)
        }
    }
}
