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
    
    public var resource: Resource { return .LevelProgression }
    
    // MARK: - JSONDecoder
    
    public func loadFromJSON(json: JSON) -> LevelProgression? {
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
    
    lazy var columnNames: String = { self.columnNameList.joinWithSeparator(",") }()
    
    lazy var columnCount: Int = { self.columnNameList.count }()
    
    public func createTable(database: FMDatabase) throws {
        guard database.executeUpdate("CREATE TABLE IF NOT EXISTS \(self.dynamicType.tableName)(\(columnDefinitions))") else {
            throw database.lastError()
        }
    }
    
    public func loadFromDatabase(database: FMDatabase) throws -> LevelProgression? {
        guard let resultSet = database.executeQuery("SELECT \(columnNames) FROM \(self.dynamicType.tableName)") else {
            throw database.lastError()
        }
        
        var result: LevelProgression? = nil
        while resultSet.next() {
            result = LevelProgression(radicalsProgress: resultSet.longForColumn(Columns.radicalsProgress),
                radicalsTotal: resultSet.longForColumn(Columns.radicalsTotal),
                kanjiProgress: resultSet.longForColumn(Columns.kanjiProgress),
                kanjiTotal: resultSet.longForColumn(Columns.kanjiTotal),
                lastUpdateTimestamp: resultSet.dateForColumn(Columns.lastUpdateTimestamp) as NSDate)
        }
        
        assert(!resultSet.next(), "Expected only a single row of data")
        
        return result
    }
    
    private lazy var updateSQL: String = {
        let columnValuePlaceholders = self.createColumnValuePlaceholders(self.columnCount)
        return "INSERT INTO \(self.dynamicType.tableName)(\(self.columnNames)) VALUES (\(columnValuePlaceholders))"
        }()
    
    public func save(model: LevelProgression, toDatabase database: FMDatabase) throws {
        guard database.executeUpdate("DELETE FROM \(self.dynamicType.tableName)") else {
            throw database.lastError()
        }
        
        let columnValues: [AnyObject] = [
            model.radicalsProgress,
            model.radicalsTotal,
            model.kanjiProgress,
            model.kanjiTotal,
            model.lastUpdateTimestamp
        ]
        
        guard database.executeUpdate(updateSQL, withArgumentsInArray: columnValues) else {
            throw database.lastError()
        }
    }
    
    public func hasBeenUpdatedSince(since: NSDate, inDatabase database: FMDatabase) throws -> Bool {
        guard let earliestDate = database.dateForQuery("SELECT MIN(\(Columns.lastUpdateTimestamp)) FROM \(self.dynamicType.tableName)") else {
            if database.hadError() { throw database.lastError() }
            return false
        }
        
        return earliestDate >= since
    }
}
