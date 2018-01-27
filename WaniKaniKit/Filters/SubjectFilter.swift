//
//  SubjectFilter.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct SubjectFilter {
    public let ids: [Int]?
    public let type: SubjectType?
    public let slugs: [String]?
    public let levels: [Int]?
    public let updatedAfter: Date?
    
    public init(ids: [Int]? = nil,
                type: SubjectType? = nil,
                slugs: [String]? = nil,
                levels: [Int]? = nil,
                updatedAfter: Date? = nil) {
        self.ids = ids
        self.type = type
        self.slugs = slugs
        self.levels = levels
        self.updatedAfter = updatedAfter
    }
}

extension SubjectFilter: RequestFilter {
    func asQueryItems() -> [URLQueryItem]? {
        var elements = [URLQueryItem]()
        elements.appendItemsIfSet(name: "ids", values: ids)
        elements.appendItemIfSet(name: "type", value: type)
        elements.appendItemsIfSet(name: "slugs", values: slugs)
        elements.appendItemsIfSet(name: "levels", values: levels)
        elements.appendItemIfSet(name: "updated_after", value: updatedAfter)
        
        return elements.count == 0 ? nil : elements
    }
}
