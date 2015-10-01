//
//  LevelProgression.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public struct LevelProgression: Equatable {
    public let radicalsProgress: Int
    public let radicalsTotal: Int
    public let kanjiProgress: Int
    public let kanjiTotal: Int
    public let lastUpdateTimestamp: NSDate
    
    public var radicalsFractionComplete: Double {
        return Double(radicalsProgress) / Double(radicalsTotal)
    }
    
    public var kanjiFractionComplete: Double {
        return Double(kanjiProgress) / Double(kanjiTotal)
    }
    
    public init(radicalsProgress: Int, radicalsTotal: Int, kanjiProgress: Int, kanjiTotal: Int, lastUpdateTimestamp: NSDate? = nil) {
        self.radicalsProgress = radicalsProgress
        self.radicalsTotal = radicalsTotal
        self.kanjiProgress = kanjiProgress
        self.kanjiTotal = kanjiTotal
        self.lastUpdateTimestamp = lastUpdateTimestamp ?? NSDate()
    }
}

public func ==(lhs: LevelProgression, rhs: LevelProgression) -> Bool {
    return lhs.radicalsProgress == rhs.radicalsProgress &&
        lhs.radicalsTotal == rhs.radicalsTotal &&
        lhs.kanjiProgress == rhs.kanjiProgress &&
        lhs.kanjiTotal == rhs.kanjiTotal
}
