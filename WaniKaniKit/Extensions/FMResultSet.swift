//
//  FMResultSet+Types.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB

extension FMResultSet {
    func url(forColumn columnName: String) -> URL? {
        guard let stringValue = string(forColumn: columnName) else {
            return nil
        }
        return URL(string: stringValue)
    }
    
    func url(forColumnIndex columnIdx: Int32) -> URL? {
        guard let stringValue = string(forColumnIndex: columnIdx) else {
            return nil
        }
        return URL(string: stringValue)
    }
    
    func rawValue<T: RawRepresentable>(_ type: T.Type, forColumn columnName: String) -> T? where T.RawValue == String {
        guard let stringValue = string(forColumn: columnName) else {
            return nil
        }
        return type.init(rawValue: stringValue)
    }
    
    func rawValue<T: RawRepresentable>(_ type: T.Type, forColumnIndex columnIdx: Int32) -> T? where T.RawValue == String {
        guard let stringValue = string(forColumnIndex: columnIdx) else {
            return nil
        }
        return type.init(rawValue: stringValue)
    }
}

