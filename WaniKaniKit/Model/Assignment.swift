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
    
    public static func earliestDate(from date: Date, forItemAtSRSStage initialStage: Int, toSRSStage finalStage: Int, withLevel level: Int) -> Date? {
        let itemHasAcceleratedLevel = isAcceleratedLevel(level)
        
        let calendar = Calendar.current
        
        var guruDate = calendar.startOfHour(for: date)
        for stage in initialStage..<finalStage {
            guard let timeToNextStage = timeToNextReview(forItemWithSRSStage: stage, isAcceleratedLevel: itemHasAcceleratedLevel) else {
                return nil
            }
            guruDate = calendar.date(byAdding: timeToNextStage, to: guruDate)!
        }
        
        return guruDate
    }
    
    public func guruDate(unlockDateForLockedItems: Date?) -> Date? {
        // Assume best case scenario: the next review is performed as soon as it becomes available (or now, if available now) and is successful
        guard let baseDate = availableAt.map({ max($0, Date()) }) ?? unlockDateForLockedItems else { return nil }
        
        let initialLevel = srsStage + 1
        let guruNumericLevel = SRSStage.guru.numericLevelRange.lowerBound
        
        if isPassed || initialLevel > guruNumericLevel { return nil }
        if initialLevel == guruNumericLevel { return baseDate }
        
        return Assignment.earliestDate(from: baseDate, forItemAtSRSStage: initialLevel, toSRSStage: guruNumericLevel, withLevel: level)
    }
    
    private static func timeToNextReview(forItemWithSRSStage srsStageNumeric: Int, isAcceleratedLevel: Bool) -> DateComponents? {
        switch srsStageNumeric {
        case 0:
            return DateComponents()
        case 1 where isAcceleratedLevel:
            var dc = DateComponents()
            dc.hour = 2
            return dc
        case 1,
             2 where isAcceleratedLevel:
            var dc = DateComponents()
            dc.hour = 4
            return dc
        case 2,
             3 where isAcceleratedLevel:
            var dc = DateComponents()
            dc.hour = 8
            return dc
        case 3,
             4 where isAcceleratedLevel:
            var dc = DateComponents()
            dc.day = 1
            dc.hour = -1
            return dc
        case 4:
            var dc = DateComponents()
            dc.day = 2
            dc.hour = -1
            return dc
        case 5:
            var dc = DateComponents()
            dc.day = 7
            dc.hour = -1
            return dc
        case 6:
            var dc = DateComponents()
            dc.day = 14
            dc.hour = -1
            return dc
        case 7:
            var dc = DateComponents()
            dc.day = 30 // WK assumes 30 day months
            dc.hour = -1
            return dc
        case 8:
            var dc = DateComponents()
            dc.day = 4 * 30  // WK assumes 30 day months
            dc.hour = -1
            return dc
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
