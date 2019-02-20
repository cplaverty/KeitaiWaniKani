//
//  Kanji.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct Kanji: ResourceCollectionItemData, Equatable {
    public let createdAt: Date
    public let level: Int
    public let slug: String
    public let hiddenAt: Date?
    public let documentURL: URL
    public let characters: String
    public let meanings: [Meaning]
    public let auxiliaryMeanings: [AuxiliaryMeaning]
    public let readings: [Reading]
    public let componentSubjectIDs: [Int]
    public let amalgamationSubjectIDs: [Int]
    public let visuallySimilarSubjectIDs: [Int]
    public let meaningMnemonic: String
    public let meaningHint: String?
    public let readingMnemonic: String
    public let readingHint: String?
    public let lessonPosition: Int
    
    private enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case level
        case slug
        case hiddenAt = "hidden_at"
        case documentURL = "document_url"
        case characters
        case meanings
        case auxiliaryMeanings = "auxiliary_meanings"
        case readings
        case componentSubjectIDs = "component_subject_ids"
        case amalgamationSubjectIDs = "amalgamation_subject_ids"
        case visuallySimilarSubjectIDs = "visually_similar_subject_ids"
        case meaningMnemonic = "meaning_mnemonic"
        case meaningHint = "meaning_hint"
        case readingMnemonic = "reading_mnemonic"
        case readingHint = "reading_hint"
        case lessonPosition = "lesson_position"
    }
}

extension Kanji: Subject {
    public var subjectType: SubjectType {
        return .kanji
    }
}
