//
//  Vocabulary.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public struct Vocabulary: SRSDataItem, Equatable {
    /// Primary key
    public let character: String
    public let meaning: String
    public let kana: String
    public let level: Int
    public let userSpecificSRSData: UserSpecificSRSData?
    public let lastUpdateTimestamp: NSDate
    
    public init(character: String, meaning: String, kana: String, level: Int, userSpecificSRSData: UserSpecificSRSData? = nil, lastUpdateTimestamp: NSDate? = nil) {
        self.character = character
        self.meaning = meaning
        self.kana = kana
        self.level = level
        self.userSpecificSRSData = userSpecificSRSData
        self.lastUpdateTimestamp = lastUpdateTimestamp ?? NSDate()
    }
}

public func ==(lhs: Vocabulary, rhs: Vocabulary) -> Bool {
    return lhs.character == rhs.character &&
        lhs.meaning == rhs.meaning &&
        lhs.kana == rhs.kana &&
        lhs.level == rhs.level &&
        lhs.userSpecificSRSData == rhs.userSpecificSRSData
}
