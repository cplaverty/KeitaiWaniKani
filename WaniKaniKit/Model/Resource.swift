//
//  Resource.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public enum Resource {
    case UserInformation, StudyQueue, LevelProgression, SRSDistribution, Radicals, Kanji, Vocabulary
    
    var splitByLevel: Bool {
        switch self {
        case UserInformation, StudyQueue, LevelProgression, SRSDistribution, Radicals, Kanji: return false
        case Vocabulary: return true
        }
    }
}

extension Resource: CustomStringConvertible {
    public var description: String {
        switch self {
        case .UserInformation: return "User Information"
        case .StudyQueue: return "Study Queue"
        case .LevelProgression: return "Level Progression"
        case .SRSDistribution: return "SRS Distribution"
        case .Radicals: return "Radicals"
        case .Kanji: return "Kanji"
        case .Vocabulary: return "Vocabulary"
        }
    }
}