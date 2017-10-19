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
        let query = "SELECT \(table.id) FROM \(table) WHERE \(table.level) = ?"
        
        let resultSet = try database.executeQuery(query, values: [level])
        
        var subjectIDs = [Int]()
        while resultSet.next() {
            subjectIDs.append(resultSet.long(forColumnIndex: 0))
        }
        resultSet.close()
        
        return try ResourceCollectionItem.read(from: database, ids: subjectIDs)
    }
    
    static func read(from database: FMDatabase, ids: [Int]) throws -> [Int: Kanji] {
        let meaningsBySubjectID = try Meaning.read(from: database, ids: ids)
        let readingsBySubjectID = try Reading.read(from: database, ids: ids)
        let subjectComponentsBySubjectID = try SubjectComponent.read(from: database, ids: ids)
        
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
        
        var items = [Int: Kanji]()
        items.reserveCapacity(ids.count)
        
        while resultSet.next() {
            let id = resultSet.long(forColumn: table.id.name)
            let level = resultSet.long(forColumn: table.level.name)
            let createdAt = resultSet.date(forColumn: table.createdAt.name)!
            let slug = resultSet.string(forColumn: table.slug.name)!
            let character = resultSet.string(forColumn: table.character.name)!
            let meanings = meaningsBySubjectID[id] ?? []
            let readings = readingsBySubjectID[id] ?? []
            let componentSubjectIDs = subjectComponentsBySubjectID[id] ?? []
            let documentURL = resultSet.url(forColumn: table.documentURL.name)!
            
            items[id] = Kanji(level: level, createdAt: createdAt, slug: slug, character: character, meanings: meanings, readings: readings, componentSubjectIDs: componentSubjectIDs, documentURL: documentURL)
        }
        
        return items
    }
    
    init(from database: FMDatabase, id: Int) throws {
        let meanings = try Meaning.read(from: database, id: id)
        let readings = try Reading.read(from: database, id: id)
        let subjectComponents = try SubjectComponent.read(from: database, id: id)
        
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
        self.character = resultSet.string(forColumn: table.character.name)!
        self.meanings = meanings
        self.readings = readings
        self.componentSubjectIDs = subjectComponents
        self.documentURL = resultSet.url(forColumn: table.documentURL.name)!
    }
    
    func write(to database: FMDatabase, id: Int) throws {
        try Meaning.write(items: meanings, to: database, id: id)
        try Reading.write(items: readings, to: database, id: id)
        try SubjectComponent.write(items: componentSubjectIDs, to: database, id: id)
        
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.id.name), \(table.level.name), \(table.createdAt.name), \(table.slug.name), \(table.character.name), \(table.documentURL.name))
        VALUES (?, ?, ?, ?, ?, ?)
        """
        
        let values: [Any] = [
            id, level, createdAt, slug, character, documentURL.absoluteString
        ]
        try database.executeUpdate(query, values: values)
        
        try SubjectSearch.write(to: database, id: id, character: character, meanings: meanings, readings: readings)
    }
}
