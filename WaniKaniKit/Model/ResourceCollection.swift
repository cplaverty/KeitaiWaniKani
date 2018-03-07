//
//  ResourceCollection.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct ResourceCollection: Decodable, Equatable {
    public struct Pages: Decodable, Equatable {
        public let itemsPerPage: Int
        public let previousURL: URL?
        public let nextURL: URL?
        
        private enum CodingKeys: String, CodingKey {
            case itemsPerPage = "per_page"
            case previousURL = "previous_url"
            case nextURL = "next_url"
        }
    }
    
    public let object: String
    public let url: URL
    public let pages: Pages
    public let totalCount: Int
    public let dataUpdatedAt: Date?
    public let data: [ResourceCollectionItem]
    
    public var estimatedPageCount: Int {
        let (quotient, remainder) = totalCount.quotientAndRemainder(dividingBy: pages.itemsPerPage)
        return remainder > 0 ? quotient + 1 : quotient
    }
    
    private enum CodingKeys: String, CodingKey {
        case object
        case url
        case pages
        case totalCount = "total_count"
        case dataUpdatedAt = "data_updated_at"
        case data
    }
}
