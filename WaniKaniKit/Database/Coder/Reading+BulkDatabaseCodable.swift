//
//  Reading+BulkDatabaseCodable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB

private let table = Tables.readings

extension Reading: BulkDatabaseCodable {
    static func read(from database: FMDatabase, id: Int) throws -> [Reading] {
        let query = """
        SELECT \(table.readingType), \(table.reading), \(table.isPrimary)
        FROM \(table)
        WHERE \(table.subjectID) = ?
        ORDER BY \(table.index)
        """
        
        let resultSet = try database.executeQuery(query, values: [id])
        defer { resultSet.close() }
        
        var items = [Reading]()
        while resultSet.next() {
            items.append(Reading(type: resultSet.string(forColumn: table.readingType.name),
                                 reading: resultSet.string(forColumn: table.reading.name)!,
                                 isPrimary: resultSet.bool(forColumn: table.isPrimary.name)))
        }
        
        return items
    }
    
    static func read(from database: FMDatabase, ids: [Int]) throws -> [Int: [Reading]] {
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
        SELECT \(table.subjectID), \(table.readingType), \(table.reading), \(table.isPrimary)
        FROM \(table)
        WHERE \(table.subjectID) IN (\(parameterNames.joined(separator: ",")))
        ORDER BY \(table.subjectID), \(table.index)
        """
        
        guard let resultSet = database.executeQuery(query, withParameterDictionary: queryArgs) else {
            throw database.lastError()
        }
        defer { resultSet.close() }
        
        var items = [Int: [Reading]]()
        items.reserveCapacity(ids.count)
        
        while resultSet.next() {
            let subjectID = resultSet.long(forColumn: table.subjectID.name)
            let reading = Reading(type: resultSet.string(forColumn: table.readingType.name),
                                  reading: resultSet.string(forColumn: table.reading.name)!,
                                  isPrimary: resultSet.bool(forColumn: table.isPrimary.name))
            
            items[subjectID, default: []].append(reading)
        }
        
        return items
    }
    
    static func write(items: [Reading], to database: FMDatabase, id: Int) throws {
        try database.executeUpdate("DELETE FROM \(table) WHERE \(table.subjectID) = ?", values: [id])
        
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.subjectID.name), \(table.index.name), \(table.readingType.name), \(table.reading.name), \(table.isPrimary.name))
        VALUES (?, ?, ?, ?, ?)
        """
        
        for (index, item) in items.enumerated() {
            let values: [Any] = [
                id, index, item.type as Any, item.reading, item.isPrimary
            ]
            try database.executeUpdate(query, values: values)
        }
    }
}
