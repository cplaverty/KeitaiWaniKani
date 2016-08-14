//
//  SRSDistribution.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public struct SRSDistribution: Equatable {
    public let countsBySRSLevel: [SRSLevel: SRSItemCounts]
    public let lastUpdateTimestamp: Date
    
    public init?(countsBySRSLevel: [SRSLevel: SRSItemCounts], lastUpdateTimestamp: Date? = nil) {
        if countsBySRSLevel.isEmpty {
            return nil
        }
        
        self.countsBySRSLevel = countsBySRSLevel
        self.lastUpdateTimestamp = lastUpdateTimestamp ?? Date()
    }
}

public func ==(lhs: SRSDistribution, rhs: SRSDistribution) -> Bool {
    return lhs.countsBySRSLevel == rhs.countsBySRSLevel
}
