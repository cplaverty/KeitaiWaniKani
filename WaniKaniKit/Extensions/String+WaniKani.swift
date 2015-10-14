//
//  String+WaniKani.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public extension String {
    
    // Adapted from http://rosettacode.org/wiki/Levenshtein_distance#C
    public func levenshteinDistanceToString(other: String) -> Int {
        guard self != other else { return 0 }
        guard !self.isEmpty else { return other.characters.count }
        guard !other.isEmpty else { return self.characters.count }
        
        let ls = self.characters.count
        let lt = other.characters.count
        var d: [[Int]] = []
        d.reserveCapacity(ls + 1)
        for _ in 0...ls {
            d.append(Array(count: lt + 1, repeatedValue: -1))
        }
        
        func dist(i: Int, _ j: Int) -> Int {
            guard d[i][j] < 0 else { return d[i][j] }
            
            let x: Int
            if (i == ls) {
                x = lt - j
            } else if (j == lt) {
                x = ls - i
            } else if (self.characters[self.characters.startIndex.advancedBy(i)] == other.characters[other.characters.startIndex.advancedBy(j)]) {
                x = dist(i + 1, j + 1)
            } else {
                x = min(min(dist(i + 1, j + 1), dist(i, j + 1)), dist(i + 1, j)) + 1
            }
            
            d[i][j] = x
            
            return x
        }
        
        return dist(0, 0)
    }
    
}