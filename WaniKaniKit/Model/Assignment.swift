//
//  Assignment.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct Assignment: ResourceCollectionItemData {
    public let subjectID: Int
    public let subjectType: SubjectType
    public let level: Int
    public let srsStage: Int
    public let srsStageName: String
    public let unlockedAt: Date?
    public let startedAt: Date?
    public let passedAt: Date?
    public let burnedAt: Date?
    public let availableAt: Date?
    public let isPassed: Bool
    public let isResurrected: Bool
    
    private enum CodingKeys: String, CodingKey {
        case subjectID = "subject_id"
        case subjectType = "subject_type"
        case level
        case srsStage = "srs_stage"
        case srsStageName = "srs_stage_name"
        case unlockedAt = "unlocked_at"
        case startedAt = "started_at"
        case passedAt = "passed_at"
        case burnedAt = "burned_at"
        case availableAt = "available_at"
        case isPassed = "passed"
        case isResurrected = "resurrected"
    }
}

extension Assignment: Equatable {
    public static func ==(lhs: Assignment, rhs: Assignment) -> Bool {
        return lhs.subjectID == rhs.subjectID
            && lhs.subjectType == rhs.subjectType
            && lhs.level == rhs.level
            && lhs.srsStage == rhs.srsStage
            && lhs.srsStageName == rhs.srsStageName
            && lhs.unlockedAt == rhs.unlockedAt
            && lhs.startedAt == rhs.startedAt
            && lhs.passedAt == rhs.passedAt
            && lhs.burnedAt == rhs.burnedAt
            && lhs.availableAt == rhs.availableAt
            && lhs.isPassed == rhs.isPassed
            && lhs.isResurrected == rhs.isResurrected
    }
}

public extension Assignment {
    public static func isAcceleratedLevel(_ level: Int) -> Bool {
        return level <= 2
    }
    
    public static func earliestDate(from date: Date, forItemAtSRSStage initialStage: Int, toSRSStage finalStage: Int, subjectType: SubjectType, level: Int) -> Date? {
        let isAccelerated = isAcceleratedLevel(level)
        
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
    
    public func guruDate() -> Date? {
        let initialLevel = srsStage + 1
        let guruNumericLevel = SRSStage.guru.numericLevelRange.lowerBound
        
        if isPassed || initialLevel > guruNumericLevel { return passedAt ?? Date.distantPast }
        
        // Assume best case scenario: the next review is performed as soon as it becomes available (or now, if available now) and is successful
        let startOfHour = Calendar.current.startOfHour(for: Date())
        let baseDate = availableAt.map({ max($0, startOfHour) }) ?? startOfHour
        
        if initialLevel == guruNumericLevel { return baseDate }
        
        return Assignment.earliestDate(from: baseDate, forItemAtSRSStage: initialLevel, toSRSStage: guruNumericLevel, subjectType: subjectType, level: level)
    }
    
    private static func timeToNextReview(forItemWithSRSStage srsStageNumeric: Int, isAccelerated: Bool) -> DateComponents? {
        switch srsStageNumeric {
        case 0:
            return DateComponents()
        case 1 where isAccelerated:
            return DateComponents(hour: 1)
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
