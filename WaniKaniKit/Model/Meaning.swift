//
//  Meaning.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct Meaning: Codable, Equatable {
    public let meaning: String
    public let isPrimary: Bool
    public let isAcceptedAnswer: Bool
    
    public init(meaning: String, isPrimary: Bool, isAcceptedAnswer: Bool) {
        self.meaning = meaning
        self.isPrimary = isPrimary
        self.isAcceptedAnswer = isAcceptedAnswer
    }
    
    private enum CodingKeys: String, CodingKey {
        case meaning
        case isPrimary = "primary"
        case isAcceptedAnswer = "accepted_answer"
    }
}
