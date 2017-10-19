//
//  StudyMaterials+DatabaseCodable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB

private let table = Tables.studyMaterials

extension StudyMaterials: DatabaseCodable {
    static func read(from database: FMDatabase, ids: [Int]) throws -> [Int: StudyMaterials] {
        let meaningSynonymsByID = try MeaningSynonym.read(from: database, ids: ids)
        
        var parameterNames = [String]()
        parameterNames.reserveCapacity(ids.count)
        var queryArgs = [String: Any]()
        queryArgs.reserveCapacity(ids.count)
        
        for (index, id) in ids.enumerated() {
            var parameterName = "id_\(index)"
            parameterNames.append(":" + parameterName)
            queryArgs[parameterName] = id
        }
        
        let query = """
        SELECT \(table.id), \(table.createdAt), \(table.subjectID), \(table.subjectType), \(table.meaningNote), \(table.readingNote)
        FROM \(table)
        WHERE \(table.id) IN (\(parameterNames.joined(separator: ",")))
        """
        
        guard let resultSet = database.executeQuery(query, withParameterDictionary: queryArgs) else {
            throw database.lastError()
        }
        defer { resultSet.close() }
        
        var items = [Int: StudyMaterials]()
        items.reserveCapacity(ids.count)
        
        while resultSet.next() {
            let id = resultSet.long(forColumn: table.id.name)
            let createdAt = resultSet.date(forColumn: table.createdAt.name)!
            let subjectID = resultSet.long(forColumn: table.subjectID.name)
            let subjectType = resultSet.rawValue(SubjectType.self, forColumn: table.subjectType.name)!
            let meaningNote = resultSet.string(forColumn: table.meaningNote.name)
            let readingNote = resultSet.string(forColumn: table.readingNote.name)
            let meaningSynonyms = meaningSynonymsByID[id] ?? []
            
            items[id] = StudyMaterials(createdAt: createdAt, subjectID: subjectID, subjectType: subjectType, meaningNote: meaningNote, readingNote: readingNote, meaningSynonyms: meaningSynonyms)
        }
        
        return items
    }
    
    init(from database: FMDatabase, id: Int) throws {
        let meaningSynonyms = try MeaningSynonym.read(from: database, id: id)
        
        let query = """
        SELECT \(table.createdAt), \(table.subjectID), \(table.subjectType), \(table.meaningNote), \(table.readingNote)
        FROM \(table)
        WHERE \(table.id) = ?
        """
        
        let resultSet = try database.executeQuery(query, values: [id])
        defer { resultSet.close() }
        
        guard resultSet.next() else {
            throw DatabaseError.itemNotFound(id: id)
        }
        
        self.createdAt = resultSet.date(forColumn: table.createdAt.name)!
        self.subjectID = resultSet.long(forColumn: table.subjectID.name)
        self.subjectType = resultSet.rawValue(SubjectType.self, forColumn: table.subjectType.name)!
        self.meaningNote = resultSet.string(forColumn: table.meaningNote.name)
        self.readingNote = resultSet.string(forColumn: table.readingNote.name)
        self.meaningSynonyms = meaningSynonyms
    }
    
    func write(to database: FMDatabase, id: Int) throws {
        try MeaningSynonym.write(items: meaningSynonyms, to: database, id: id)
        
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.id.name), \(table.createdAt.name), \(table.subjectID.name), \(table.subjectType.name), \(table.meaningNote.name), \(table.readingNote.name))
        VALUES (?, ?, ?, ?, ?, ?)
        """
        
        let values: [Any] = [
            id, createdAt, subjectID, subjectType.rawValue,
            meaningNote as Any, readingNote as Any
        ]
        try database.executeUpdate(query, values: values)
    }
}

struct MeaningSynonym: BulkDatabaseCodable {
    private static let table = Tables.studyMaterialsMeaningSynonyms
    
    static func read(from database: FMDatabase, ids: [Int]) throws -> [Int: [String]] {
        var parameterNames = [String]()
        parameterNames.reserveCapacity(ids.count)
        var queryArgs = [String: Any]()
        queryArgs.reserveCapacity(ids.count)
        
        for (index, id) in ids.enumerated() {
            var parameterName = "id_\(index)"
            parameterNames.append(":" + parameterName)
            queryArgs[parameterName] = id
        }
        
        let query = """
        SELECT \(table.studyMaterialsID), \(table.synonym)
        FROM \(table)
        WHERE \(table.studyMaterialsID) IN (\(parameterNames.joined(separator: ",")))
        ORDER BY \(table.studyMaterialsID), \(table.index)
        """
        
        guard let resultSet = database.executeQuery(query, withParameterDictionary: queryArgs) else {
            throw database.lastError()
        }
        defer { resultSet.close() }
        
        var items = [Int: [String]]()
        items.reserveCapacity(ids.count)
        
        while resultSet.next() {
            let id = resultSet.long(forColumn: table.studyMaterialsID.name)
            let synonym = resultSet.string(forColumn: table.synonym.name)!
            
            items[id, default: []].append(synonym)
        }
        
        return items
    }
    
    static func read(from database: FMDatabase, id: Int) throws -> [String] {
        let query = """
        SELECT \(table.synonym)
        FROM \(table)
        WHERE \(table.studyMaterialsID) = ?
        ORDER BY \(table.index)
        """
        
        let resultSet = try database.executeQuery(query, values: [id])
        defer { resultSet.close() }
        
        var items = [String]()
        while resultSet.next() {
            items.append(resultSet.string(forColumn: table.synonym.name)!)
        }
        
        return items
    }
    
    static func write(items: [String], to database: FMDatabase, id: Int) throws {
        try database.executeUpdate("DELETE FROM \(table) WHERE \(table.studyMaterialsID) = ?", values: [id])
        
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.studyMaterialsID.name), \(table.index.name), \(table.synonym.name))
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
