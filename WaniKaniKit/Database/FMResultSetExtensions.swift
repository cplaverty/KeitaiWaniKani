//
//  FMResultSetExtensions.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import FMDB

extension FMResultSet {
    /** Result set `NSURL` value for column.
    
    @param columnName `NSURL` value of the name of the column.
    
    @return `NSURL` value of the result set's column.
    */
    func urlForColumn(columnName: String) -> NSURL? {
        guard let stringValue = stringForColumn(columnName) else {
            return nil
        }
        return NSURL(string: stringValue)
    }
    
    /** Result set `NSURL` value for column.
    
    @param columnIdx Zero-based index for column.
    
    @return `NSURL` value of the result set's column.
    */
    func urlForColumnIndex(columnIdx: Int32) -> NSURL? {
        guard let stringValue = stringForColumnIndex(columnIdx) else {
            return nil
        }
        return NSURL(string: stringValue)
    }

    /** Result set `long` value for column.
    
    @param columnName `NSString` value of the name of the column.
    
    @return `long` value of the result set's column.
    */
    func longForColumnOptional(columnName: String) -> Int? {
        guard !columnIsNull(columnName) else {
            return nil
        }
        return longForColumn(columnName)
    }
    
    
    /** Result set long value for column.
    
    @param columnIdx Zero-based index for column.
    
    @return `long` value of the result set's column.
    */
    func longForColumnIndexOptional(columnIdx: Int32) -> Int? {
        guard !columnIndexIsNull(columnIdx) else {
            return nil
        }
        return longForColumnIndex(columnIdx)
    }
}

public extension FMDatabaseQueue {

    public func withDatabase<T>(block: FMDatabase throws -> T) throws -> T {
        var t: T? = nil
        var e: ErrorType? = nil
        self.inDatabase { database in
            do {
                t = try block(database)
            } catch {
                e = error
            }
        }
        if let e = e { throw e }
        return t!
    }
    
    public func withDatabase<T>(block: FMDatabase throws -> T?) throws -> T? {
        var t: T? = nil
        var e: ErrorType? = nil
        self.inDatabase { database in
            do {
                t = try block(database)
            } catch {
                e = error
            }
        }
        if let e = e { throw e }
        return t
    }
    
}