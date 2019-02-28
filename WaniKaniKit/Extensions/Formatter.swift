//
//  Formatter.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import Foundation

extension DateFormatter {
    static let iso8601 = iso8601Formatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX")
    static let iso8601WithoutFractionalSeconds = iso8601Formatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ssXXXXX")
    
    private static func iso8601Formatter(dateFormat: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = dateFormat
        
        return formatter
    }
}
