//
//  Vocabulary.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct Vocabulary: ResourceCollectionItemData, Equatable {
    public let level: Int
    public let createdAt: Date
    public let slug: String
    public let characters: String
    public let meanings: [Meaning]
    public let readings: [Reading]
    public let partsOfSpeech: [String]
    public let componentSubjectIDs: [Int]
    public let documentURL: URL
    
    private enum CodingKeys: String, CodingKey {
        case level
        case createdAt = "created_at"
        case slug
        case characters
        case meanings
        case readings
        case partsOfSpeech = "parts_of_speech"
        case componentSubjectIDs = "component_subject_ids"
        case documentURL = "document_url"
    }
}

extension Vocabulary: Subject {
    public var subjectType: SubjectType {
        return .vocabulary
    }
    
    public var characterRepresentation: SubjectCharacterRepresentation {
        return .unicode(characters)
    }
}
