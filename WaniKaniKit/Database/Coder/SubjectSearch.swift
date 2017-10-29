//
//  SubjectSearch.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB

private let table = Tables.subjectSearch

struct SubjectSearch {
    static func read(from database: FMDatabase, searchQuery: String, isSubscribed: Bool) throws -> [ResourceCollectionItem] {
        let levelRestriction = isSubscribed ? "" : "AND \(table.level) <= 3"
        
        let query = """
        SELECT \(table.subjectID)
        FROM \(table)
        WHERE \(table.name) MATCH ? \(levelRestriction)
        ORDER BY rank, \(table.subjectID)
        """
        
        let resultSet = try database.executeQuery(query, values: [searchQuery])
        
        var subjectIDs = [Int]()
        while resultSet.next() {
            subjectIDs.append(resultSet.long(forColumnIndex: 0))
        }
        resultSet.close()
        
        return try ResourceCollectionItem.read(from: database, ids: subjectIDs)
    }
    
    static func write(to database: FMDatabase, id: Int, character: String?, level: Int, meanings: [Meaning], readings: [Reading]) throws {
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.subjectID), \(table.character.name), \(table.level.name), \(table.primaryMeanings.name), \(table.primaryReadings.name), \(table.nonprimaryMeanings.name), \(table.nonprimaryReadings.name))
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """
        
        let primaryMeanings = meanings.lazy.filter({ $0.isPrimary }).map({ $0.meaning }).joined(separator: ",")
        let nonprimaryMeanings = meanings.lazy.filter({ !$0.isPrimary }).map({ $0.meaning }).joined(separator: ",")
        let primaryReadings = readings.lazy.filter({ $0.isPrimary }).map({ $0.reading }).joined(separator: ",")
        let nonprimaryReadings = readings.lazy.filter({ !$0.isPrimary }).map({ $0.reading }).joined(separator: ",")
        let values: [Any] = [
            id, character as Any, level, primaryMeanings, primaryReadings, nonprimaryMeanings, nonprimaryReadings
        ]
        try database.executeUpdate(query, values: values)
    }
}
