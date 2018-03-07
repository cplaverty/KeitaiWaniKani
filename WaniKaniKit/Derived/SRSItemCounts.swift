//
//  SRSItemCounts.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct SRSItemCounts: Equatable {
    public static let zero = SRSItemCounts(radicals: 0, kanji: 0, vocabulary: 0)
    
    public let radicals: Int
    public let kanji: Int
    public let vocabulary: Int
    public var total: Int { return radicals + kanji + vocabulary }
    
    public init(radicals: Int, kanji: Int, vocabulary: Int) {
        self.radicals = radicals
        self.kanji = kanji
        self.vocabulary = vocabulary
    }
}

public extension SRSItemCounts {
    public static func +(lhs: SRSItemCounts, rhs: SRSItemCounts) -> SRSItemCounts {
        return SRSItemCounts(radicals: lhs.radicals + rhs.radicals,
                             kanji: lhs.kanji + rhs.kanji,
                             vocabulary: lhs.vocabulary + rhs.vocabulary)
    }
}
