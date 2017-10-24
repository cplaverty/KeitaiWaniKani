//
//  ReviewStatistics+DatabaseCodable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB

private let table = Tables.reviewStatistics

extension ReviewStatistics: DatabaseCodable {
    static func read(from database: FMDatabase, ids: [Int]) throws -> [Int: ReviewStatistics] {
        var items = [Int: ReviewStatistics]()
        items.reserveCapacity(ids.count)
        
        for id in ids {
            items[id] = try ReviewStatistics(from: database, id: id)
        }
        
        return items
    }
    
    init(from database: FMDatabase, id: Int) throws {
        let query = """
        SELECT \(table.createdAt), \(table.subjectID), \(table.subjectType), \(table.meaningCorrect), \(table.meaningIncorrect), \(table.meaningMaxStreak), \(table.meaningCurrentStreak), \(table.readingCorrect), \(table.readingIncorrect), \(table.readingMaxStreak), \(table.readingCurrentStreak), \(table.percentageCorrect)
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
        self.meaningCorrect = resultSet.long(forColumn: table.meaningCorrect.name)
        self.meaningIncorrect = resultSet.long(forColumn: table.meaningIncorrect.name)
        self.meaningMaxStreak = resultSet.long(forColumn: table.meaningMaxStreak.name)
        self.meaningCurrentStreak = resultSet.long(forColumn: table.meaningCurrentStreak.name)
        self.readingCorrect = resultSet.long(forColumn: table.readingCorrect.name)
        self.readingIncorrect = resultSet.long(forColumn: table.readingIncorrect.name)
        self.readingMaxStreak = resultSet.long(forColumn: table.readingMaxStreak.name)
        self.readingCurrentStreak = resultSet.long(forColumn: table.readingCurrentStreak.name)
        self.percentageCorrect = resultSet.long(forColumn: table.percentageCorrect.name)
    }
    
    func write(to database: FMDatabase, id: Int) throws {
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.id.name), \(table.createdAt.name), \(table.subjectID.name), \(table.subjectType.name), \(table.meaningCorrect.name), \(table.meaningIncorrect.name), \(table.meaningMaxStreak.name), \(table.meaningCurrentStreak.name), \(table.readingCorrect.name), \(table.readingIncorrect.name), \(table.readingMaxStreak.name), \(table.readingCurrentStreak.name), \(table.percentageCorrect.name))
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        let values: [Any] = [
            id, createdAt, subjectID, subjectType.rawValue,
            meaningCorrect, meaningIncorrect, meaningMaxStreak, meaningCurrentStreak,
            readingCorrect, readingIncorrect, readingMaxStreak, readingCurrentStreak,
            percentageCorrect
        ]
        try database.executeUpdate(query, values: values)
    }
}
