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
        var items = [Int: [Meaning]]()
        items.reserveCapacity(ids.count)
        
        for id in ids {
            items[id] = try read(from: database, id: id)
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
