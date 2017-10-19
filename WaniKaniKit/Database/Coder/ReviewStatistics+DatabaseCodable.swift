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
        SELECT \(table.id), \(table.createdAt), \(table.subjectID), \(table.subjectType), \(table.meaningCorrect), \(table.meaningIncorrect), \(table.meaningMaxStreak), \(table.meaningCurrentStreak), \(table.readingCorrect), \(table.readingIncorrect), \(table.readingMaxStreak), \(table.readingCurrentStreak), \(table.percentageCorrect)
        FROM \(table)
        WHERE \(table.id) IN (\(parameterNames.joined(separator: ",")))
        """
        
        guard let resultSet = database.executeQuery(query, withParameterDictionary: queryArgs) else {
            throw database.lastError()
        }
        defer { resultSet.close() }
        
        var items = [Int: ReviewStatistics]()
        items.reserveCapacity(ids.count)
        
        while resultSet.next() {
            let id = resultSet.long(forColumn: table.id.name)
            let createdAt = resultSet.date(forColumn: table.createdAt.name)!
            let subjectID = resultSet.long(forColumn: table.subjectID.name)
            let subjectType = resultSet.rawValue(SubjectType.self, forColumn: table.subjectType.name)!
            let meaningCorrect = resultSet.long(forColumn: table.meaningCorrect.name)
            let meaningIncorrect = resultSet.long(forColumn: table.meaningIncorrect.name)
            let meaningMaxStreak = resultSet.long(forColumn: table.meaningMaxStreak.name)
            let meaningCurrentStreak = resultSet.long(forColumn: table.meaningCurrentStreak.name)
            let readingCorrect = resultSet.long(forColumn: table.readingCorrect.name)
            let readingIncorrect = resultSet.long(forColumn: table.readingIncorrect.name)
            let readingMaxStreak = resultSet.long(forColumn: table.readingMaxStreak.name)
            let readingCurrentStreak = resultSet.long(forColumn: table.readingCurrentStreak.name)
            let percentageCorrect = resultSet.long(forColumn: table.percentageCorrect.name)
            
            items[id] = ReviewStatistics(createdAt: createdAt, subjectID: subjectID, subjectType: subjectType, meaningCorrect: meaningCorrect, meaningIncorrect: meaningIncorrect, meaningMaxStreak: meaningMaxStreak, meaningCurrentStreak: meaningCurrentStreak, readingCorrect: readingCorrect, readingIncorrect: readingIncorrect, readingMaxStreak: readingMaxStreak, readingCurrentStreak: readingCurrentStreak, percentageCorrect: percentageCorrect)
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
