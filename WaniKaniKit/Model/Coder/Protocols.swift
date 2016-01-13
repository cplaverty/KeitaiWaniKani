//
//  Protocols.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import FMDB
import SwiftyJSON

public protocol ResourceHandler {
    var resource: Resource { get }
}

public protocol JSONDecoder {
    typealias ModelObject: Equatable
    
    func loadFromJSON(json: JSON) -> ModelObject?
}

public protocol DatabaseCoder {
    func createTable(database: FMDatabase, dropFirst: Bool) throws
    func hasBeenUpdatedSince(since: NSDate, inDatabase database: FMDatabase) throws -> Bool
}

public protocol SingleItemDatabaseCoder: DatabaseCoder {
    typealias ModelObject: Equatable
    
    func loadFromDatabase(database: FMDatabase) throws -> ModelObject?
    func save(models: ModelObject, toDatabase database: FMDatabase) throws
}

public protocol ListItemDatabaseCoder: DatabaseCoder {
    typealias ModelObject: SRSDataItem, Equatable
    
    func loadFromDatabase(database: FMDatabase) throws -> [ModelObject]
    func save(models: [ModelObject], toDatabase database: FMDatabase) throws
    
    func levelsNotUpdatedSince(since: NSDate, inDatabase database: FMDatabase) throws -> Set<Int>
    func maxLevel(database: FMDatabase) -> Int
    func lessonsOutstanding(database: FMDatabase) throws -> [ModelObject]
    func reviewsDueBefore(date: NSDate, database: FMDatabase) throws -> [ModelObject]
}

extension DatabaseCoder {
    func createColumnValuePlaceholders(count: Int) -> String {
        guard count > 0 else {
            return ""
        }
        
        var columnValuePlaceholders = "?"
        columnValuePlaceholders.reserveCapacity(count * 2 - 1)
        
        for _ in 1..<count {
            columnValuePlaceholders.appendContentsOf(",?")
        }
        
        return columnValuePlaceholders
    }
}
