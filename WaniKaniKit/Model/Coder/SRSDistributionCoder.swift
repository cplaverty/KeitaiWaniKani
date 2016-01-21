//
//  SRSDistributionCoder.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import CocoaLumberjack
import FMDB
import SwiftyJSON

public extension SRSDistribution {
    static let coder = SRSDistributionCoder()
}

public final class SRSDistributionCoder: SRSItemCountsItem, ResourceHandler, JSONDecoder, SingleItemDatabaseCoder {
    private struct Columns {
        static let apprentice = "apprentice"
        static let guru = "guru"
        static let master = "master"
        static let enlightened = "enlighten"
        static let burned = "burned"
        static let srsLevel = "srs_level"
        static let lastUpdateTimestamp = "last_update_timestamp"
    }
    
    // MARK: - ResourceHandler
    
    public var resource: Resource { return .SRSDistribution }
    
    // MARK: - JSONDecoder
    
    public func loadFromJSON(json: JSON) -> SRSDistribution? {
        guard let dictionary = json.dictionary else {
            return nil
        }
        
        var countsBySRSLevel = [SRSLevel: SRSItemCounts]()
        for (key, value) in dictionary {
            if let srsLevel = SRSLevel(rawValue: key), itemCounts = SRSItemCounts.coder.loadFromJSON(value) {
                countsBySRSLevel[srsLevel] = itemCounts
            }
        }
        
        return SRSDistribution(countsBySRSLevel: countsBySRSLevel)
    }
    
    // MARK: - DatabaseCoder
    
    static let tableName = "srs_distribution"
    
    override var columnDefinitions: String {
        return "\(Columns.srsLevel) TEXT PRIMARY KEY, " +
            "\(Columns.lastUpdateTimestamp) INT NOT NULL, " +
            super.columnDefinitions
    }
    
    override var columnNameList: [String] {
        return [Columns.srsLevel, Columns.lastUpdateTimestamp] + super.columnNameList
    }
    
    public func createTable(database: FMDatabase, dropFirst: Bool) throws {
        if dropFirst {
            try database.executeUpdate("DROP TABLE IF EXISTS \(self.dynamicType.tableName)")
        }
        
        try database.executeUpdate("CREATE TABLE IF NOT EXISTS \(self.dynamicType.tableName)(\(columnDefinitions))")
    }
    
    public func loadFromDatabase(database: FMDatabase) throws -> SRSDistribution? {
        let resultSet = try database.executeQuery("SELECT \(columnNames) FROM \(self.dynamicType.tableName)")
        defer { resultSet.close() }
        
        var countsBySRSLevel = [SRSLevel: SRSItemCounts]()
        var lastUpdateTimestamp: NSDate?
        
        while resultSet.next() {
            let srsLevelRawValue = resultSet.stringForColumn(Columns.srsLevel)
            guard let srsLevel = SRSLevel(rawValue: srsLevelRawValue) else {
                DDLogWarn("When creating SRSDistribution, ignoring unrecognised SRS level '\(srsLevelRawValue)'")
                continue
            }
            let srsItemCounts = try loadSRSItemCountsForRow(resultSet)
            countsBySRSLevel[srsLevel] = srsItemCounts
            lastUpdateTimestamp = resultSet.dateForColumn(Columns.lastUpdateTimestamp).laterDateIfNotNil(lastUpdateTimestamp)
        }
        
        return SRSDistribution(countsBySRSLevel: countsBySRSLevel, lastUpdateTimestamp: lastUpdateTimestamp)
    }
    
    private lazy var updateSQL: String = {
        let columnValuePlaceholders = self.createColumnValuePlaceholders(self.columnCount)
        return "INSERT INTO \(self.dynamicType.tableName)(\(self.columnNames)) VALUES (\(columnValuePlaceholders))"
    }()
    
    public func save(model: SRSDistribution, toDatabase database: FMDatabase) throws {
        try database.executeUpdate("DELETE FROM \(self.dynamicType.tableName)")
        
        for (srsLevel, srsItemCounts) in model.countsBySRSLevel {
            let columnValues: [AnyObject] = [srsLevel.rawValue, model.lastUpdateTimestamp] + srsItemCountsColumnValues(srsItemCounts)
            
            try database.executeUpdate(updateSQL, values: columnValues)
        }
    }
    
    public func hasBeenUpdatedSince(since: NSDate, inDatabase database: FMDatabase) throws -> Bool {
        guard let earliestDate = try database.dateForQuery("SELECT MIN(\(Columns.lastUpdateTimestamp)) FROM \(self.dynamicType.tableName)") else {
            return false
        }
        
        return earliestDate >= since
    }
}

private extension NSDate {
    func laterDateIfNotNil(anotherDate: NSDate?) -> NSDate {
        guard let anotherDate = anotherDate else {
            return self
        }
        return self.laterDate(anotherDate)
    }
}