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
    public let averageLevelDuration: NSTimeInterval?
    
    public init(detail: [LevelInfo], projectedCurrentLevel: ProjectedLevelInfo?) {
        self.detail = detail
        self.projectedCurrentLevel = projectedCurrentLevel
        self.averageLevelDuration = self.dynamicType.calculateAverageLevelDuration(detail)
    }
    
    /// Calculate the bounded mean, ignoring durations in the upper and lower quartiles
    private static func calculateAverageLevelDuration(detail: [LevelInfo]) -> NSTimeInterval? {
        guard detail.count > 0 else { return nil }
        
        var durations = detail.flatMap { $0.duration }
        durations.sortInPlace(<)
        let boundedDurations = durations[interquartileRange(durations.count)]
        
        return boundedDurations.reduce(0.0, combine: +) / Double(boundedDurations.count)
    }
    
    /// Grab the middle 50% of values, preferring lower values
    private static func interquartileRange(itemCount: Int) -> Range<Int> {
        guard itemCount > 0 else { return 0..<0 }
        
        let itemIndex = itemCount - 1
        let lowerQuartileEdge = itemIndex / 4 + (itemIndex % 4 == 3 ? 1 : 0)
        let upperQuartileEdge = itemIndex * 3 / 4 + (itemIndex == 1 ? 1 : 0)
        return lowerQuartileEdge...upperQuartileEdge
    }
}

public func ==(lhs: LevelData, rhs: LevelData) -> Bool {
    // No need to check averageLevelDuration since this is a cached calculation
    return lhs.detail == rhs.detail &&
        lhs.projectedCurrentLevel == rhs.projectedCurrentLevel
}

public struct LevelInfo: Equatable {
    public let level: Int
    public let startDate: NSDate
    public let endDate: NSDate?
    
    public var duration: NSTimeInterval? {
        guard let endDate = endDate else { return nil }
        return endDate.timeIntervalSinceDate(startDate)
    }
    
    public init(level: Int, startDate: NSDate, endDate: NSDate?) {
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
    public let startDate: NSDate
    public let endDate: NSDate
    public let endDateBasedOnLockedItem: Bool
    
    public init(level: Int, startDate: NSDate, endDate: NSDate, endDateBasedOnLockedItem: Bool) {
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
