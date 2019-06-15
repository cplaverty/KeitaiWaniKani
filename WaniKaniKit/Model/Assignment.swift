//
//  Assignment.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct Assignment: ResourceCollectionItemData, Equatable {
    public let createdAt: Date
    public let subjectID: Int
    public let subjectType: SubjectType
    public let srsStage: Int
    public let srsStageName: String
    public let unlockedAt: Date?
    public let startedAt: Date?
    public let passedAt: Date?
    public let burnedAt: Date?
    public let availableAt: Date?
    public let resurrectedAt: Date?
    public let isPassed: Bool
    public let isResurrected: Bool
    public let isHidden: Bool
    
    private enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case subjectID = "subject_id"
        case subjectType = "subject_type"
        case srsStage = "srs_stage"
        case srsStageName = "srs_stage_name"
        case unlockedAt = "unlocked_at"
        case startedAt = "started_at"
        case passedAt = "passed_at"
        case burnedAt = "burned_at"
        case availableAt = "available_at"
        case resurrectedAt = "resurrected_at"
        case isPassed = "passed"
        case isResurrected = "resurrected"
        case isHidden = "hidden"
    }
}

public extension Assignment {
    private static func isAcceleratedLevel(_ level: Int) -> Bool {
        return level <= 2
    }
    
    static func earliestDate(from date: Date, forItemAtSRSStage initialStage: Int, toSRSStage finalStage: Int, subjectType: SubjectType, subjectLevel: Int) -> Date? {
        let isAccelerated = isAcceleratedLevel(subjectLevel)
        
        let calendar = Calendar.current
        var guruDate = calendar.startOfHour(for: date)
        for stage in initialStage..<finalStage {
            guard let timeToNextStage = timeToNextReview(forItemWithSRSStage: stage, isAccelerated: isAccelerated) else {
                return nil
            }
            guruDate = calendar.date(byAdding: timeToNextStage, to: guruDate)!
        }
        
        return guruDate
    }
    
    func guruDate(subjectLevel: Int) -> Date? {
        if isPassed { return passedAt ?? Date.distantPast }
        
        return earliestDate(to: .guru, reportedDate: passedAt, subjectLevel: subjectLevel)
    }
    
    func burnDate(subjectLevel: Int) -> Date? {
        return earliestDate(to: .burned, reportedDate: burnedAt, subjectLevel: subjectLevel)
    }
    
    private func earliestDate(to stage: SRSStage, reportedDate: Date?, subjectLevel: Int) -> Date? {
        let initialStageNumeric = srsStage + 1
        let finalStageNumeric = stage.numericLevelRange.lowerBound
        
        if initialStageNumeric > finalStageNumeric { return reportedDate ?? Date.distantPast }
        
        // Assume best case scenario: the next review is performed as soon as it becomes available (or now, if available now) and is successful
        let startOfHour = Calendar.current.startOfHour(for: Date())
        let date = availableAt.map({ max($0, startOfHour) }) ?? startOfHour
        
        guard initialStageNumeric < finalStageNumeric else { return date }
        
        return Assignment.earliestDate(from: date, forItemAtSRSStage: initialStageNumeric, toSRSStage: finalStageNumeric, subjectType: subjectType, subjectLevel: subjectLevel)
    }
    
    private static func timeToNextReview(forItemWithSRSStage srsStageNumeric: Int, isAccelerated: Bool) -> DateComponents? {
        switch srsStageNumeric {
        case 0:
            return DateComponents()
        case 1 where isAccelerated:
            return DateComponents(hour: 2)
        case 1,
             2 where isAccelerated:
            return DateComponents(hour: 4)
        case 2,
             3 where isAccelerated:
            return DateComponents(hour: 8)
        case 3,
             4 where isAccelerated:
            return DateComponents(day: 1, hour: -1)
        case 4:
            return DateComponents(day: 2, hour: -1)
        case 5:
            return DateComponents(day: 7, hour: -1)
        case 6:
            return DateComponents(day: 14, hour: -1)
        case 7:
            // WK assumes 30 day months
            return DateComponents(day: 30, hour: -1)
        case 8:
            // WK assumes 30 day months
            return DateComponents(day: 4 * 30, hour: -1)
        default: return nil
        }
    }
}

extension Assignment {
    public struct Sorting {
        /// Sort from least progressed to most progressed
        public static func byProgress(_ lhs: Assignment, _ rhs: Assignment) -> Bool {
            if lhs.isPassed != rhs.isPassed {
                return rhs.isPassed
            }
            if lhs.srsStage != rhs.srsStage {
                return lhs.srsStage < rhs.srsStage
            }
            return (lhs.availableAt ?? Date.distantFuture) > (rhs.availableAt ?? Date.distantFuture)
        }
        
        public static func byProgress(_ lhs: Assignment?, _ rhs: Assignment?) -> Bool {
            guard let lhs = lhs else {
                return true
            }
            guard let rhs = rhs else {
                return false
            }
            return byProgress(lhs, rhs)
        }
    }
}
