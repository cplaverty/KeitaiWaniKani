//
//  SubjectFilter.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct SubjectFilter {
    public let type: SubjectType?
    public let slugs: [String]?
    public let levels: [Int]?
    public let updatedAfter: Date?
    public let pageNumber: Int?
    
    public init(type: SubjectType? = nil,
                slugs: [String]? = nil,
                levels: [Int]? = nil,
                updatedAfter: Date? = nil,
                pageNumber: Int? = nil) {
        self.type = type
        self.slugs = slugs
        self.levels = levels
        self.updatedAfter = updatedAfter
        self.pageNumber = pageNumber
    }
}

extension SubjectFilter: RequestFilter {
    func asQueryItems() -> [URLQueryItem]? {
        var elements = [URLQueryItem]()
        elements.appendItemIfSet(name: "type", value: type)
        elements.appendItemsIfSet(name: "slugs", values: slugs)
        elements.appendItemsIfSet(name: "levels", values: levels)
        elements.appendItemIfSet(name: "updated_after", value: updatedAfter)
        elements.appendItemIfSet(name: "page", value: pageNumber)
        
        return elements.count == 0 ? nil : elements
    }
}
