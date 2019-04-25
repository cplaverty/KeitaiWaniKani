//
//  Radical.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct Radical: ResourceCollectionItemData, Equatable {
    public let createdAt: Date
    public let level: Int
    public let slug: String
    public let hiddenAt: Date?
    public let documentURL: URL
    public let characters: String?
    public let characterImages: [CharacterImage]
    public let meanings: [Meaning]
    public let auxiliaryMeanings: [AuxiliaryMeaning]
    public let amalgamationSubjectIDs: [Int]
    public let meaningMnemonic: String
    public let lessonPosition: Int
    
    private enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case level
        case slug
        case hiddenAt = "hidden_at"
        case documentURL = "document_url"
        case characters
        case characterImages = "character_images"
        case meanings
        case auxiliaryMeanings = "auxiliary_meanings"
        case amalgamationSubjectIDs = "amalgamation_subject_ids"
        case meaningMnemonic = "meaning_mnemonic"
        case lessonPosition = "lesson_position"
    }
}

extension Radical: Subject {
    public var subjectType: SubjectType {
        return .radical
    }
    
    public var readings: [Reading] {
        return []
    }
    
    public var componentSubjectIDs: [Int] {
        return []
    }
}

extension Radical {
    public struct CharacterImage: Codable, Equatable {
        public let url: URL
        public let metadata: Metadata
        public let contentType: String
        
        private enum CodingKeys: String, CodingKey {
            case url
            case metadata
            case contentType = "content_type"
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
