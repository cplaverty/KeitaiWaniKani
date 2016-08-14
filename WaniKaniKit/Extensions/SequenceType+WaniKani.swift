//
//  SequenceType+WaniKani.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import OperationKit

public extension Sequence where Self.Iterator.Element == Error {
    func filterNonFatalErrors() -> [Self.Iterator.Element] {
        return self.filter {
            switch $0 {
            case ModelObjectUpdateCheckConditionError.noUpdateRequired,
                 StudyQueueIsUpdatedConditionError.notUpdated,
                 UserNotificationConditionError.settingsMismatch:
                return false
            default: return true
            }
        }
    }
}
