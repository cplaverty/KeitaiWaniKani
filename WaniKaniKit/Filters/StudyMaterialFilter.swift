//
//  StudyMaterialsFilter.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct StudyMaterialFilter {
    public let ids: [Int]?
    public let subjectIDs: [Int]?
    public let subjectTypes: [SubjectType]?
    public let updatedAfter: Date?
    
    public init(ids: [Int]? = nil,
                subjectIDs: [Int]? = nil,
                subjectTypes: [SubjectType]? = nil,
                updatedAfter: Date? = nil) {
        self.ids = ids
        self.subjectIDs = subjectIDs
        self.subjectTypes = subjectTypes
        self.updatedAfter = updatedAfter
    }
}

extension StudyMaterialFilter: RequestFilter {
    func asQueryItems() -> [URLQueryItem]? {
        var elements = [URLQueryItem]()
        elements.appendItemsIfSet(name: "ids", values: ids)
        elements.appendItemsIfSet(name: "subject_ids", values: subjectIDs)
        elements.appendItemsIfSet(name: "subject_types", values: subjectTypes)
        elements.appendItemIfSet(name: "updated_after", value: updatedAfter)
        
        return elements.count == 0 ? nil : elements
    }
}
