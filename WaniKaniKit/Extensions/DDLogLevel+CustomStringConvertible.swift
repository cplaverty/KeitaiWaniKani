//
//  DDLogLevel+CustomStringConvertible.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import CocoaLumberjack

extension DDLogLevel: CustomStringConvertible {
    public var description: String {
        switch self {
        case .off: return "Off"
        case .error: return "Error"
        case .warning: return "Warning"
        case .info: return "Info"
        case .debug: return "Debug"
        case .verbose: return "Verbose"
        case .all: return "All"
        }
    }
}
