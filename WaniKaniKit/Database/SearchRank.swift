//
//  SearchRank.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os
import SQLite3

// Adapted from https://sqlite.org/fts3.html#appendix_a
func calculateRank(pCtx: UnsafeMutableRawPointer, nVal: Int32, apVal: UnsafeMutablePointer<UnsafeMutableRawPointer>) {
    guard nVal > 0 else {
        sqlite3_result_error(OpaquePointer(pCtx), "must supply at least one argument to rank()", -1)
        return
    }
    
    let matchInfo = sqlite3_value_blob(OpaquePointer(apVal[0])).assumingMemoryBound(to: UInt32.self)
    let phraseCount = matchInfo[0]
    let columnCount = matchInfo[1]
    
    guard nVal == columnCount + 1 else {
        sqlite3_result_error(OpaquePointer(pCtx), "must supply a weighting for each column to rank() (expected \(columnCount + 1), got \(nVal)", -1)
        return
    }
    
    var score = 0.0
    
    var hitInfo = matchInfo.advanced(by: 2)
    for phrase in 0..<phraseCount {
        for column in 0..<columnCount {
            let hits = hitInfo[0]
            let totalHits = hitInfo[1]
            
            if hits > 0 {
                let weight = sqlite3_value_double(OpaquePointer(apVal[Int(column) + 1]));
                score += (Double(hits) / Double(totalHits)) * weight
                
                if #available(iOS 10.0, *) {
                    os_log("Found phrase %u in column %u with weight %f, score = %f (%u / %u)", type: .debug, phrase, column, weight, score, hits, totalHits)
                }
            }
            
            hitInfo = hitInfo.advanced(by: 3)
        }
    }
    
    sqlite3_result_double(OpaquePointer(pCtx), score);
}
