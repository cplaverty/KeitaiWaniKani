//
//  SRSItemCounts.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public struct SRSItemCounts: Equatable {
    public static var zero: SRSItemCounts {
        return SRSItemCounts(radicals: 0, kanji: 0, vocabulary: 0)
    }
    
    public let radicals: Int
    public let kanji: Int
    public let vocabulary: Int
    public let total: Int
    
    public init(radicals: Int, kanji: Int, vocabulary: Int, total: Int? = nil) {
        self.radicals = radicals
        self.kanji = kanji
        self.vocabulary = vocabulary
        self.total = total ?? (radicals + kanji + vocabulary)
    }
}

public func ==(lhs: SRSItemCounts, rhs: SRSItemCounts) -> Bool {
    return lhs.radicals == rhs.radicals &&
        lhs.kanji == rhs.kanji &&
        lhs.vocabulary == rhs.vocabulary &&
        lhs.total == rhs.total
}
