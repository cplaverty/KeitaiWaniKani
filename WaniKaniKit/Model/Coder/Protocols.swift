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
    associatedtype ModelObject: Equatable
    
    func load(from: JSON) -> ModelObject?
}

public protocol DatabaseCoder {
    func createTable(in: FMDatabase, dropExisting: Bool) throws
    func hasBeenUpdated(since: Date, in: FMDatabase) throws -> Bool
}

public protocol SingleItemDatabaseCoder: DatabaseCoder {
    associatedtype ModelObject: Equatable
    
    func load(from: FMDatabase) throws -> ModelObject?
    func save(_: ModelObject, to: FMDatabase) throws
}

public protocol ListItemDatabaseCoder: DatabaseCoder {
    associatedtype ModelObject: SRSDataItem, Equatable
    
    func load(from: FMDatabase) throws -> [ModelObject]
    func save(_: [ModelObject], to: FMDatabase) throws
    
    func levelsNotUpdated(since: Date, in: FMDatabase) throws -> Set<Int>
    func maxLevel(in: FMDatabase) throws -> Int
    func possiblyStaleLevels(since: Date, in: FMDatabase) throws -> Set<Int>
}

extension DatabaseCoder {
    func createColumnValuePlaceholders(_ count: Int) -> String {
        guard count > 0 else {
            return ""
        }
        
        var columnValuePlaceholders = "?"
        columnValuePlaceholders.reserveCapacity(count * 2 - 1)
        
        for _ in 1..<count {
            columnValuePlaceholders.append(",?")
        }
        
        return columnValuePlaceholders
    }
}
