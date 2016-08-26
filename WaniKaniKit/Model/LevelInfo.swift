//
//  LevelInfo.swift
//  WaniKaniKit
//
//  Copyright © 2016 Chris Laverty. All rights reserved.
//

import Foundation

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
        guard !detail.lazy.filter({ $0.endDate != nil }).isEmpty else { return nil }
        
        var durations = detail.flatMap { $0.duration }
        durations.sort(by: <)
        let boundedDurations = durations.interquartileRange()
        guard !boundedDurations.isEmpty else { return nil }
        
        let lowerQuartile = boundedDurations.first!
        let upperQuartile = boundedDurations.last!
        let mean = boundedDurations.reduce(0.0, +) / Double(boundedDurations.count)
        
        return LevelStats(mean: mean, lowerQuartile: lowerQuartile, upperQuartile: upperQuartile)
    }
}

public func ==(lhs: LevelData, rhs: LevelData) -> Bool {
    return lhs.detail == rhs.detail &&
        lhs.projectedCurrentLevel == rhs.projectedCurrentLevel &&
        lhs.stats == rhs.stats
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

public func ==(lhs: LevelStats, rhs: LevelStats) -> Bool {
    return lhs.mean == rhs.mean &&
        lhs.lowerQuartile == rhs.lowerQuartile &&
        lhs.upperQuartile == rhs.upperQuartile
}

public struct LevelInfo: Equatable {
    public let level: Int
    public let startDate: Date
    public let endDate: Date?
    
    public var duration: TimeInterval? {
        guard let endDate = endDate else { return nil }
        return endDate.timeIntervalSince(startDate)
    }
    
    public init(level: Int, startDate: Date, endDate: Date?) {
        self.level = level
        self.startDate = startDate
        self.endDate = endDate
    }
}

public func ==(lhs: LevelInfo, rhs: LevelInfo) -> Bool {
    return lhs.level == rhs.level &&
        lhs.startDate == rhs.startDate &&
        lhs.endDate == rhs.endDate
}

public struct ProjectedLevelInfo: Equatable {
    public let level: Int
    public let startDate: Date
    public let endDate: Date
    public let endDateBasedOnLockedItem: Bool
    
    public init(level: Int, startDate: Date, endDate: Date, endDateBasedOnLockedItem: Bool) {
        self.level = level
        self.startDate = startDate
        self.endDate = endDate
        self.endDateBasedOnLockedItem = endDateBasedOnLockedItem
    }
}

public func ==(lhs: ProjectedLevelInfo, rhs: ProjectedLevelInfo) -> Bool {
    return lhs.level == rhs.level &&
        lhs.startDate == rhs.startDate &&
        lhs.endDate == rhs.endDate &&
        lhs.endDateBasedOnLockedItem == rhs.endDateBasedOnLockedItem
}

fileprivate extension Collection {
    /// Grab the middle 50% of values, preferring lower values
    fileprivate func interquartileRange() -> SubSequence {
        guard self.count > 0 else { return self[startIndex..<startIndex] }
        
        let itemIndex = self.count - 1
        let lowerQuartileEdge = index(startIndex, offsetBy: itemIndex / 4 + (itemIndex % 4 == 3 ? 1 : 0))
        let upperQuartileEdge = index(startIndex, offsetBy: itemIndex * 3 / 4 + (itemIndex == 1 ? 1 : 0))
        return self[lowerQuartileEdge...upperQuartileEdge]
    }
}
