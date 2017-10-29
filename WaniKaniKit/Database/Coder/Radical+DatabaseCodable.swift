//
//  Radical+DatabaseCodable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB

private let table = Tables.radicals

extension Radical: DatabaseCodable {
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
    
    static func read(from database: FMDatabase, ids: [Int]) throws -> [Int: Radical] {
        var items = [Int: Radical]()
        items.reserveCapacity(ids.count)
        
        for id in ids {
            items[id] = try Radical(from: database, id: id)
        }
        
        return items
    }
    
    init(from database: FMDatabase, id: Int) throws {
        let characterImages = try CharacterImage.read(from: database, id: id)
        let meanings = try Meaning.read(from: database, id: id)
        
        let query = """
        SELECT \(table.level), \(table.createdAt), \(table.slug), \(table.character), \(table.documentURL)
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
        self.character = resultSet.string(forColumn: table.character.name)
        self.characterImages = characterImages
        self.meanings = meanings
        self.documentURL = resultSet.url(forColumn: table.documentURL.name)!
    }
    
    func write(to database: FMDatabase, id: Int) throws {
        try CharacterImage.write(items: characterImages, to: database, id: id)
        try Meaning.write(items: meanings, to: database, id: id)
        
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.id.name), \(table.level.name), \(table.createdAt.name), \(table.slug.name), \(table.character.name), \(table.documentURL.name))
        VALUES (?, ?, ?, ?, ?, ?)
        """
        
        let values: [Any] = [
            id, level, createdAt, slug, character as Any, documentURL.absoluteString
        ]
        try database.executeUpdate(query, values: values)
        
        try SubjectSearch.write(to: database, id: id, character: character, level: level, meanings: meanings, readings: [])
    }
}

extension Radical.CharacterImage: BulkDatabaseCodable {
    private static let table = Tables.radicalCharacterImages
    
    static func read(from database: FMDatabase, id: Int) throws -> [Radical.CharacterImage] {
        let query = """
        SELECT \(table.contentType), \(table.url)
        FROM \(table)
        WHERE \(table.subjectID) = ?
        """
        
        let resultSet = try database.executeQuery(query, values: [id])
        defer { resultSet.close() }
        
        var items = [Radical.CharacterImage]()
        while resultSet.next() {
            items.append(Radical.CharacterImage(contentType: resultSet.string(forColumn: table.contentType.name)!,
                                                url: resultSet.url(forColumn: table.url.name)!))
        }
        
        return items
    }
    
    static func read(from database: FMDatabase, ids: [Int]) throws -> [Int: [Radical.CharacterImage]] {
        var items = [Int: [Radical.CharacterImage]]()
        items.reserveCapacity(ids.count)
        
        for id in ids {
            items[id] = try read(from: database, id: id)
        }
        
        return items
    }
    
    static func write(items: [Radical.CharacterImage], to database: FMDatabase, id: Int) throws {
        try database.executeUpdate("DELETE FROM \(table) WHERE \(table.subjectID) = ?", values: [id])
        
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.subjectID.name), \(table.contentType.name), \(table.url.name))
        VALUES (?, ?, ?)
        """
        
        for item in items {
            let values: [Any] = [
                id, item.contentType, item.url.absoluteString
            ]
            try database.executeUpdate(query, values: values)
        }
    }
}
