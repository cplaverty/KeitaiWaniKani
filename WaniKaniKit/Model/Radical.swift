//
//  Radical.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public struct Radical: SRSDataItem, Equatable {
    public let character: String?
    /// Primary key
    public let meaning: String
    public let image: URL?
    public let level: Int
    public let userSpecificSRSData: UserSpecificSRSData?
    public let lastUpdateTimestamp: Date
    
    public init(character: String? = nil, meaning: String, image: URL? = nil, level: Int, userSpecificSRSData: UserSpecificSRSData? = nil, lastUpdateTimestamp: Date? = nil) {
        self.character = character
        self.meaning = meaning
        self.image = image
        self.level = level
        self.userSpecificSRSData = userSpecificSRSData
        self.lastUpdateTimestamp = lastUpdateTimestamp ?? Date()
    }
}

public func ==(lhs: Radical, rhs: Radical) -> Bool {
    return lhs.character == rhs.character &&
        lhs.meaning == rhs.meaning &&
        lhs.image == rhs.image &&
        lhs.level == rhs.level &&
        lhs.userSpecificSRSData == rhs.userSpecificSRSData
}
