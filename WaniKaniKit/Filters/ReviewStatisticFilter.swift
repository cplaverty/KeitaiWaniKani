//
//  ReviewStatisticsFilter.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct ReviewStatisticFilter {
    public let ids: [Int]?
    public let subjectIDs: [Int]?
    public let subjectTypes: [SubjectType]?
    public let updatedAfter: Date?
    public let percentagesGreaterThan: Int?
    public let percentagesLessThan: Int?
    
    public init(ids: [Int]? = nil,
                subjectIDs: [Int]? = nil,
                subjectTypes: [SubjectType]? = nil,
                updatedAfter: Date? = nil,
                percentagesGreaterThan: Int? = nil,
                percentagesLessThan: Int? = nil) {
        self.ids = ids
        self.subjectIDs = subjectIDs
        self.subjectTypes = subjectTypes
        self.updatedAfter = updatedAfter
        self.percentagesGreaterThan = percentagesGreaterThan
        self.percentagesLessThan = percentagesLessThan
    }
}

extension ReviewStatisticFilter: RequestFilter {
    func asQueryItems() -> [URLQueryItem]? {
        var elements = [URLQueryItem]()
        elements.appendItemsIfSet(name: "ids", values: ids)
        elements.appendItemsIfSet(name: "subject_ids", values: subjectIDs)
        elements.appendItemsIfSet(name: "subject_types", values: subjectTypes)
        elements.appendItemIfSet(name: "updated_after", value: updatedAfter)
        elements.appendItemIfSet(name: "percentages_greater_than", value: percentagesGreaterThan)
        elements.appendItemIfSet(name: "percentages_less_than", value: percentagesLessThan)
        
        return elements.count == 0 ? nil : elements
    }
}
