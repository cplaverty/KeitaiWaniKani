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
        var items = [Int: StudyMaterials]()
        items.reserveCapacity(ids.count)
        
        for id in ids {
            items[id] = try StudyMaterials(from: database, id: id)
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
        var items = [Int: [String]]()
        items.reserveCapacity(ids.count)
        
        for id in ids {
            items[id] = try read(from: database, id: id)
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
