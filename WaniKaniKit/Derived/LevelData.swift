//
//  LevelData.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct LevelData: Equatable {
    public let detail: [LevelInfo]
    public let projectedCurrentLevel: ProjectedLevelInfo?
    public let stats: LevelStats?
    
    public init(detail: [LevelInfo], projectedCurrentLevel: ProjectedLevelInfo?) {
        self.detail = detail
        self.projectedCurrentLevel = projectedCurrentLevel
        self.stats = type(of: self).calculateAverageLevelDuration(detail)
    }
    
    /// Calculate the bounded mean, ignoring durations in the upper and lower quartiles
    private static func calculateAverageLevelDuration(_ detail: [LevelInfo]) -> LevelStats? {
        let durations = detail.lazy.flatMap { $0.duration }.sorted()
        let boundedDurations = durations.interquartileSubSequence()
        guard !boundedDurations.isEmpty else { return nil }
        
        let lowerQuartile = boundedDurations.first!
        let upperQuartile = boundedDurations.last!
        let mean = boundedDurations.reduce(0.0, +) / Double(boundedDurations.count)
        
        return LevelStats(mean: mean, lowerQuartile: lowerQuartile, upperQuartile: upperQuartile)
    }
}

extension LevelData {
    public static func ==(lhs: LevelData, rhs: LevelData) -> Bool {
        return lhs.detail == rhs.detail
            && lhs.projectedCurrentLevel == rhs.projectedCurrentLevel
            && lhs.stats == rhs.stats
    }
}

public struct LevelStats: Equatable {
    public let mean: TimeInterval
    public let lowerQuartile: TimeInterval
    public let upperQuartile: TimeInterval
    
    public init(mean: TimeInterval, lowerQuartile: TimeInterval, upperQuartile: TimeInterval) {
        self.mean = mean
        self.lowerQuartile = lowerQuartile
        self.upperQuartile = upperQuartile
    }
}

extension LevelStats {
    public static func ==(lhs: LevelStats, rhs: LevelStats) -> Bool {
        return lhs.mean == rhs.mean
            && lhs.lowerQuartile == rhs.lowerQuartile
            && lhs.upperQuartile == rhs.upperQuartile
    }
}

public struct LevelInfo: Equatable {
    public let level: Int
    public let startDate: Date
    public let endDate: Date?
    
    public var duration: TimeInterval? {
        return endDate?.timeIntervalSince(startDate)
    }
    
    public init(level: Int, startDate: Date, endDate: Date?) {
        self.level = level
        self.startDate = startDate
        self.endDate = endDate
    }
}

extension LevelInfo {
    public static func ==(lhs: LevelInfo, rhs: LevelInfo) -> Bool {
        return lhs.level == rhs.level
            && lhs.startDate == rhs.startDate
            && lhs.endDate == rhs.endDate
    }
}

public struct ProjectedLevelInfo: Equatable {
    public let level: Int
    public let startDate: Date
    public let endDate: Date
    public let isEndDateBasedOnLockedItem: Bool
    
    public init(level: Int, startDate: Date, endDate: Date, isEndDateBasedOnLockedItem: Bool) {
        self.level = level
        self.startDate = startDate
        self.endDate = endDate
        self.isEndDateBasedOnLockedItem = isEndDateBasedOnLockedItem
    }
}

extension ProjectedLevelInfo {
    public static func ==(lhs: ProjectedLevelInfo, rhs: ProjectedLevelInfo) -> Bool {
        return lhs.level == rhs.level
            && lhs.startDate == rhs.startDate
            && lhs.endDate == rhs.endDate
            && lhs.isEndDateBasedOnLockedItem == rhs.isEndDateBasedOnLockedItem
    }
}

private extension Collection {
    /// Grab the middle 50% of values, preferring lower values
    func interquartileSubSequence() -> SubSequence {
        guard self.count > 0 else { return self[startIndex..<startIndex] }
        
        let lastItemIndex = self.count - 1
        let lowerQuartileEdge = index(startIndex, offsetBy: lastItemIndex / 4 + (lastItemIndex % 4 == 3 ? 1 : 0))
        let upperQuartileEdge = index(startIndex, offsetBy: lastItemIndex * 3 / 4 + (lastItemIndex == 1 ? 1 : 0))
        return self[lowerQuartileEdge...upperQuartileEdge]
    }
}
