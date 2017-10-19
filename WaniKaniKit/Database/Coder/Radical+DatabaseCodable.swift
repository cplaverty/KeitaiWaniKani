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
        let characterImagesBySubjectID = try CharacterImage.read(from: database, ids: ids)
        let meaningsBySubjectID = try Meaning.read(from: database, ids: ids)
        
        var parameterNames = [String]()
        parameterNames.reserveCapacity(ids.count)
        var queryArgs = [String: Any]()
        queryArgs.reserveCapacity(ids.count)
        
        for (index, id) in ids.enumerated() {
            var parameterName = "subject_id_\(index)"
            parameterNames.append(":" + parameterName)
            queryArgs[parameterName] = id
        }
        
        let query = """
        SELECT \(table.id), \(table.level), \(table.createdAt), \(table.slug), \(table.character), \(table.documentURL)
        FROM \(table)
        WHERE \(table.id) IN (\(parameterNames.joined(separator: ",")))
        """
        
        guard let resultSet = database.executeQuery(query, withParameterDictionary: queryArgs) else {
            throw database.lastError()
        }
        defer { resultSet.close() }
        
        var items = [Int: Radical]()
        items.reserveCapacity(ids.count)
        
        while resultSet.next() {
            let id = resultSet.long(forColumn: table.id.name)
            let level = resultSet.long(forColumn: table.level.name)
            let createdAt = resultSet.date(forColumn: table.createdAt.name)!
            let slug = resultSet.string(forColumn: table.slug.name)!
            let character = resultSet.string(forColumn: table.character.name)
            let characterImages = characterImagesBySubjectID[id] ?? []
            let meanings = meaningsBySubjectID[id] ?? []
            let documentURL = resultSet.url(forColumn: table.documentURL.name)!
            
            items[id] = Radical(level: level, createdAt: createdAt, slug: slug, character: character, characterImages: characterImages, meanings: meanings, documentURL: documentURL)
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
        
        try SubjectSearch.write(to: database, id: id, character: character, meanings: meanings, readings: [])
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
        var parameterNames = [String]()
        parameterNames.reserveCapacity(ids.count)
        var queryArgs = [String: Any]()
        queryArgs.reserveCapacity(ids.count)
        
        for (index, id) in ids.enumerated() {
            var parameterName = "subject_id_\(index)"
            parameterNames.append(":" + parameterName)
            queryArgs[parameterName] = id
        }
        
        let query = """
        SELECT \(table.subjectID), \(table.contentType), \(table.url)
        FROM \(table)
        WHERE \(table.subjectID) IN (\(parameterNames.joined(separator: ",")))
        ORDER BY \(table.subjectID)
        """
        
        guard let resultSet = database.executeQuery(query, withParameterDictionary: queryArgs) else {
            throw database.lastError()
        }
        defer { resultSet.close() }
        
        var items = [Int: [Radical.CharacterImage]]()
        items.reserveCapacity(ids.count)
        
        while resultSet.next() {
            let subjectID = resultSet.long(forColumn: table.subjectID.name)
            let image = Radical.CharacterImage(contentType: resultSet.string(forColumn: table.contentType.name)!,
                                               url: resultSet.url(forColumn: table.url.name)!)
            
            items[subjectID, default: []].append(image)
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
