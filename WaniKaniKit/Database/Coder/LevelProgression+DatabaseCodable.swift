//
//  LevelProgression+DatabaseCodable.swift
//  WaniKaniKit
//
//  Created by Chris Laverty on 24/10/2017.
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB

private let table = Tables.levelProgression

extension LevelProgression: DatabaseCodable {
    static func read(from database: FMDatabase, levels: [Int]) throws -> [Int: LevelProgression] {
        var items = [Int: LevelProgression]()
        items.reserveCapacity(levels.count)
        
        for level in levels {
            guard let levelProgression = try LevelProgression(from: database, level: level) else {
                continue
            }
            
            items[level] = levelProgression
        }
        
        return items
    }
    
    init(from database: FMDatabase, id: Int) throws {
        let query = """
        SELECT \(table.level), \(table.createdAt), \(table.unlockedAt), \(table.startedAt), \(table.passedAt), \(table.completedAt), \(table.abandonedAt)
        FROM \(table)
        WHERE \(table.id) = ?
        """
        
        let resultSet = try database.executeQuery(query, values: [id])
        defer { resultSet.close() }
        
        guard resultSet.next() else {
            throw DatabaseError.itemNotFound(id: id)
        }
        
        self.init(from: resultSet)
    }
    
    init?(from database: FMDatabase, level: Int) throws {
        let query = """
        SELECT \(table.level), \(table.createdAt), \(table.unlockedAt), \(table.startedAt), \(table.passedAt), \(table.completedAt), \(table.abandonedAt)
        FROM \(table)
        WHERE \(table.level) = ?
        """
        
        let resultSet = try database.executeQuery(query, values: [level])
        defer { resultSet.close() }
        
        guard resultSet.next() else {
            return nil
        }
        
        self.init(from: resultSet)
    }
    
    init(from resultSet: FMResultSet) {
        self.level = resultSet.long(forColumn: table.level.name)
        self.createdAt = resultSet.date(forColumn: table.createdAt.name)!
        self.unlockedAt = resultSet.date(forColumn: table.unlockedAt.name)
        self.startedAt = resultSet.date(forColumn: table.startedAt.name)
        self.passedAt = resultSet.date(forColumn: table.passedAt.name)
        self.completedAt = resultSet.date(forColumn: table.completedAt.name)
        self.abandonedAt = resultSet.date(forColumn: table.abandonedAt.name)
    }
    
    func write(to database: FMDatabase, id: Int) throws {
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.id.name), \(table.level.name), \(table.createdAt.name), \(table.unlockedAt.name), \(table.startedAt.name), \(table.passedAt.name), \(table.completedAt.name), \(table.abandonedAt.name))
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        let values: [Any] = [
            id, level, createdAt, unlockedAt as Any, startedAt as Any, passedAt as Any, completedAt as Any, abandonedAt as Any
        ]
        try database.executeUpdate(query, values: values)
    }
}
