//
//  ResourceCollection.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct ResourceCollection: Decodable {
    public struct Pages: Decodable {
        public let previousURL: URL?
        public let nextURL: URL?
        public let currentNumber: Int
        public let lastNumber: Int
        
        private enum CodingKeys: String, CodingKey {
            case previousURL = "previous_url"
            case nextURL = "next_url"
            case currentNumber = "current"
            case lastNumber = "last"
        }
    }
    
    public let object: String
    public let url: URL
    public let pages: Pages
    public let totalCount: Int
    public let dataUpdatedAt: Date?
    public let data: [ResourceCollectionItem]
    
    private enum CodingKeys: String, CodingKey {
        case object
        case url
        case pages
        case totalCount = "total_count"
        case dataUpdatedAt = "data_updated_at"
        case data
    }
}
