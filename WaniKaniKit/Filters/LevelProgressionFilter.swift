//
//  LevelProgressionFilter.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct LevelProgressionFilter {
    public let updatedAfter: Date?
    public let pageNumber: Int?
    
    public init(updatedAfter: Date? = nil,
                pageNumber: Int? = nil) {
        self.updatedAfter = updatedAfter
        self.pageNumber = pageNumber
    }
}

extension LevelProgressionFilter: RequestFilter {
    func asQueryItems() -> [URLQueryItem]? {
        var elements = [URLQueryItem]()
        elements.appendItemIfSet(name: "updated_after", value: updatedAfter)
        elements.appendItemIfSet(name: "page", value: pageNumber)
        
        return elements.count == 0 ? nil : elements
    }
}
