//
//  Meaning+BulkDatabaseCodable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB

private let table = Tables.meanings

extension Meaning: BulkDatabaseCodable {
    static func read(from database: FMDatabase, id: Int) throws -> [Meaning] {
        let query = """
        SELECT \(table.meaning), \(table.isPrimary)
        FROM \(table)
        WHERE \(table.subjectID) = ?
        ORDER BY \(table.index)
        """
        
        let resultSet = try database.executeQuery(query, values: [id])
        defer { resultSet.close() }
        
        var items = [Meaning]()
        while resultSet.next() {
            items.append(Meaning(meaning: resultSet.string(forColumn: table.meaning.name)!,
                                 isPrimary: resultSet.bool(forColumn: table.isPrimary.name)))
        }
        
        return items
    }
    
    static func read(from database: FMDatabase, ids: [Int]) throws -> [Int: [Meaning]] {
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
        SELECT \(table.subjectID), \(table.meaning), \(table.isPrimary)
        FROM \(table)
        WHERE \(table.subjectID) IN (\(parameterNames.joined(separator: ",")))
        ORDER BY \(table.subjectID), \(table.index)
        """
        
        guard let resultSet = database.executeQuery(query, withParameterDictionary: queryArgs) else {
            throw database.lastError()
        }
        defer { resultSet.close() }
        
        var items = [Int: [Meaning]]()
        items.reserveCapacity(ids.count)
        
        while resultSet.next() {
            let subjectID = resultSet.long(forColumn: table.subjectID.name)
            let meaning = Meaning(meaning: resultSet.string(forColumn: table.meaning.name)!,
                                  isPrimary: resultSet.bool(forColumn: table.isPrimary.name))
            
            items[subjectID, default: []].append(meaning)
        }
        
        return items
    }
    
    static func write(items: [Meaning], to database: FMDatabase, id: Int) throws {
        try database.executeUpdate("DELETE FROM \(table) WHERE \(table.subjectID) = ?", values: [id])
        
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.subjectID.name), \(table.index.name), \(table.meaning.name), \(table.isPrimary.name))
        VALUES (?, ?, ?, ?)
        """
        
        for (index, item) in items.enumerated() {
            let values: [Any] = [
                id, index, item.meaning, item.isPrimary
            ]
            try database.executeUpdate(query, values: values)
        }
    }
}
