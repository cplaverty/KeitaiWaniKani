//
//  Kanji.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct Kanji: ResourceCollectionItemData, Equatable {
    public let level: Int
    public let createdAt: Date
    public let slug: String
    public let characters: String
    public let meanings: [Meaning]
    public let readings: [Reading]
    public let componentSubjectIDs: [Int]
    public let amalgamationSubjectIDs: [Int]
    public let documentURL: URL
    public let hiddenAt: Date?
    
    private enum CodingKeys: String, CodingKey {
        case level
        case createdAt = "created_at"
        case slug
        case characters
        case meanings
        case readings
        case componentSubjectIDs = "component_subject_ids"
        case amalgamationSubjectIDs = "amalgamation_subject_ids"
        case documentURL = "document_url"
        case hiddenAt = "hidden_at"
    }
}

extension Kanji: Subject {
    public var subjectType: SubjectType {
        return .kanji
    }
    
    public var characterRepresentation: SubjectCharacterRepresentation {
        return .unicode(characters)
    }
}
