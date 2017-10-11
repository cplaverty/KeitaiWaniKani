//
//  StudyMaterialsFilter.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct StudyMaterialFilter {
    public let subjectIDs: [Int]?
    public let subjectType: SubjectType?
    public let updatedAfter: Date?
    public let pageNumber: Int?
    
    public init(subjectIDs: [Int]? = nil,
                subjectType: SubjectType? = nil,
                updatedAfter: Date? = nil,
                pageNumber: Int? = nil) {
        self.subjectIDs = subjectIDs
        self.subjectType = subjectType
        self.updatedAfter = updatedAfter
        self.pageNumber = pageNumber
    }
}

extension StudyMaterialFilter: RequestFilter {
    func asQueryItems() -> [URLQueryItem]? {
        var elements = [URLQueryItem]()
        elements.appendItemsIfSet(name: "subject_ids", values: subjectIDs)
        elements.appendItemIfSet(name: "subject_type", value: subjectType)
        elements.appendItemIfSet(name: "updated_after", value: updatedAfter)
        elements.appendItemIfSet(name: "page", value: pageNumber)
        
        return elements.count == 0 ? nil : elements
    }
}
