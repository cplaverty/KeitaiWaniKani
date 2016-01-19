//
//  UserInformationCoder.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import CocoaLumberjack
import FMDB
import SwiftyJSON

public extension UserInformation {
    static let coder = UserInformationCoder()
}

public final class UserInformationCoder: ResourceHandler, JSONDecoder, SingleItemDatabaseCoder {
    private struct Columns {
        static let username = "username"
        static let gravatar = "gravatar"
        static let level = "level"
        static let title = "title"
        static let about = "about"
        static let website = "website"
        static let twitter = "twitter"
        static let topicsCount = "topics_count"
        static let postsCount = "posts_count"
        static let creationDate = "creation_date"
        static let vacationDate = "vacation_date"
        static let lastUpdateTimestamp = "last_update_timestamp"
    }
    
    // MARK: - ResourceHandler
    
    public var resource: Resource { return .UserInformation }
    
    // MARK: - JSONDecoder
    
    public func loadFromJSON(json: JSON) -> UserInformation? {
        guard let username = json[Columns.username].string,
            level = json[Columns.level].int
            else {
                return nil
        }
        
        return UserInformation(username: username,
            gravatar: json[Columns.gravatar].stringValue,
            level: level,
            title: json[Columns.title].stringValue,
            about: json[Columns.about].string,
            website: json[Columns.website].string,
            twitter: json[Columns.twitter].string,
            topicsCount: json[Columns.topicsCount].intValue,
            postsCount: json[Columns.postsCount].intValue,
            creationDate: json[Columns.creationDate].dateValue,
            vacationDate: json[Columns.vacationDate].date)
    }
    
    // MARK: - DatabaseCoder
    
    static let tableName = "user_information"
    
    var columnDefinitions: String {
        return "\(Columns.username) TEXT NOT NULL, " +
            "\(Columns.gravatar) TEXT NOT NULL, " +
            "\(Columns.level) INT NOT NULL, " +
            "\(Columns.title) TEXT NOT NULL, " +
            "\(Columns.about) TEXT, " +
            "\(Columns.website) TEXT, " +
            "\(Columns.twitter) TEXT, " +
            "\(Columns.topicsCount) INT NOT NULL, " +
            "\(Columns.postsCount) INT NOT NULL, " +
            "\(Columns.creationDate) INT NOT NULL, " +
            "\(Columns.vacationDate) INT, " +
        "\(Columns.lastUpdateTimestamp) INT NOT NULL"
    }
    
    var columnNameList: [String] {
        return [Columns.username, Columns.gravatar, Columns.level, Columns.title, Columns.about, Columns.website, Columns.twitter, Columns.topicsCount, Columns.postsCount, Columns.creationDate, Columns.vacationDate, Columns.lastUpdateTimestamp]
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
    
    public func loadFromDatabase(database: FMDatabase) throws -> UserInformation? {
        guard let resultSet = database.executeQuery("SELECT \(columnNames) FROM \(self.dynamicType.tableName)") else {
            throw database.lastError()
        }
        defer { resultSet.close() }
        
        var result: UserInformation? = nil
        if resultSet.next() {
            result = UserInformation(username: resultSet.stringForColumn(Columns.username),
                gravatar: resultSet.stringForColumn(Columns.gravatar),
                level: resultSet.longForColumn(Columns.level),
                title: resultSet.stringForColumn(Columns.title),
                about: resultSet.stringForColumn(Columns.about),
                website: resultSet.stringForColumn(Columns.website),
                twitter: resultSet.stringForColumn(Columns.twitter),
                topicsCount: resultSet.longForColumn(Columns.topicsCount),
                postsCount: resultSet.longForColumn(Columns.postsCount),
                creationDate: resultSet.dateForColumn(Columns.creationDate),
                vacationDate: resultSet.dateForColumn(Columns.vacationDate),
                lastUpdateTimestamp: resultSet.dateForColumn(Columns.lastUpdateTimestamp))
        }
        
        assert(!resultSet.next(), "Expected only a single row of data")
        
        return result
    }
    
    private lazy var updateSQL: String = {
        let columnValuePlaceholders = self.createColumnValuePlaceholders(self.columnCount)
        return "INSERT INTO \(self.dynamicType.tableName)(\(self.columnNames)) VALUES (\(columnValuePlaceholders))"
    }()
    
    public func save(model: UserInformation, toDatabase database: FMDatabase) throws {
        guard database.executeUpdate("DELETE FROM \(self.dynamicType.tableName)") else {
            throw database.lastError()
        }
        
        let columnValues: [AnyObject] = [
            model.username,
            model.gravatar,
            model.level,
            model.title,
            model.about ?? NSNull(),
            model.website ?? NSNull(),
            model.twitter ?? NSNull(),
            model.topicsCount,
            model.postsCount,
            model.creationDate,
            model.vacationDate ?? NSNull(),
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
