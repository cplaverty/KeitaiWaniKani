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
    func urlForColumn(_ columnName: String) -> URL? {
        guard let stringValue = string(forColumn: columnName) else {
            return nil
        }
        return URL(string: stringValue)
    }
    
    /** Result set `NSURL` value for column.
     
     @param columnIdx Zero-based index for column.
     
     @return `NSURL` value of the result set's column.
     */
    func urlForColumnIndex(_ columnIdx: Int32) -> URL? {
        guard let stringValue = string(forColumnIndex: columnIdx) else {
            return nil
        }
        return URL(string: stringValue)
    }
    
    /** Result set `long` value for column.
     
     @param columnName `NSString` value of the name of the column.
     
     @return `long` value of the result set's column.
     */
    func longForColumnOptional(_ columnName: String) -> Int? {
        guard !columnIsNull(columnName) else {
            return nil
        }
        return long(forColumn: columnName)
    }
    
    
    /** Result set long value for column.
     
     @param columnIdx Zero-based index for column.
     
     @return `long` value of the result set's column.
     */
    func longForColumnIndexOptional(_ columnIdx: Int32) -> Int? {
        guard !columnIndexIsNull(columnIdx) else {
            return nil
        }
        return long(forColumnIndex: columnIdx)
    }
}

public extension FMDatabaseQueue {
    
    public func withDatabase<T>(_ block: @escaping (FMDatabase) throws -> T) throws -> T {
        var t: T? = nil
        var e: Error? = nil
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
    
    public func withDatabase<T>(_ block: @escaping (FMDatabase) throws -> T?) throws -> T? {
        var t: T? = nil
        var e: Error? = nil
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
