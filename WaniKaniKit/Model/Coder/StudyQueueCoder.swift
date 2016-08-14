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
    
    public var resource: Resource { return .studyQueue }
    
    // MARK: - JSONDecoder
    
    public func load(from json: JSON) -> StudyQueue? {
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
    
    lazy var columnNames: String = { self.columnNameList.joined(separator: ",") }()
    
    lazy var columnCount: Int = { self.columnNameList.count }()
    
    public func createTable(in database: FMDatabase, dropExisting: Bool) throws {
        if dropExisting {
            try database.executeUpdate("DROP TABLE IF EXISTS \(self.dynamicType.tableName)")
        }
        
        try database.executeUpdate("CREATE TABLE IF NOT EXISTS \(self.dynamicType.tableName)(\(columnDefinitions))")
    }
    
    public func load(from database: FMDatabase) throws -> StudyQueue? {
        let resultSet = try database.executeQuery("SELECT \(columnNames) FROM \(self.dynamicType.tableName)")
        defer { resultSet.close() }
        
        var result: StudyQueue? = nil
        if resultSet.next() {
            result = StudyQueue(lessonsAvailable: resultSet.long(forColumn: Columns.lessonsAvailable),
                                reviewsAvailable: resultSet.long(forColumn: Columns.reviewsAvailable),
                                nextReviewDate: resultSet.date(forColumn: Columns.nextReviewDate),
                                reviewsAvailableNextHour: resultSet.long(forColumn: Columns.reviewsAvailableNextHour),
                                reviewsAvailableNextDay: resultSet.long(forColumn: Columns.reviewsAvailableNextDay),
                                lastUpdateTimestamp: resultSet.date(forColumn: Columns.lastUpdateTimestamp))
        }
        
        return result
    }
    
    private lazy var updateSQL: String = {
        let columnValuePlaceholders = self.createColumnValuePlaceholders(self.columnCount)
        return "INSERT INTO \(self.dynamicType.tableName)(\(self.columnNames)) VALUES (\(columnValuePlaceholders))"
    }()
    
    public func save(_ model: StudyQueue, to database: FMDatabase) throws {
        try database.executeUpdate("DELETE FROM \(self.dynamicType.tableName)")
        
        let columnValues: [AnyObject] = [
            model.lessonsAvailable,
            model.reviewsAvailable,
            model.nextReviewDate ?? NSNull(),
            model.reviewsAvailableNextHour,
            model.reviewsAvailableNextDay,
            model.lastUpdateTimestamp
        ]
        
        try database.executeUpdate(updateSQL, values: columnValues)
    }
    
    public func hasBeenUpdated(since: Date, in database: FMDatabase) throws -> Bool {
        guard let earliestDate = try database.dateForQuery("SELECT MIN(\(Columns.lastUpdateTimestamp)) FROM \(self.dynamicType.tableName)") else {
            return false
        }
        
        return earliestDate >= since
    }
}
