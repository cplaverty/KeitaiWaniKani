//
//  StudyQueueCoder.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import CocoaLumberjack
import FMDB
import SwiftyJSON

public extension StudyQueue {
    static let coder = StudyQueueCoder()
}

public final class StudyQueueCoder: ResourceHandler, JSONDecoder, SingleItemDatabaseCoder {
    private struct Columns {
        static let lessonsAvailable = "lessons_available"
        static let reviewsAvailable = "reviews_available"
        static let nextReviewDate = "next_review_date"
        static let reviewsAvailableNextHour = "reviews_available_next_hour"
        static let reviewsAvailableNextDay = "reviews_available_next_day"
        static let lastUpdateTimestamp = "last_update_timestamp"
    }
    
    // MARK: - ResourceHandler
    
    public var resource: Resource { return .StudyQueue }
    
    // MARK: - JSONDecoder
    
    public func loadFromJSON(json: JSON) -> StudyQueue? {
        return StudyQueue(lessonsAvailable: json[Columns.lessonsAvailable].intValue,
            reviewsAvailable: json[Columns.reviewsAvailable].intValue,
            nextReviewDate: json[Columns.nextReviewDate].date,
            reviewsAvailableNextHour: json[Columns.reviewsAvailableNextHour].intValue,
            reviewsAvailableNextDay: json[Columns.reviewsAvailableNextDay].intValue)
    }
    
    // MARK: - DatabaseCoder
    
    static let tableName = "study_queue"
    
    var columnDefinitions: String {
        return "\(Columns.lessonsAvailable) INT NOT NULL, " +
            "\(Columns.reviewsAvailable) INT NOT NULL, " +
            "\(Columns.nextReviewDate) INT, " +
            "\(Columns.reviewsAvailableNextHour) INT NOT NULL, " +
            "\(Columns.reviewsAvailableNextDay) INT NOT NULL, " +
        "\(Columns.lastUpdateTimestamp) INT NOT NULL"
    }
    
    var columnNameList: [String] {
        return [Columns.lessonsAvailable, Columns.reviewsAvailable, Columns.nextReviewDate, Columns.reviewsAvailableNextHour, Columns.reviewsAvailableNextDay, Columns.lastUpdateTimestamp]
    }
    
    lazy var columnNames: String = { self.columnNameList.joinWithSeparator(",") }()
    
    lazy var columnCount: Int = { self.columnNameList.count }()
    
    public func createTable(database: FMDatabase, dropFirst: Bool) throws {
        if dropFirst {
            guard database.executeUpdate("DROP TABLE IF EXISTS \(self.dynamicType.tableName)") else {
                throw database.lastError()
            }
        }
        
        guard database.executeUpdate("CREATE TABLE IF NOT EXISTS \(self.dynamicType.tableName)(\(columnDefinitions))") else {
            throw database.lastError()
        }
    }
    
    public func loadFromDatabase(database: FMDatabase) throws -> StudyQueue? {
        guard let resultSet = database.executeQuery("SELECT \(columnNames) FROM \(self.dynamicType.tableName)") else {
            throw database.lastError()
        }
        
        var result: StudyQueue? = nil
        if resultSet.next() {
            result = StudyQueue(lessonsAvailable: resultSet.longForColumn(Columns.lessonsAvailable),
                reviewsAvailable: resultSet.longForColumn(Columns.reviewsAvailable),
                nextReviewDate: resultSet.dateForColumn(Columns.nextReviewDate) as NSDate?,
                reviewsAvailableNextHour: resultSet.longForColumn(Columns.reviewsAvailableNextHour),
                reviewsAvailableNextDay: resultSet.longForColumn(Columns.reviewsAvailableNextDay),
                lastUpdateTimestamp: resultSet.dateForColumn(Columns.lastUpdateTimestamp) as NSDate)
        }
        
        assert(!resultSet.next(), "Expected only a single row of data")
        
        return result
    }
    
    private lazy var updateSQL: String = {
        let columnValuePlaceholders = self.createColumnValuePlaceholders(self.columnCount)
        return "INSERT INTO \(self.dynamicType.tableName)(\(self.columnNames)) VALUES (\(columnValuePlaceholders))"
        }()
    
    public func save(model: StudyQueue, toDatabase database: FMDatabase) throws {
        guard database.executeUpdate("DELETE FROM \(self.dynamicType.tableName)") else {
            throw database.lastError()
        }
        
        let columnValues: [AnyObject] = [
            model.lessonsAvailable,
            model.reviewsAvailable,
            model.nextReviewDate ?? NSNull(),
            model.reviewsAvailableNextHour,
            model.reviewsAvailableNextDay,
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
