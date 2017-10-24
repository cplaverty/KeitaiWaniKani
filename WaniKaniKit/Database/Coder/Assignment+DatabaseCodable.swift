//
//  Assignment+DatabaseCodable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB

private let table = Tables.assignments

extension Assignment: DatabaseCodable {
    static func read(from database: FMDatabase, ids: [Int]) throws -> [Int: Assignment] {
        var items = [Int: Assignment]()
        items.reserveCapacity(ids.count)
        
        for id in ids {
            items[id] = try Assignment(from: database, id: id)
        }
        
        return items
    }
    
    static func read(from database: FMDatabase, subjectIDs: [Int]) throws -> [Int: Assignment] {
        var items = [Int: Assignment]()
        items.reserveCapacity(subjectIDs.count)
        
        for subjectID in subjectIDs {
            guard let assignment = try Assignment(from: database, subjectID: subjectID) else {
                continue
            }
            
            items[subjectID] = assignment
        }
        
        return items
    }
    
    static func read(from database: FMDatabase, level: Int? = nil, srsStage: SRSStage? = nil) throws -> [Int: Assignment] {
        var filterCriteria = [String]()
        var queryArgs = [String: Any]()
        
        if let level = level {
            filterCriteria.append("\(table.level) = :level")
            queryArgs["level"] = level
        }
        
        if let srsStage = srsStage {
            filterCriteria.append("\(table.srsStage) BETWEEN :srsStageLower AND :srsStageUpper")
            queryArgs["srsStageLower"] = srsStage.numericLevelRange.lowerBound
            queryArgs["srsStageUpper"] = srsStage.numericLevelRange.upperBound
        }
        
        let query = """
        SELECT \(table.id), \(table.subjectID), \(table.subjectType), \(table.level), \(table.srsStage), \(table.srsStageName), \(table.unlockedAt), \(table.startedAt), \(table.passedAt), \(table.burnedAt), \(table.availableAt), \(table.isPassed), \(table.isResurrected)
        FROM \(table)
        WHERE \(filterCriteria.joined(separator: "\nAND "))
        """
        
        guard let resultSet = database.executeQuery(query, withParameterDictionary: queryArgs) else {
            throw database.lastError()
        }
        defer { resultSet.close() }
        
        var assignments = [Int: Assignment]()
        
        while resultSet.next() {
            let id = resultSet.long(forColumn: table.id.name)
            assignments[id] = Assignment(from: resultSet)
        }
        
        return assignments
    }
    
    init(from database: FMDatabase, id: Int) throws {
        let query = """
        SELECT \(table.subjectID), \(table.subjectType), \(table.level), \(table.srsStage), \(table.srsStageName), \(table.unlockedAt), \(table.startedAt), \(table.passedAt), \(table.burnedAt), \(table.availableAt), \(table.isPassed), \(table.isResurrected)
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
    
    init?(from database: FMDatabase, subjectID: Int) throws {
        let query = """
        SELECT \(table.subjectID), \(table.subjectType), \(table.level), \(table.srsStage), \(table.srsStageName), \(table.unlockedAt), \(table.startedAt), \(table.passedAt), \(table.burnedAt), \(table.availableAt), \(table.isPassed), \(table.isResurrected)
        FROM \(table)
        WHERE \(table.subjectID) = ?
        """
        
        let resultSet = try database.executeQuery(query, values: [subjectID])
        defer { resultSet.close() }
        
        guard resultSet.next() else {
            return nil
        }
        
        self.init(from: resultSet)
    }
    
    init(from resultSet: FMResultSet) {
        self.subjectID = resultSet.long(forColumn: table.subjectID.name)
        self.subjectType = resultSet.rawValue(SubjectType.self, forColumn: table.subjectType.name)!
        self.level = resultSet.long(forColumn: table.level.name)
        self.srsStage = resultSet.long(forColumn: table.srsStage.name)
        self.srsStageName = resultSet.string(forColumn: table.srsStageName.name)!
        self.unlockedAt = resultSet.date(forColumn: table.unlockedAt.name)
        self.startedAt = resultSet.date(forColumn: table.startedAt.name)
        self.passedAt = resultSet.date(forColumn: table.passedAt.name)
        self.burnedAt = resultSet.date(forColumn: table.burnedAt.name)
        self.availableAt = resultSet.date(forColumn: table.availableAt.name)
        self.isPassed = resultSet.bool(forColumn: table.isPassed.name)
        self.isResurrected = resultSet.bool(forColumn: table.isResurrected.name)
    }
    
    func write(to database: FMDatabase, id: Int) throws {
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.id.name), \(table.subjectID.name), \(table.subjectType.name), \(table.level.name), \(table.srsStage.name), \(table.srsStageName.name), \(table.unlockedAt.name), \(table.startedAt.name), \(table.passedAt.name), \(table.burnedAt.name), \(table.availableAt.name), \(table.isPassed.name), \(table.isResurrected.name))
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        let values: [Any] = [
            id, subjectID, subjectType.rawValue, level, srsStage, srsStageName, unlockedAt as Any, startedAt as Any, passedAt as Any, burnedAt as Any, availableAt as Any, isPassed, isResurrected
        ]
        try database.executeUpdate(query, values: values)
    }
}
