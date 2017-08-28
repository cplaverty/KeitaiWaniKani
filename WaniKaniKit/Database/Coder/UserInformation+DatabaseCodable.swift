//
//  UserInformation+DatabaseCodable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB

private let table = Tables.userInformation

extension UserInformation {
    init?(from database: FMDatabase) throws {
        let query = """
        SELECT \(table.username), \(table.level), \(table.startedAt), \(table.isSubscribed), \(table.profileURL), \(table.currentVacationStartedAt)
        FROM \(table)
        """
        
        let resultSet = try database.executeQuery(query, values: nil)
        defer { resultSet.close() }
        
        guard resultSet.next() else {
            return nil
        }
        
        self.username = resultSet.string(forColumn: table.username.name)!
        self.level = resultSet.long(forColumn: table.level.name)
        self.startedAt = resultSet.date(forColumn: table.startedAt.name)!
        self.isSubscribed = resultSet.bool(forColumn: table.isSubscribed.name)
        self.profileURL = resultSet.url(forColumn: table.profileURL.name)
        self.currentVacationStartedAt = resultSet.date(forColumn: table.currentVacationStartedAt.name)
    }
    
    func write(to database: FMDatabase) throws {
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.username.name), \(table.level.name), \(table.startedAt.name), \(table.isSubscribed.name), \(table.profileURL.name), \(table.currentVacationStartedAt.name))
        VALUES (?, ?, ?, ?, ?, ?)
        """
        
        let values: [Any] = [
            username, level, startedAt, isSubscribed,
            profileURL?.absoluteString as Any, currentVacationStartedAt as Any
        ]
        try database.executeUpdate(query, values: values)
    }
}
