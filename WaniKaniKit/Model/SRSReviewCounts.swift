//
//  SRSReviewCounts.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public struct SRSReviewCounts: Equatable {
    public let dateAvailable: Date
    public let itemCounts: SRSItemCounts
}

public func ==(lhs: SRSReviewCounts, rhs: SRSReviewCounts) -> Bool {
    return lhs.dateAvailable == rhs.dateAvailable && lhs.itemCounts == rhs.itemCounts
}
