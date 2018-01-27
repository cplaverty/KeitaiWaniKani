//
//  Radical.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct Radical: ResourceCollectionItemData {
    public struct CharacterImage: SubjectImage, Codable {
        public let contentType: String
        public let url: URL
        
        private enum CodingKeys: String, CodingKey {
            case contentType = "content_type"
            case url
        }
    }
    
    public let level: Int
    public let createdAt: Date
    public let slug: String
    public let characters: String?
    public let characterImages: [CharacterImage]
    public let meanings: [Meaning]
    public let documentURL: URL
    
    private enum CodingKeys: String, CodingKey {
        case level
        case createdAt = "created_at"
        case slug
        case characters
        case characterImages = "character_images"
        case meanings
        case documentURL = "document_url"
    }
}

extension Radical: Subject {
    public var subjectType: SubjectType {
        return .radical
    }
    
    public var characterRepresentation: SubjectCharacterRepresentation {
        if let characters = characters {
            return .unicode(characters)
        }
        
        return .image(characterImages)
    }
    
    public var readings: [Reading] {
        return []
    }
    
    public var componentSubjectIDs: [Int] {
        return []
    }
}

extension Radical: Equatable {
    public static func ==(lhs: Radical, rhs: Radical) -> Bool {
        return lhs.level == rhs.level
            && lhs.createdAt == rhs.createdAt
            && lhs.slug == rhs.slug
            && lhs.characters == rhs.characters
            && lhs.characterImages == rhs.characterImages
            && lhs.meanings == rhs.meanings
            && lhs.documentURL == rhs.documentURL
    }
}

extension Radical.CharacterImage: Equatable {
    public static func ==(lhs: Radical.CharacterImage, rhs: Radical.CharacterImage) -> Bool {
        return lhs.contentType == rhs.contentType
            && lhs.url == rhs.url
    }
}
