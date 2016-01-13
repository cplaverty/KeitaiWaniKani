//
//  RadicalCoder.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import FMDB
import SwiftyJSON

public extension Radical {
    static let coder = RadicalCoder()
}

public final class RadicalCoder: SRSDataItemCoder, ResourceHandler, JSONDecoder, ListItemDatabaseCoder {
    
    private struct Columns {
        static let character = "character"
        /// Primary key
        static let meaning = "meaning"
        static let image = "image"
        static let level = "level"
        static let userSpecificSRSData = "user_specific"
        static let lastUpdateTimestamp = "last_update_timestamp"
    }
    
    init() {
        super.init(tableName: "radicals")
    }
    
    // MARK: - ResourceHandler
    
    public var resource: Resource { return .Radicals }
    
    // MARK: - JSONDecoder
    
    public func loadFromJSON(json: JSON) -> Radical? {
        guard let meaning = json[Columns.meaning].string,
            level = json[Columns.level].int else {
                return nil
        }
        
        let userSpecificSRSData = UserSpecificSRSData.coder.loadFromJSON(json[Columns.userSpecificSRSData])
        
        return Radical(character: json[Columns.character].string,
            meaning: meaning,
            image: json[Columns.image].URL,
            level: level,
            userSpecificSRSData: userSpecificSRSData)
    }
    
    // MARK: - DatabaseCoder
    
    override var columnDefinitions: String {
        return "\(Columns.character) TEXT, " +
            "\(Columns.meaning) TEXT PRIMARY KEY, " +
            "\(Columns.image) TEXT, " +
            "\(Columns.level) INT NOT NULL, " +
            "\(Columns.lastUpdateTimestamp) INT NOT NULL, " +
            super.columnDefinitions
    }
    
    override var columnNameList: [String] {
        return [Columns.character, Columns.meaning, Columns.image, Columns.level, Columns.lastUpdateTimestamp] + super.columnNameList
    }
    
    public func createTable(database: FMDatabase, dropFirst: Bool) throws {
        if dropFirst {
            guard database.executeUpdate("DROP TABLE IF EXISTS \(tableName)") else {
                throw database.lastError()
            }
        }
        
        let createTable = "CREATE TABLE IF NOT EXISTS \(tableName)(\(columnDefinitions))"
        let indexes = "CREATE INDEX IF NOT EXISTS idx_\(tableName)_lastUpdateTimestamp ON \(tableName) (\(Columns.lastUpdateTimestamp));"
            + "CREATE INDEX IF NOT EXISTS idx_\(tableName)_level ON \(tableName) (\(Columns.level));"
            + srsDataIndices
        guard database.executeStatements("\(createTable); \(indexes)") else {
            throw database.lastError()
        }
    }
    
    public func loadFromDatabase(database: FMDatabase) throws -> [Radical] {
        return try loadFromDatabase(database, forLevel: nil)
    }
    
    public func loadFromDatabase(database: FMDatabase, forLevel level: Int?) throws -> [Radical] {
        var sql = "SELECT \(columnNames) FROM \(tableName)"
        if let level = level {
            sql += " WHERE \(Columns.level) = \(level)"
        }
        
        guard let resultSet = database.executeQuery(sql) else {
            throw database.lastError()
        }
        
        var results = [Radical]()
        while resultSet.next() {
            results.append(try loadModelObjectFromRow(resultSet))
        }
        
        return results
    }
    
    private lazy var updateSQL: String = {
        let columnValuePlaceholders = self.createColumnValuePlaceholders(self.columnCount)
        return "INSERT OR REPLACE INTO \(self.tableName)(\(self.columnNames)) VALUES (\(columnValuePlaceholders))"
    }()
    
    public func save(models: [Radical], toDatabase database: FMDatabase) throws {
        let maxLevelToKeep = try! UserInformation.coder.loadFromDatabase(database)?.level ?? 0
        let levelsToReplace = Set(models.map { $0.level }).sort()
        let deleteSql = "DELETE FROM \(tableName) WHERE \(Columns.level) > ? OR \(Columns.level) IN (\(self.createColumnValuePlaceholders(levelsToReplace.count)))"
        guard database.executeUpdate(deleteSql, withArgumentsInArray: [maxLevelToKeep] + levelsToReplace) else {
            throw database.lastError()
        }
        
        for model in models {
            let columnValues: [AnyObject] = [
                model.character ?? NSNull(),
                model.meaning,
                model.image?.absoluteString ?? NSNull(),
                model.level,
                model.lastUpdateTimestamp] + srsDataColumnValues(model.userSpecificSRSData)
            
            guard database.executeUpdate(updateSQL, withArgumentsInArray: columnValues) else {
                throw database.lastError()
            }
        }
    }
    
    public func hasBeenUpdatedSince(since: NSDate, inDatabase database: FMDatabase) throws -> Bool {
        guard let earliestDate = database.dateForQuery("SELECT MIN(\(Columns.lastUpdateTimestamp)) FROM \(tableName)") else {
            if database.hadError() { throw database.lastError() }
            return false
        }
        
        return earliestDate >= since
    }
    
    public func levelsNotUpdatedSince(since: NSDate, inDatabase database: FMDatabase) throws -> Set<Int> {
        let sql = "SELECT DISTINCT \(Columns.level) FROM \(tableName) WHERE \(Columns.lastUpdateTimestamp) < ?"
        guard let resultSet = database.executeQuery(sql, since) else {
            throw database.lastError()
        }
        
        var results = Set<Int>()
        while resultSet.next() {
            results.insert(resultSet.longForColumnIndex(0))
        }
        return results
    }
    
    public func maxLevel(database: FMDatabase) -> Int {
        return database.longForQuery("SELECT MAX(\(Columns.level)) FROM \(tableName)") ?? 0
    }
    
    public func lessonsOutstanding(database: FMDatabase) throws -> [Radical] {
        let sql = "SELECT \(columnNames) FROM \(tableName) WHERE \(UserSpecificSRSDataColumns.dateAvailable) IS NULL"
        guard let resultSet = database.executeQuery(sql) else {
            throw database.lastError()
        }
        
        var results = [Radical]()
        while resultSet.next() {
            results.append(try loadModelObjectFromRow(resultSet))
        }
        
        return results
    }
    
    public func reviewsDueBefore(date: NSDate, database: FMDatabase) throws -> [Radical] {
        let sql = "SELECT \(columnNames) FROM \(tableName) WHERE \(UserSpecificSRSDataColumns.dateAvailable) < ? AND \(UserSpecificSRSDataColumns.burned) = 0"
        guard let resultSet = database.executeQuery(sql, date) else {
            throw database.lastError()
        }
        
        var results = [Radical]()
        while resultSet.next() {
            results.append(try loadModelObjectFromRow(resultSet))
        }
        
        return results
    }
    
    private func loadModelObjectFromRow(resultSet: FMResultSet) throws -> Radical {
        let srsData = try loadSRSDataForRow(resultSet)
        return Radical(character: resultSet.stringForColumn(Columns.character) as String?,
            meaning: resultSet.stringForColumn(Columns.meaning),
            image: resultSet.urlForColumn(Columns.image),
            level: resultSet.longForColumn(Columns.level),
            userSpecificSRSData: srsData,
            lastUpdateTimestamp: resultSet.dateForColumn(Columns.lastUpdateTimestamp))
    }
    
}
