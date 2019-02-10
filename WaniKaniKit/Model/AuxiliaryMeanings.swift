//
//  AuxiliaryMeanings.swift
//  WaniKaniKit
//
//  Copyright © 2019 Chris Laverty. All rights reserved.
//

public struct AuxiliaryMeaning: Codable, Equatable {
    public let type: String
    public let meaning: String
    
    private enum CodingKeys: String, CodingKey {
        case type
        case meaning
    }
}
