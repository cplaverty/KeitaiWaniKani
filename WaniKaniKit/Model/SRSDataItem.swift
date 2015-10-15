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
    private var isAccelerated: Bool { return level <= 2 }
    
    public func guruDate(unlockDateForLockedItems: NSDate?) -> NSDate? {
        // Assume best case scenario: the next review is successful
        guard let baseDate = userSpecificSRSData?.dateAvailable?.laterDate(NSDate()) ?? unlockDateForLockedItems else { return nil }

        let initialLevel = (userSpecificSRSData?.srsLevelNumeric ?? 0) + 1
        let guruNumericLevel = SRSLevel.Guru.numericLevelThreshold
        
        if initialLevel > guruNumericLevel { return nil }
        else if initialLevel == guruNumericLevel { return baseDate }
        
        return minimumTimeFromLevel(initialLevel, toLevel: guruNumericLevel, fromDate: baseDate)
    }
    
    public func earliestPossibleGuruDate(unlockDateForLockedItems: NSDate? = nil) -> NSDate? {
        guard let baseDate = userSpecificSRSData?.dateUnlocked ?? unlockDateForLockedItems else { return nil }
        
        return minimumTimeFromLevel(1, toLevel: SRSLevel.Guru.numericLevelThreshold, fromDate: baseDate)
    }
    
    private func minimumTimeFromLevel(initialLevel: Int, toLevel finalLevel: Int, fromDate baseDate: NSDate) -> NSDate? {
        let isRadical = self.dynamicType.isRadical
        let isAccelerated = self.isAccelerated
        var guruDate = baseDate
        let calendar = NSCalendar.autoupdatingCurrentCalendar()
        for level in initialLevel..<finalLevel {
            guard let timeForLevel = timeToNextReviewForLevel(level, isRadical: isRadical, isAccelerated: isAccelerated) else { return nil }
            guruDate = calendar.dateByAddingComponents(timeForLevel, toDate: guruDate, options: [])!
        }
        
        return guruDate
    }
    
    private func timeToNextReviewForLevel(srsLevelNumeric: Int, isRadical: Bool, isAccelerated: Bool) -> NSDateComponents? {
        switch srsLevelNumeric {
        case 1 where isAccelerated:
            let dc = NSDateComponents()
            dc.hour = 2
            return dc
        case 1, 2 where isAccelerated:
            let dc = NSDateComponents()
            dc.hour = 4
            return dc
        case 2, 3 where isAccelerated:
            let dc = NSDateComponents()
            dc.hour = 8
            return dc
        case 3, 4 where isAccelerated:
            let dc = NSDateComponents()
            dc.day = 1
            dc.hour = -1
            return dc
        case 4:
            let dc = NSDateComponents()
            dc.day = isRadical ? 2 : 3
            dc.hour = -1
            return dc
        case 5: // -> 6
            let dc = NSDateComponents()
            dc.day = 7
            dc.hour = -1
            return dc
        case 6: // -> 7
            let dc = NSDateComponents()
            dc.day = 14
            dc.hour = -1
            return dc
        case 7: // -> 8
            let dc = NSDateComponents()
            dc.month = 1
            dc.hour = -1
            return dc
        case 8: // -> 9
            let dc = NSDateComponents()
            dc.month = 4
            dc.hour = -1
            return dc
        default: return nil
        }
    }
}
