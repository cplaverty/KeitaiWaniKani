//
//  CollectionType+WaniKani.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import OperationKit

public extension CollectionType where Self.Generator.Element == ErrorType {
    func filterNonFatalErrors() -> [Self.Generator.Element] {
        return self.filter {
            switch $0 {
            case ModelObjectUpdateCheckConditionError.NoUpdateRequired,
            StudyQueueIsUpdatedConditionError.NotUpdated,
            UserNotificationConditionError.SettingsMismatch:
                return false
            default: return true
            }
        }
    }
}
