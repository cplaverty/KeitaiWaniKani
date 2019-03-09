//
//  SubjectRelation+BulkDatabaseCodable.swift
//  WaniKaniKit
//
//  Copyright © 2018 Chris Laverty. All rights reserved.
//

import FMDB

private let table = Tables.subjectRelations

public enum SubjectRelationType: String {
    case amalgamation = "a"
    case component = "c"
    case visuallySimilar = "v"
}

struct SubjectRelation {
    static func read(from database: FMDatabase, type: SubjectRelationType, id: Int) throws -> [Int] {
        let subjects = Tables.subjectsView
        let userInformation = Tables.userInformation
        
        let query = """
        SELECT \(table.relatedSubjectID)
        FROM \(table)
        WHERE \(table.relationType) = ?
        AND \(table.subjectID) = ?
        ORDER BY \(table.index)
        """
        
        let resultSet = try database.executeQuery(query, values: [type.rawValue, id])
        defer { resultSet.close() }
        
        var items = [Int]()
        while resultSet.next() {
            items.append(resultSet.long(forColumn: table.relatedSubjectID.name))
        }
        
        return items
    }
    
    static func write(items: [Int], to database: FMDatabase, type: SubjectRelationType, id: Int) throws {
        try database.executeUpdate(
            "DELETE FROM \(table) WHERE \(table.relationType.name) = ? AND \(table.subjectID) = ?",
            values: [type.rawValue, id])
        
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.relationType.name), \(table.subjectID.name), \(table.index.name), \(table.relatedSubjectID.name))
        VALUES (?, ?, ?, ?)
        """
        
        for (index, item) in items.enumerated() {
            let values: [Any] = [
                type.rawValue, id, index, item
            ]
            try database.executeUpdate(query, values: values)
        }
    }
}
