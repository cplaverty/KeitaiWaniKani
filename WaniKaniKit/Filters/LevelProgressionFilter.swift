//
//  LevelProgressionFilter.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct LevelProgressionFilter {
    public let ids: [Int]?
    public let updatedAfter: Date?
    
    public init(ids: [Int]? = nil,
                updatedAfter: Date? = nil) {
        self.ids = ids
        self.updatedAfter = updatedAfter
    }
}

extension LevelProgressionFilter: RequestFilter {
    func asQueryItems() -> [URLQueryItem]? {
        var elements = [URLQueryItem]()
        elements.appendItemsIfSet(name: "ids", values: ids)
        elements.appendItemIfSet(name: "updated_after", value: updatedAfter)
        
        return elements.count == 0 ? nil : elements
    }
}
