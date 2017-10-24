//
//  ResourceCollectionItem.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public enum ResourceCollectionItemObjectType: String, Codable {
    case radical
    case kanji
    case vocabulary
    case assignment
    case studyMaterial = "study_material"
    case reviewStatistic = "review_statistic"
    case levelProgression = "level_progression"
}

public protocol ResourceCollectionItemData: Codable {
}

public struct ResourceCollectionItem: Decodable {
    public let id: Int
    public let type: ResourceCollectionItemObjectType
    public let url: URL
    public let dataUpdatedAt: Date
    public let data: ResourceCollectionItemData
    
    public init(id: Int, type: ResourceCollectionItemObjectType, url: URL, dataUpdatedAt: Date, data: ResourceCollectionItemData) {
        self.id = id
        self.type = type
        self.url = url
        self.dataUpdatedAt = dataUpdatedAt
        self.data = data
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        type = try c.decode(ResourceCollectionItemObjectType.self, forKey: .type)
        url = try c.decode(URL.self, forKey: .url)
        dataUpdatedAt = try c.decode(Date.self, forKey: .dataUpdatedAt)
        data = try c.decodeResource(of: type, forKey: .data)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case type = "object"
        case url
        case dataUpdatedAt = "data_updated_at"
        case data
    }
}

extension ResourceCollectionItem: Equatable {
    public static func ==(lhs: ResourceCollectionItem, rhs: ResourceCollectionItem) -> Bool {
        switch (lhs.data, rhs.data) {
        case let (ldata, rdata) as (Assignment, Assignment):
            guard ldata == rdata else { return false }
        case let (ldata, rdata) as (Radical, Radical):
            guard ldata == rdata else { return false }
        case let (ldata, rdata) as (Kanji, Kanji):
            guard ldata == rdata else { return false }
        case let (ldata, rdata) as (Vocabulary, Vocabulary):
            guard ldata == rdata else { return false }
        case let (ldata, rdata) as (StudyMaterials, StudyMaterials):
            guard ldata == rdata else { return false }
        case let (ldata, rdata) as (ReviewStatistics, ReviewStatistics):
            guard ldata == rdata else { return false }
        case let (ldata, rdata) as (LevelProgression, LevelProgression):
            guard ldata == rdata else { return false }
        default:
            return false
        }
        
        return lhs.id == rhs.id
            && lhs.type == rhs.type
            && lhs.url == rhs.url
            && lhs.dataUpdatedAt == rhs.dataUpdatedAt
    }
}

private extension KeyedDecodingContainerProtocol {
    func decodeResource(of type: ResourceCollectionItemObjectType, forKey key: Key) throws -> ResourceCollectionItemData {
        switch type {
        case .radical: return try decode(Radical.self, forKey: key)
        case .kanji: return try decode(Kanji.self, forKey: key)
        case .vocabulary: return try decode(Vocabulary.self, forKey: key)
        case .assignment: return try decode(Assignment.self, forKey: key)
        case .reviewStatistic: return try decode(ReviewStatistics.self, forKey: key)
        case .studyMaterial: return try decode(StudyMaterials.self, forKey: key)
        case .levelProgression: return try decode(LevelProgression.self, forKey: key)
        }
    }
}
