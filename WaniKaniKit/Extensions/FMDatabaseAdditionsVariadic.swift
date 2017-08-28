//
//  FMDatabaseAdditionsVariadic.swift
//  FMDB
//

import Foundation
import FMDB

extension FMDatabase {
    
    /// Private generic function used for the variadic renditions of the FMDatabaseAdditions methods
    ///
    /// :param: sql The SQL statement to be used.
    /// :param: values The NSArray of the arguments to be bound to the ? placeholders in the SQL.
    /// :param: completionHandler The closure to be used to call the appropriate FMDatabase method to return the desired value.
    ///
    /// :returns: This returns the T value if value is found. Returns nil if column is NULL or upon error.
    
    private func valueForQuery<T>(_ sql: String, values: [Any]?, completionHandler: (FMResultSet) -> T?) throws -> T? {
        var result: T?
        
        let rs = try executeQuery(sql, values: values)
        defer { rs.close() }
        
        if rs.next() && !rs.columnIndexIsNull(0) {
            result = completionHandler(rs)
        }
        
        return result
    }
    
    /// This is a rendition of stringForQuery that handles Swift variadic parameters
    /// for the values to be bound to the ? placeholders in the SQL.
    ///
    /// :param: sql The SQL statement to be used.
    /// :param: values The values to be bound to the ? placeholders
    ///
    /// :returns: This returns string value if value is found. Returns nil if column is NULL or upon error.
    
    func stringForQuery(_ sql: String, values: [Any]? = nil) throws -> String? {
        return try valueForQuery(sql, values: values) { $0.string(forColumnIndex: 0) }
    }
    
    /// This is a rendition of intForQuery that handles Swift variadic parameters
    /// for the values to be bound to the ? placeholders in the SQL.
    ///
    /// :param: sql The SQL statement to be used.
    /// :param: values The values to be bound to the ? placeholders
    ///
    /// :returns: This returns integer value if value is found. Returns nil if column is NULL or upon error.
    
    func intForQuery(_ sql: String, values: [Any]? = nil) throws -> Int32? {
        return try valueForQuery(sql, values: values) { $0.int(forColumnIndex: 0) }
    }
    
    /// This is a rendition of longForQuery that handles Swift variadic parameters
    /// for the values to be bound to the ? placeholders in the SQL.
    ///
    /// :param: sql The SQL statement to be used.
    /// :param: values The values to be bound to the ? placeholders
    ///
    /// :returns: This returns long value if value is found. Returns nil if column is NULL or upon error.
    
    func longForQuery(_ sql: String, values: [Any]? = nil) throws -> Int? {
        return try valueForQuery(sql, values: values) { $0.long(forColumnIndex: 0) }
    }
    
    /// This is a rendition of boolForQuery that handles Swift variadic parameters
    /// for the values to be bound to the ? placeholders in the SQL.
    ///
    /// :param: sql The SQL statement to be used.
    /// :param: values The values to be bound to the ? placeholders
    ///
    /// :returns: This returns Bool value if value is found. Returns nil if column is NULL or upon error.
    
    func boolForQuery(_ sql: String, values: [Any]? = nil) throws -> Bool? {
        return try valueForQuery(sql, values: values) { $0.bool(forColumnIndex: 0) }
    }
    
    /// This is a rendition of doubleForQuery that handles Swift variadic parameters
    /// for the values to be bound to the ? placeholders in the SQL.
    ///
    /// :param: sql The SQL statement to be used.
    /// :param: values The values to be bound to the ? placeholders
    ///
    /// :returns: This returns Double value if value is found. Returns nil if column is NULL or upon error.
    
    func doubleForQuery(_ sql: String, values: [Any]? = nil) throws -> Double? {
        return try valueForQuery(sql, values: values) { $0.double(forColumnIndex: 0) }
    }
    
    /// This is a rendition of dateForQuery that handles Swift variadic parameters
    /// for the values to be bound to the ? placeholders in the SQL.
    ///
    /// :param: sql The SQL statement to be used.
    /// :param: values The values to be bound to the ? placeholders
    ///
    /// :returns: This returns NSDate value if value is found. Returns nil if column is NULL or upon error.
    
    func dateForQuery(_ sql: String, values: [Any]? = nil) throws -> Date? {
        return try valueForQuery(sql, values: values) { $0.date(forColumnIndex: 0) }
    }
    
    /// This is a rendition of dataForQuery that handles Swift variadic parameters
    /// for the values to be bound to the ? placeholders in the SQL.
    ///
    /// :param: sql The SQL statement to be used.
    /// :param: values The values to be bound to the ? placeholders
    ///
    /// :returns: This returns NSData value if value is found. Returns nil if column is NULL or upon error.
    
    func dataForQuery(_ sql: String, values: [Any]? = nil) throws -> Data? {
        return try valueForQuery(sql, values: values) { $0.data(forColumnIndex: 0) }
    }
    
}
