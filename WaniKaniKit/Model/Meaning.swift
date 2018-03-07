//
//  Meaning.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct Meaning: Codable, Equatable {
    public let meaning: String
    public let isPrimary: Bool
    
    public init(meaning: String, isPrimary: Bool) {
        self.meaning = meaning
        self.isPrimary = isPrimary
    }
    
    private enum CodingKeys: String, CodingKey {
        case meaning
        case isPrimary = "primary"
    }
}
