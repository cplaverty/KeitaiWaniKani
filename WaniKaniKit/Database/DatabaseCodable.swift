//
//  DatabaseCodable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB

protocol DatabaseWriteable {
    func write(to database: FMDatabase, id: Int) throws
}

protocol DatabaseReadable {
    init(from database: FMDatabase, id: Int) throws
}

typealias DatabaseCodable = DatabaseWriteable & DatabaseReadable

protocol BulkDatabaseWriteable {
    associatedtype Element
    static func write(items: [Element], to database: FMDatabase, id: Int) throws
}

protocol BulkDatabaseReadable {
    associatedtype Element
    static func read(from database: FMDatabase, id: Int) throws -> [Element]
}

typealias BulkDatabaseCodable = BulkDatabaseWriteable & BulkDatabaseReadable

enum DatabaseError: Error {
    case itemNotFound(id: Int)
}
