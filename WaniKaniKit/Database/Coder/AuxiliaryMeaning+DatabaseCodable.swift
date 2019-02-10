//
//  AuxiliaryMeaning+BulkDatabaseCodable.swift
//  WaniKaniKit
//
//  Copyright © 2019 Chris Laverty. All rights reserved.
//

import FMDB

private let table = Tables.auxiliaryMeanings

extension AuxiliaryMeaning: BulkDatabaseCodable {
    static func read(from database: FMDatabase, id: Int) throws -> [AuxiliaryMeaning] {
        let query = """
        SELECT \(table.type), \(table.meaning)
        FROM \(table)
        WHERE \(table.subjectID) = ?
        ORDER BY \(table.index)
        """
        
        let resultSet = try database.executeQuery(query, values: [id])
        defer { resultSet.close() }
        
        var items = [AuxiliaryMeaning]()
        while resultSet.next() {
            items.append(AuxiliaryMeaning(type: resultSet.string(forColumn: table.type.name)!,
                                          meaning: resultSet.string(forColumn: table.meaning.name)!))
        }
        
        return items
    }
    
    static func read(from database: FMDatabase, ids: [Int]) throws -> [Int: [AuxiliaryMeaning]] {
        var items = [Int: [AuxiliaryMeaning]]()
        items.reserveCapacity(ids.count)
        
        for id in ids {
            items[id] = try read(from: database, id: id)
        }
        
        return items
    }
    
    static func write(items: [AuxiliaryMeaning], to database: FMDatabase, id: Int) throws {
        try database.executeUpdate("DELETE FROM \(table) WHERE \(table.subjectID) = ?", values: [id])
        
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.subjectID.name), \(table.index.name), \(table.type.name), \(table.meaning.name))
        VALUES (?, ?, ?, ?)
        """
        
        for (index, item) in items.enumerated() {
            let values: [Any] = [
                id, index, item.type, item.meaning
            ]
            try database.executeUpdate(query, values: values)
        }
    }
}
