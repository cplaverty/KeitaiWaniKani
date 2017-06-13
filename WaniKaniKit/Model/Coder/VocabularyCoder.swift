//
//  VocabularyCoder.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import FMDB
import SwiftyJSON

public extension Vocabulary {
    static let coder = VocabularyCoder()
}

public final class VocabularyCoder: SRSDataItemCoder, ResourceHandler, JSONDecoder, ListItemDatabaseCoder {
    
    private struct Columns {
        /// Primary key
        static let character = "character"
        static let meaning = "meaning"
        static let kana = "kana"
        static let level = "level"
        static let userSpecificSRSData = "user_specific"
        static let lastUpdateTimestamp = "last_update_timestamp"
    }
    
    init() {
        super.init(tableName: "vocabulary")
    }
    
    // MARK: - ResourceHandler
    
    public var resource: Resource { return .vocabulary }
    
    // MARK: - JSONDecoder
    
    public func load(from json: JSON) -> Vocabulary? {
        guard
            let character = json[Columns.character].string,
            let level = json[Columns.level].int else {
                return nil
        }
        
        let meaning = json[Columns.meaning].stringValue
        let kana = json[Columns.kana].stringValue
        let userSpecificSRSData = UserSpecificSRSData.coder.load(from: json[Columns.userSpecificSRSData])
        
        return Vocabulary(character: character, meaning: meaning, kana: kana, level: level, userSpecificSRSData: userSpecificSRSData)
    }
    
    // MARK: - DatabaseCoder
    
    override var columnDefinitions: String {
        return "\(Columns.character) TEXT PRIMARY KEY, " +
            "\(Columns.meaning) TEXT NOT NULL, " +
            "\(Columns.kana) TEXT NOT NULL, " +
            "\(Columns.level) INT NOT NULL, " +
            "\(Columns.lastUpdateTimestamp) INT NOT NULL, " +
            super.columnDefinitions
    }
    
    override var columnNameList: [String] {
        return [Columns.character, Columns.meaning, Columns.kana, Columns.level, Columns.lastUpdateTimestamp] + super.columnNameList
    }
    
    public func createTable(in database: FMDatabase, dropExisting: Bool) throws {
        if dropExisting {
            try database.executeUpdate("DROP TABLE IF EXISTS \(tableName)")
        }
        
        let createTable = "CREATE TABLE IF NOT EXISTS \(tableName)(\(columnDefinitions))"
        let indexes = "CREATE INDEX IF NOT EXISTS idx_\(tableName)_lastUpdateTimestamp ON \(tableName) (\(Columns.lastUpdateTimestamp));"
            + "CREATE INDEX IF NOT EXISTS idx_\(tableName)_level ON \(tableName) (\(Columns.level));"
            + srsDataIndices
        guard database.executeStatements("\(createTable); \(indexes)") else {
            throw database.lastError()
        }
    }
    
    public func load(from database: FMDatabase) throws -> [Vocabulary] {
        return try load(from: database, level: nil)
    }
    
    public func load(from database: FMDatabase, level: Int?) throws -> [Vocabulary] {
        var sql = "SELECT \(columnNames) FROM \(tableName)"
        if let level = level {
            sql += " WHERE \(Columns.level) = \(level)"
        }
        
        let resultSet = try database.executeQuery(sql)
        defer { resultSet.close() }
        
        var results = [Vocabulary]()
        while resultSet.next() {
            results.append(try loadModelObjectFromRow(resultSet))
        }
        
        return results
    }
    
    private lazy var updateSQL: String = {
        let columnValuePlaceholders = self.createColumnValuePlaceholders(self.columnCount)
        return "INSERT OR REPLACE INTO \(self.tableName)(\(self.columnNames)) VALUES (\(columnValuePlaceholders))"
    }()
    
    public func save(_ models: [Vocabulary], to database: FMDatabase) throws {
        let maxLevelToKeep = try! UserInformation.coder.load(from: database)?.level ?? 0
        let levelsToReplace = Set(models.map { $0.level }).sorted()
        let deleteSql = "DELETE FROM \(tableName) WHERE \(Columns.level) > ? OR \(Columns.level) IN (\(self.createColumnValuePlaceholders(levelsToReplace.count)))"
        try database.executeUpdate(deleteSql, values: [maxLevelToKeep] + levelsToReplace)
        
        for model in models {
            let columnValues: [AnyObject] = [
                model.character as NSString,
                model.meaning as NSString,
                model.kana as NSString,
                model.level as NSNumber,
                model.lastUpdateTimestamp as NSDate
                ] + srsDataColumnValues(model.userSpecificSRSData)
            
            try database.executeUpdate(updateSQL, values: columnValues)
        }
    }
    
    public func hasBeenUpdated(since: Date, in database: FMDatabase) throws -> Bool {
        guard let earliestDate = try database.dateForQuery("SELECT MIN(\(Columns.lastUpdateTimestamp)) FROM \(tableName)") else {
            return false
        }
        
        return earliestDate >= since
    }
    
    public func levelsNotUpdated(since: Date, in database: FMDatabase) throws -> Set<Int> {
        let sql = "SELECT DISTINCT \(Columns.level) FROM \(tableName) WHERE \(Columns.lastUpdateTimestamp) < ?"
        let resultSet = try database.executeQuery(sql, since as NSDate)
        defer { resultSet.close() }
        
        var results = Set<Int>()
        while resultSet.next() {
            results.insert(resultSet.long(forColumnIndex: 0))
        }
        return results
    }
    
    public func maxLevel(in database: FMDatabase) throws -> Int {
        return try database.longForQuery("SELECT MAX(\(Columns.level)) FROM \(tableName)") ?? 0
    }
    
    public func possiblyStaleLevels(since: Date, in database: FMDatabase) throws -> Set<Int> {
        let sql = "SELECT DISTINCT \(Columns.level) FROM \(tableName) WHERE \(UserSpecificSRSDataColumns.dateAvailable) IS NULL OR (\(UserSpecificSRSDataColumns.dateAvailable) < ? AND \(UserSpecificSRSDataColumns.burned) = 0)"
        let resultSet = try database.executeQuery(sql, since as NSDate)
        defer { resultSet.close() }
        
        var results = Set<Int>()
        while resultSet.next() {
            results.insert(resultSet.long(forColumnIndex: 0))
        }
        return results
    }
    
    private func loadModelObjectFromRow(_ resultSet: FMResultSet) throws -> Vocabulary {
        let srsData = try loadSRSDataForRow(resultSet)
        return Vocabulary(character: resultSet.string(forColumn: Columns.character)!,
                          meaning: resultSet.string(forColumn: Columns.meaning)!,
                          kana: resultSet.string(forColumn: Columns.kana)!,
                          level: resultSet.long(forColumn: Columns.level),
                          userSpecificSRSData: srsData,
                          lastUpdateTimestamp: resultSet.date(forColumn: Columns.lastUpdateTimestamp))
    }
    
}
