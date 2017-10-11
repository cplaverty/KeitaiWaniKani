//
//  AssignmentFilter.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct AssignmentFilter {
    public let subjectIDs: [Int]?
    public let subjectType: SubjectType?
    public let levels: [Int]?
    public let availableBefore: Date?
    public let availableAfter: Date?
    public let srsStages: [Int]?
    public let passed: Bool?
    public let burned: Bool?
    public let updatedAfter: Date?
    public let pageNumber: Int?
    
    public init(subjectIDs: [Int]? = nil,
                subjectType: SubjectType? = nil,
                levels: [Int]? = nil,
                availableBefore: Date? = nil,
                availableAfter: Date? = nil,
                srsStages: [Int]? = nil,
                passed: Bool? = nil,
                burned: Bool? = nil,
                updatedAfter: Date? = nil,
                pageNumber: Int? = nil) {
        self.subjectIDs = subjectIDs
        self.subjectType = subjectType
        self.levels = levels
        self.availableBefore = availableBefore
        self.availableAfter = availableAfter
        self.srsStages = srsStages
        self.passed = passed
        self.burned = burned
        self.updatedAfter = updatedAfter
        self.pageNumber = pageNumber
    }
}

extension AssignmentFilter: RequestFilter {
    func asQueryItems() -> [URLQueryItem]? {
        var elements = [URLQueryItem]()
        elements.appendItemsIfSet(name: "subject_ids", values: subjectIDs)
        elements.appendItemIfSet(name: "subject_type", value: subjectType)
        elements.appendItemsIfSet(name: "levels", values: levels)
        elements.appendItemIfSet(name: "available_before", value: availableBefore)
        elements.appendItemIfSet(name: "available_after", value: availableAfter)
        elements.appendItemsIfSet(name: "srs_stages", values: srsStages)
        elements.appendItemIfSet(name: "passed", value: passed)
        elements.appendItemIfSet(name: "burned", value: burned)
        elements.appendItemIfSet(name: "updated_after", value: updatedAfter)
        elements.appendItemIfSet(name: "page", value: pageNumber)
        
        return elements.count == 0 ? nil : elements
    }
}
