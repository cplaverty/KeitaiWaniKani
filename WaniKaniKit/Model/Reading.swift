//
//  Reading.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct Reading: Codable, Equatable {
    /// Kanji only: one of Onyomi, Kunyomi or Nanori
    public let type: String?
    public let reading: String
    public let isPrimary: Bool
    public let isAcceptedAnswer: Bool
    
    public init(type: String? = nil, reading: String, isPrimary: Bool, isAcceptedAnswer: Bool) {
        self.type = type
        self.reading = reading
        self.isPrimary = isPrimary
        self.isAcceptedAnswer = isAcceptedAnswer
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case reading
        case isPrimary = "primary"
        case isAcceptedAnswer = "accepted_answer"
    }
}
