//
//  Kanji.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct Kanji: ResourceCollectionItemData {
    public let level: Int
    public let createdAt: Date
    public let slug: String
    public let characters: String
    public let meanings: [Meaning]
    public let readings: [Reading]
    public let componentSubjectIDs: [Int]
    public let documentURL: URL
    
    private enum CodingKeys: String, CodingKey {
        case level
        case createdAt = "created_at"
        case slug
        case characters
        case meanings
        case readings
        case componentSubjectIDs = "component_subject_ids"
        case documentURL = "document_url"
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

extension Kanji: Equatable {
    public static func ==(lhs: Kanji, rhs: Kanji) -> Bool {
        return lhs.level == rhs.level
            && lhs.createdAt == rhs.createdAt
            && lhs.slug == rhs.slug
            && lhs.characters == rhs.characters
            && lhs.meanings == rhs.meanings
            && lhs.readings == rhs.readings
            && lhs.componentSubjectIDs == rhs.componentSubjectIDs
            && lhs.documentURL == rhs.documentURL
    }
}
