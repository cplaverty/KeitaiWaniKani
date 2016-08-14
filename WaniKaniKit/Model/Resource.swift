//
//  Resource.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public enum Resource {
    case userInformation, studyQueue, levelProgression, srsDistribution, radicals, kanji, vocabulary
    
    var shouldSplitDownloadByLevel: Bool {
        switch self {
        case .userInformation, .studyQueue, .levelProgression, .srsDistribution, .radicals, .kanji: return false
        case .vocabulary: return true
        }
    }
}

extension Resource: CustomStringConvertible {
    public var description: String {
        switch self {
        case .userInformation: return "User Information"
        case .studyQueue: return "Study Queue"
        case .levelProgression: return "Level Progression"
        case .srsDistribution: return "SRS Distribution"
        case .radicals: return "Radicals"
        case .kanji: return "Kanji"
        case .vocabulary: return "Vocabulary"
        }
    }
}
