//
//  SRSDistribution.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct SRSDistribution: Equatable {
    public let countsBySRSStage: [SRSStage: SRSItemCounts]
    
    public init(countsBySRSStage: [SRSStage: SRSItemCounts]) {
        self.countsBySRSStage = countsBySRSStage
    }
}
