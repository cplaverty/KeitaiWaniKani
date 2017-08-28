//
//  ResourceRefreshResult.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public enum ResourceRefreshResult: Equatable {
    case success
    case noData
    case error(Error)
}

extension ResourceRefreshResult {
    public static func ==(lhs: ResourceRefreshResult, rhs: ResourceRefreshResult) -> Bool {
        switch (lhs, rhs) {
        case (.success, .success), (.noData, .noData):
            return true
        default:
            return false
        }
    }
}
