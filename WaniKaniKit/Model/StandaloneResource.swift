//
//  StandaloneResource.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public enum StandaloneResourceObjectType: String, Codable {
    case user
}

public protocol StandaloneResourceData: Codable {
    func isEqualTo(_ other: StandaloneResourceData) -> Bool
}

extension StandaloneResourceData where Self: Equatable {
    public func isEqualTo(_ other: StandaloneResourceData) -> Bool {
        guard let otherData = other as? Self else { return false }
        return self == otherData
    }
}

public struct StandaloneResource: Decodable {
    public let type: StandaloneResourceObjectType
    public let url: URL
    public let dataUpdatedAt: Date
    public let data: StandaloneResourceData
    
    public init(type: StandaloneResourceObjectType, url: URL, dataUpdatedAt: Date, data: StandaloneResourceData) {
        self.type = type
        self.url = url
        self.dataUpdatedAt = dataUpdatedAt
        self.data = data
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decode(StandaloneResourceObjectType.self, forKey: .type)
        url = try c.decode(URL.self, forKey: .url)
        dataUpdatedAt = try c.decode(Date.self, forKey: .dataUpdatedAt)
        data = try c.decodeResource(of: type, forKey: .data)
    }
    
    private enum CodingKeys: String, CodingKey {
        case type = "object"
        case url
        case dataUpdatedAt = "data_updated_at"
        case data
    }
}

extension StandaloneResource: Equatable {
    public static func ==(lhs: StandaloneResource, rhs: StandaloneResource) -> Bool {
        return lhs.type == rhs.type
            && lhs.url == rhs.url
            && lhs.dataUpdatedAt == rhs.dataUpdatedAt
            && lhs.data.isEqualTo(rhs.data)
    }
}

private extension KeyedDecodingContainerProtocol {
    func decodeResource(of type: StandaloneResourceObjectType, forKey key: Key) throws -> StandaloneResourceData {
        switch type {
        case .user: return try decode(UserInformation.self, forKey: key)
        }
    }
}
