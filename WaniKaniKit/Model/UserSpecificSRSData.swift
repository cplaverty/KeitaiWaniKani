//
//  UserSpecificSRSData.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public enum SRSLevel: String {
    case Apprentice = "apprentice"
    case Guru = "guru"
    case Master = "master"
    case Enlightened = "enlighten"
    case Burned = "burned"
    
    public var numericLevelThreshold: Int {
        switch self {
        case Apprentice: return 1
        case Guru: return 5
        case Master: return 7
        case Enlightened: return 8
        case Burned: return 9
        }
    }
}

public struct ItemStats: Equatable {
    public let correctCount: Int?
    public let incorrectCount: Int?
    public let maxStreakLength: Int?
    public let currentStreakLength: Int?
    
    public init?(correctCount: Int? = nil, incorrectCount: Int? = nil, maxStreakLength: Int? = nil, currentStreakLength: Int? = nil) {
        if correctCount == nil && incorrectCount == nil && maxStreakLength == nil && currentStreakLength == nil {
            return nil
        }
        
        self.correctCount = correctCount
        self.incorrectCount = incorrectCount
        self.maxStreakLength = maxStreakLength
        self.currentStreakLength = currentStreakLength
    }
}

public func ==(lhs: ItemStats, rhs: ItemStats) -> Bool {
    return lhs.correctCount == rhs.correctCount &&
        lhs.incorrectCount == rhs.incorrectCount &&
        lhs.maxStreakLength == rhs.maxStreakLength &&
        lhs.currentStreakLength == rhs.currentStreakLength
}

public struct UserSpecificSRSData: Equatable {
    public let srsLevel: SRSLevel
    public let srsLevelNumeric: Int
    public let dateUnlocked: NSDate?
    public let dateAvailable: NSDate?
    public let burned: Bool
    public let dateBurned: NSDate?
    public let meaningStats: ItemStats?
    public let readingStats: ItemStats?
    public let meaningNote: String?
    public let readingNote: String?
    public let userSynonyms: [String]?
    
    public init(srsLevel: SRSLevel, srsLevelNumeric: Int, dateUnlocked: NSDate? = nil, dateAvailable: NSDate? = nil, burned: Bool, dateBurned: NSDate? = nil, meaningStats: ItemStats? = nil, readingStats: ItemStats? = nil, meaningNote: String? = nil, readingNote: String? = nil, userSynonyms: [String]? = nil) {
        self.srsLevel = srsLevel
        self.srsLevelNumeric = srsLevelNumeric
        self.dateUnlocked = dateUnlocked
        self.dateAvailable = dateAvailable
        self.burned = burned
        self.dateBurned = dateBurned
        self.meaningStats = meaningStats
        self.readingStats = readingStats
        self.meaningNote = meaningNote
        self.readingNote = readingNote
        self.userSynonyms = userSynonyms
    }
}

public func ==(lhs: UserSpecificSRSData, rhs: UserSpecificSRSData) -> Bool {
    func compareOptionalArray(a: [String]?, to b: [String]?) -> Bool {
        if a == nil && b == nil {
            return true
        }
        if let aa = a, let bb = b {
            return aa == bb
        }
        return false
    }
    
    return lhs.srsLevel == rhs.srsLevel &&
        lhs.srsLevelNumeric == rhs.srsLevelNumeric &&
        lhs.dateUnlocked == rhs.dateUnlocked &&
        lhs.dateAvailable == rhs.dateAvailable &&
        lhs.burned == rhs.burned &&
        lhs.dateBurned == rhs.dateBurned &&
        lhs.meaningStats == rhs.meaningStats &&
        lhs.readingStats == rhs.readingStats &&
        lhs.meaningNote == rhs.meaningNote &&
        lhs.readingNote == rhs.readingNote &&
        // The line below makes the entire statement fail to compile.  Compiler bug?
//        lhs.userSynonyms == rhs.userSynonyms
        // Use nested comparison function for now
        compareOptionalArray(lhs.userSynonyms, to: rhs.userSynonyms)
}
