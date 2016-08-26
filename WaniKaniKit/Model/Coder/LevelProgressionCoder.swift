//
//  LevelProgressionCoder.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import CocoaLumberjack
import FMDB
import SwiftyJSON

public extension LevelProgression {
    static let coder = LevelProgressionCoder()
}

public final class LevelProgressionCoder: ResourceHandler, JSONDecoder, SingleItemDatabaseCoder {
    private struct Columns {
        static let radicalsProgress = "radicals_progress"
        static let radicalsTotal = "radicals_total"
        static let kanjiProgress = "kanji_progress"
        static let kanjiTotal = "kanji_total"
        static let lastUpdateTimestamp = "last_update_timestamp"
    }
    
    // MARK: - ResourceHandler
    
    public var resource: Resource { return .levelProgression }
    
    // MARK: - JSONDecoder
    
    public func load(from json: JSON) -> LevelProgression? {
        return LevelProgression(radicalsProgress: json[Columns.radicalsProgress].intValue,
                                radicalsTotal: json[Columns.radicalsTotal].intValue,
                                kanjiProgress: json[Columns.kanjiProgress].intValue,
                                kanjiTotal: json[Columns.kanjiTotal].intValue)
    }
    
    // MARK: - DatabaseCoder
    
    static let tableName = "level_progression"
    
    var columnDefinitions: String {
        return "\(Columns.radicalsProgress) INT NOT NULL, " +
            "\(Columns.radicalsTotal) INT NOT NULL, " +
            "\(Columns.kanjiProgress) INT NOT NULL, " +
            "\(Columns.kanjiTotal) INT NOT NULL, " +
            "\(Columns.lastUpdateTimestamp) INT NOT NULL"
    }
    
    var columnNameList: [String] {
        return [Columns.radicalsProgress, Columns.radicalsTotal, Columns.kanjiProgress, Columns.kanjiTotal, Columns.lastUpdateTimestamp]
    }
    
    lazy var columnNames: String = { self.columnNameList.joined(separator: ",") }()
    
    lazy var columnCount: Int = { self.columnNameList.count }()
    
    public func createTable(in database: FMDatabase, dropExisting: Bool) throws {
        if dropExisting {
            try database.executeUpdate("DROP TABLE IF EXISTS \(type(of: self).tableName)")
        }
        
        try database.executeUpdate("CREATE TABLE IF NOT EXISTS \(type(of: self).tableName)(\(columnDefinitions))")
    }
    
    public func load(from database: FMDatabase) throws -> LevelProgression? {
        let resultSet = try database.executeQuery("SELECT \(columnNames) FROM \(type(of: self).tableName)")
        defer { resultSet.close() }
        
        var result: LevelProgression? = nil
        if resultSet.next() {
            result = LevelProgression(radicalsProgress: resultSet.long(forColumn: Columns.radicalsProgress),
                                      radicalsTotal: resultSet.long(forColumn: Columns.radicalsTotal),
                                      kanjiProgress: resultSet.long(forColumn: Columns.kanjiProgress),
                                      kanjiTotal: resultSet.long(forColumn: Columns.kanjiTotal),
                                      lastUpdateTimestamp: resultSet.date(forColumn: Columns.lastUpdateTimestamp))
        }
        
        return result
    }
    
    private lazy var updateSQL: String = {
        let columnValuePlaceholders = self.createColumnValuePlaceholders(self.columnCount)
        return "INSERT INTO \(type(of: self).tableName)(\(self.columnNames)) VALUES (\(columnValuePlaceholders))"
    }()
    
    public func save(_ model: LevelProgression, to database: FMDatabase) throws {
        try database.executeUpdate("DELETE FROM \(type(of: self).tableName)")
        
        let columnValues: [AnyObject] = [
            model.radicalsProgress as NSNumber,
            model.radicalsTotal as NSNumber,
            model.kanjiProgress as NSNumber,
            model.kanjiTotal as NSNumber,
            model.lastUpdateTimestamp as NSDate
        ]
        
        try database.executeUpdate(updateSQL, values: columnValues)
    }
    
    public func hasBeenUpdated(since: Date, in database: FMDatabase) throws -> Bool {
        guard let earliestDate = try database.dateForQuery("SELECT MIN(\(Columns.lastUpdateTimestamp)) FROM \(type(of: self).tableName)") else {
            return false
        }
        
        return earliestDate >= since
    }
}
