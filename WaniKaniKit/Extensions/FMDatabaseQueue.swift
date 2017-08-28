//
//  FMDatabaseQueue.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB

extension FMDatabaseQueue {
    func inDatabase<T>(_ block: (FMDatabase) throws -> T) throws -> T {
        var result: T? = nil
        var e: Error? = nil
        do {
            inDatabase { database in
                do {
                    result = try block(database)
                } catch {
                    e = error
                }
            }
        }
        if let e = e { throw e }
        return result!
    }
}
