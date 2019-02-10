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
        SELECT \(table.id), \(table.username), \(table.level), \(table.profileURL), \(table.startedAt), \(table.isSubscriptionActive), \(table.subscriptionType), \(table.subscriptionMaxLevelGranted), \(table.subscriptionPeriodEndsAt), \(table.currentVacationStartedAt)
        FROM \(table)
        """
        
        let resultSet = try database.executeQuery(query, values: nil)
        defer { resultSet.close() }
        
        guard resultSet.next() else {
            return nil
        }
        
        self.id = resultSet.string(forColumn: table.id.name)!
        self.username = resultSet.string(forColumn: table.username.name)!
        self.level = resultSet.long(forColumn: table.level.name)
        self.profileURL = resultSet.url(forColumn: table.profileURL.name)!
        self.startedAt = resultSet.date(forColumn: table.startedAt.name)!
        self.subscription = UserInformation.Subscription(isActive: resultSet.bool(forColumn: table.isSubscriptionActive.name),
                                                         type: resultSet.string(forColumn: table.subscriptionType.name)!,
                                                         maxLevelGranted: resultSet.long(forColumn: table.subscriptionMaxLevelGranted.name),
                                                         periodEndsAt: resultSet.date(forColumn: table.subscriptionPeriodEndsAt.name))
        self.currentVacationStartedAt = resultSet.date(forColumn: table.currentVacationStartedAt.name)
    }
    
    func write(to database: FMDatabase) throws {
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.id.name), \(table.username.name), \(table.level.name), \(table.profileURL.name), \(table.startedAt.name), \(table.isSubscriptionActive.name), \(table.subscriptionType.name), \(table.subscriptionMaxLevelGranted.name), \(table.subscriptionPeriodEndsAt.name), \(table.currentVacationStartedAt.name))
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        let values: [Any] = [
            id, username, level, profileURL.absoluteString, startedAt, subscription.isActive, subscription.type, subscription.maxLevelGranted, subscription.periodEndsAt as Any, currentVacationStartedAt as Any
        ]
        try database.executeUpdate(query, values: values)
    }
}
