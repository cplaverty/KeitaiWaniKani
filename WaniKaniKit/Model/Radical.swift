//
//  Radical.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct Radical: ResourceCollectionItemData, Equatable {
    public let level: Int
    public let createdAt: Date
    public let slug: String
    public let characters: String?
    public let characterImages: [CharacterImage]
    public let meanings: [Meaning]
    public let amalgamationSubjectIDs: [Int]
    public let documentURL: URL
    public let hiddenAt: Date?
    
    private enum CodingKeys: String, CodingKey {
        case level
        case createdAt = "created_at"
        case slug
        case characters
        case characterImages = "character_images"
        case meanings
        case amalgamationSubjectIDs = "amalgamation_subject_ids"
        case documentURL = "document_url"
        case hiddenAt = "hidden_at"
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

extension Radical {
    public struct CharacterImage: SubjectImage, Codable, Equatable {
        public let contentType: String
        public let metadata: Metadata
        public let url: URL
        
        private enum CodingKeys: String, CodingKey {
            case contentType = "content_type"
            case metadata
            case url
        }
    }
}

extension Radical.CharacterImage {
    public struct Metadata: Codable, Equatable {
        public let color: String?
        public let dimensions: String?
        public let styleName: String?
        public let inlineStyles: Bool?
        
        enum CodingKeys: String, CodingKey {
            case color
            case dimensions
            case styleName = "style_name"
            case inlineStyles = "inline_styles"
        }
    }
}
