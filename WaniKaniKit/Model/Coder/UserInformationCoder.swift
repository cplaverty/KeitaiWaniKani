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
    
    public var resource: Resource { return .userInformation }
    
    // MARK: - JSONDecoder
    
    public func load(from json: JSON) -> UserInformation? {
        guard
            let username = json[Columns.username].string,
            let level = json[Columns.level].int else {
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
    
    lazy var columnNames: String = { self.columnNameList.joined(separator: ",") }()
    
    lazy var columnCount: Int = { self.columnNameList.count }()
    
    public func createTable(in database: FMDatabase, dropExisting: Bool) throws {
        if dropExisting {
            try database.executeUpdate("DROP TABLE IF EXISTS \(type(of: self).tableName)")
        }
        
        try database.executeUpdate("CREATE TABLE IF NOT EXISTS \(type(of: self).tableName)(\(columnDefinitions))")
    }
    
    public func load(from database: FMDatabase) throws -> UserInformation? {
        let resultSet = try database.executeQuery("SELECT \(columnNames) FROM \(type(of: self).tableName)")
        defer { resultSet.close() }
        
        var result: UserInformation? = nil
        if resultSet.next() {
            result = UserInformation(username: resultSet.string(forColumn: Columns.username)!,
                                     gravatar: resultSet.string(forColumn: Columns.gravatar)!,
                                     level: resultSet.long(forColumn: Columns.level),
                                     title: resultSet.string(forColumn: Columns.title)!,
                                     about: resultSet.string(forColumn: Columns.about),
                                     website: resultSet.string(forColumn: Columns.website),
                                     twitter: resultSet.string(forColumn: Columns.twitter),
                                     topicsCount: resultSet.long(forColumn: Columns.topicsCount),
                                     postsCount: resultSet.long(forColumn: Columns.postsCount),
                                     creationDate: resultSet.date(forColumn: Columns.creationDate)!,
                                     vacationDate: resultSet.date(forColumn: Columns.vacationDate),
                                     lastUpdateTimestamp: resultSet.date(forColumn: Columns.lastUpdateTimestamp))
        }
        
        return result
    }
    
    private lazy var updateSQL: String = {
        let columnValuePlaceholders = self.createColumnValuePlaceholders(self.columnCount)
        return "INSERT INTO \(type(of: self).tableName)(\(self.columnNames)) VALUES (\(columnValuePlaceholders))"
    }()
    
    public func save(_ model: UserInformation, to database: FMDatabase) throws {
        try database.executeUpdate("DELETE FROM \(type(of: self).tableName)")
        
        let columnValues: [AnyObject] = [
            model.username as NSString,
            model.gravatar as NSString,
            model.level as NSNumber,
            model.title as NSString,
            model.about as NSString? ?? NSNull(),
            model.website as NSString? ?? NSNull(),
            model.twitter as NSString? ?? NSNull(),
            model.topicsCount as NSNumber,
            model.postsCount as NSNumber,
            model.creationDate as NSDate,
            model.vacationDate as NSDate? ?? NSNull(),
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
