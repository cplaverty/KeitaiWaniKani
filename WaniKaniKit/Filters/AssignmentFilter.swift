//
//  AssignmentFilter.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct AssignmentFilter {
    public let ids: [Int]?
    public let subjectIDs: [Int]?
    public let subjectTypes: [SubjectType]?
    public let levels: [Int]?
    public let availableBefore: Date?
    public let availableAfter: Date?
    public let srsStages: [Int]?
    public let unlocked: Bool?
    public let started: Bool?
    public let passed: Bool?
    public let burned: Bool?
    public let resurrected: Bool?
    public let updatedAfter: Date?
    
    public init(ids: [Int]? = nil,
                subjectIDs: [Int]? = nil,
                subjectTypes: [SubjectType]? = nil,
                levels: [Int]? = nil,
                availableBefore: Date? = nil,
                availableAfter: Date? = nil,
                srsStages: [Int]? = nil,
                unlocked: Bool? = nil,
                started: Bool? = nil,
                passed: Bool? = nil,
                burned: Bool? = nil,
                resurrected: Bool? = nil,
                updatedAfter: Date? = nil) {
        self.ids = ids
        self.subjectIDs = subjectIDs
        self.subjectTypes = subjectTypes
        self.levels = levels
        self.availableBefore = availableBefore
        self.availableAfter = availableAfter
        self.srsStages = srsStages
        self.unlocked = unlocked
        self.started = started
        self.passed = passed
        self.burned = burned
        self.resurrected = resurrected
        self.updatedAfter = updatedAfter
    }
}

extension AssignmentFilter: RequestFilter {
    func asQueryItems() -> [URLQueryItem]? {
        var elements = [URLQueryItem]()
        elements.appendItemsIfSet(name: "ids", values: ids)
        elements.appendItemsIfSet(name: "subject_ids", values: subjectIDs)
        elements.appendItemsIfSet(name: "subject_types", values: subjectTypes)
        elements.appendItemsIfSet(name: "levels", values: levels)
        elements.appendItemIfSet(name: "available_before", value: availableBefore)
        elements.appendItemIfSet(name: "available_after", value: availableAfter)
        elements.appendItemsIfSet(name: "srs_stages", values: srsStages)
        elements.appendItemIfSet(name: "unlocked", value: unlocked)
        elements.appendItemIfSet(name: "started", value: started)
        elements.appendItemIfSet(name: "passed", value: passed)
        elements.appendItemIfSet(name: "burned", value: burned)
        elements.appendItemIfSet(name: "resurrected", value: resurrected)
        elements.appendItemIfSet(name: "updated_after", value: updatedAfter)
        
        return elements.count == 0 ? nil : elements
    }
}
