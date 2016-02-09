//
//  SRSDataItem.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public protocol SRSDataItem {
    var level: Int { get }
    var userSpecificSRSData: UserSpecificSRSData? { get }
    
    /// Returns the earliest date an item could be raised to Guru given the current state of the item
    func guruDate(unlockDateForLockedItems: NSDate?) -> NSDate?
    
    /// Returns the earliest possible date an item could be raised to Guru, ignoring current progress and assuming all reviews correct
    func earliestPossibleGuruDate(unlockDateForLockedItems: NSDate?) -> NSDate?
}

public extension SRSDataItem {
    private static var isRadical: Bool { return self == Radical.self }
    private var isAccelerated: Bool { return WaniKaniAPI.isAcceleratedLevel(level) }
    
    public func guruDate(unlockDateForLockedItems: NSDate?) -> NSDate? {
        // Assume best case scenario: the next review is successful
        guard let baseDate = userSpecificSRSData?.dateAvailable?.laterDate(NSDate()) ?? unlockDateForLockedItems else { return nil }

        let initialLevel = (userSpecificSRSData?.srsLevelNumeric ?? 0) + 1
        let guruNumericLevel = SRSLevel.Guru.numericLevelThreshold
        
        if initialLevel > guruNumericLevel { return nil }
        else if initialLevel == guruNumericLevel { return baseDate }
        
        return WaniKaniAPI.minimumTimeFromSRSLevel(initialLevel, toSRSLevel: guruNumericLevel, fromDate: baseDate, isRadical: self.dynamicType.isRadical, isAccelerated: isAccelerated)
    }
    
    public func earliestPossibleGuruDate(unlockDateForLockedItems: NSDate? = nil) -> NSDate? {
        guard let baseDate = userSpecificSRSData?.dateUnlocked ?? unlockDateForLockedItems else { return nil }
        
        return WaniKaniAPI.minimumTimeFromSRSLevel(1, toSRSLevel: SRSLevel.Guru.numericLevelThreshold, fromDate: baseDate, isRadical: self.dynamicType.isRadical, isAccelerated: isAccelerated)
    }
}

public struct SRSDataItemSorting {
    public static func byProgress(lhs: SRSDataItem, rhs: SRSDataItem) -> Bool {
        let u1 = lhs.userSpecificSRSData, u2 = rhs.userSpecificSRSData
        if u1?.srsLevelNumeric == u2?.srsLevelNumeric {
            return u1?.dateAvailable > u2?.dateAvailable
        } else {
            return u1?.srsLevelNumeric < u2?.srsLevelNumeric
        }
    }
}
