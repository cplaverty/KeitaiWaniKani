//
//  Kanji.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public struct Kanji: SRSDataItem, Equatable {
    /// Primary key
    public let character: String
    public let meaning: String
    public let onyomi: String?
    public let kunyomi: String?
    public let nanori: String?
    public let importantReading: String
    public let level: Int
    public let userSpecificSRSData: UserSpecificSRSData?
    public let lastUpdateTimestamp: Date
    
    public init(character: String, meaning: String, onyomi: String? = nil, kunyomi: String? = nil, nanori: String? = nil, importantReading: String, level: Int, userSpecificSRSData: UserSpecificSRSData? = nil, lastUpdateTimestamp: Date? = nil) {
        self.character = character
        self.meaning = meaning
        self.onyomi = onyomi
        self.kunyomi = kunyomi
        self.nanori = nanori
        self.importantReading = importantReading
        self.level = level
        self.userSpecificSRSData = userSpecificSRSData
        self.lastUpdateTimestamp = lastUpdateTimestamp ?? Date()
    }
}

public func ==(lhs: Kanji, rhs: Kanji) -> Bool {
    return lhs.character == rhs.character &&
        lhs.meaning == rhs.meaning &&
        lhs.onyomi == rhs.onyomi &&
        lhs.kunyomi == rhs.kunyomi &&
        lhs.nanori == rhs.nanori &&
        lhs.importantReading == rhs.importantReading &&
        lhs.level == rhs.level &&
        lhs.userSpecificSRSData == rhs.userSpecificSRSData
}
