//
//  SRSReviewCounts.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct SRSReviewCounts: Equatable {
    public let dateAvailable: Date
    public let itemCounts: SRSItemCounts
    
    public init(dateAvailable: Date, itemCounts: SRSItemCounts) {
        self.dateAvailable = dateAvailable
        self.itemCounts = itemCounts
    }
}
