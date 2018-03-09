//
//  LevelData.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct LevelData: Equatable {
    public let detail: [LevelProgression]
    public let projectedCurrentLevel: ProjectedLevelInfo?
    public let stats: LevelStats?
    
    public init(detail: [LevelProgression], projectedCurrentLevel: ProjectedLevelInfo?) {
        self.detail = detail
        self.projectedCurrentLevel = projectedCurrentLevel
        self.stats = type(of: self).calculateAverageLevelDuration(detail)
    }
    
    /// Calculate the bounded mean, ignoring durations in the upper and lower quartiles
    private static func calculateAverageLevelDuration(_ detail: [LevelProgression]) -> LevelStats? {
        let durations = detail.lazy.compactMap({ $0.duration }).sorted()
        let boundedDurations = durations.interquartileSubSequence()
        guard !boundedDurations.isEmpty else { return nil }
        
        let lowerQuartile = boundedDurations.first!
        let upperQuartile = boundedDurations.last!
        let mean = boundedDurations.reduce(0.0, +) / Double(boundedDurations.count)
        
        return LevelStats(mean: mean, lowerQuartile: lowerQuartile, upperQuartile: upperQuartile)
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
