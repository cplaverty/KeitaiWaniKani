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
        case Off: return "Off"
        case Error: return "Error"
        case Warning: return "Warning"
        case Info: return "Info"
        case Debug: return "Debug"
        case Verbose: return "Verbose"
        case All: return "All"
        }
    }
}
