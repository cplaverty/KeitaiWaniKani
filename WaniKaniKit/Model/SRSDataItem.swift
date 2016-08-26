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
    func guruDate(_ unlockDateForLockedItems: Date?) -> Date?
    
    /// Returns the earliest possible date an item could be raised to Guru, ignoring current progress and assuming all reviews correct
    func earliestPossibleGuruDate(_ unlockDateForLockedItems: Date?) -> Date?
}

public extension SRSDataItem {
    private static var isRadical: Bool { return self == Radical.self }
    private var isAccelerated: Bool { return WaniKaniAPI.isAccelerated(level: level) }
    
    public func guruDate(_ unlockDateForLockedItems: Date?) -> Date? {
        // Assume best case scenario: the next review is performed as soon as it becomes available (or now, if available now) and is successful
        guard let baseDate = (userSpecificSRSData?.dateAvailable.map { max($0, Date()) }) ?? unlockDateForLockedItems else { return nil }
        
        let initialLevel = (userSpecificSRSData?.srsLevelNumeric ?? 0) + 1
        let guruNumericLevel = SRSLevel.guru.numericLevelThreshold
        
        if initialLevel > guruNumericLevel { return nil }
        else if initialLevel == guruNumericLevel { return baseDate }
        
        return WaniKaniAPI.minimumTime(fromSRSLevel: initialLevel, to: guruNumericLevel, fromDate: baseDate, isRadical: type(of: self).isRadical, isAccelerated: isAccelerated)
    }
    
    public func earliestPossibleGuruDate(_ unlockDateForLockedItems: Date? = nil) -> Date? {
        guard let baseDate = userSpecificSRSData?.dateUnlocked ?? unlockDateForLockedItems else { return nil }
        
        return WaniKaniAPI.minimumTime(fromSRSLevel: 1, to: SRSLevel.guru.numericLevelThreshold, fromDate: baseDate, isRadical: type(of: self).isRadical, isAccelerated: isAccelerated)
    }
}

public struct SRSDataItemSorting {
    public static func byProgress(_ lhs: SRSDataItem, _ rhs: SRSDataItem) -> Bool {
        let u1 = lhs.userSpecificSRSData, u2 = rhs.userSpecificSRSData
        if u1?.srsLevelNumeric == u2?.srsLevelNumeric {
            return (u1?.dateAvailable ?? Date.distantPast) > (u2?.dateAvailable ?? Date.distantPast)
        } else {
            return (u1?.srsLevelNumeric ?? Int.min) < (u2?.srsLevelNumeric ?? Int.min)
        }
    }
}
