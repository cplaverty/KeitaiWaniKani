//
//  Subject.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public enum SubjectType: String, Codable {
    case radical
    case kanji
    case vocabulary
}

public extension SubjectType {
    var backgroundColor: UIColor {
        switch self {
        case .radical:
            return .waniKaniRadical
        case .kanji:
            return .waniKaniKanji
        case .vocabulary:
            return .waniKaniVocabulary
        }
    }
}

public protocol Subject {
    var level: Int { get }
    var slug: String { get }
    var componentSubjectIDs: [Int] { get }
}
