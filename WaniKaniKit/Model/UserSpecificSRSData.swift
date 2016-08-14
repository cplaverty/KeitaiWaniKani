//
//  UserSpecificSRSData.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public enum SRSLevel: String {
    case apprentice = "apprentice"
    case guru = "guru"
    case master = "master"
    case enlightened = "enlighten"
    case burned = "burned"
    
    public var numericLevelThreshold: Int {
        switch self {
        case .apprentice: return 1
        case .guru: return 5
        case .master: return 7
        case .enlightened: return 8
        case .burned: return 9
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
    public let dateUnlocked: Date?
    public let dateAvailable: Date?
    public let burned: Bool
    public let dateBurned: Date?
    public let meaningStats: ItemStats?
    public let readingStats: ItemStats?
    public let meaningNote: String?
    public let readingNote: String?
    public let userSynonyms: [String]?
    
    public init(srsLevel: SRSLevel, srsLevelNumeric: Int, dateUnlocked: Date? = nil, dateAvailable: Date? = nil, burned: Bool, dateBurned: Date? = nil, meaningStats: ItemStats? = nil, readingStats: ItemStats? = nil, meaningNote: String? = nil, readingNote: String? = nil, userSynonyms: [String]? = nil) {
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
    func compareOptionalArray(_ a: [String]?, to b: [String]?) -> Bool {
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
        // The line below makes the entire statement fail to compile.  Awaiting support for Arrays of Equatables to be Equatable.
        //lhs.userSynonyms == rhs.userSynonyms
        // Use nested comparison function for now
        compareOptionalArray(lhs.userSynonyms, to: rhs.userSynonyms)
}
