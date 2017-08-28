//
//  Array+URLQueryItem.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

extension Array where Element == URLQueryItem {
    mutating func appendItemIfSet(name: String, value: String?) {
        if let value = value {
            append(URLQueryItem(name: name, value: value))
        }
    }
    
    mutating func appendItemIfSet<T: LosslessStringConvertible>(name: String, value: T?) {
        if let value = value {
            append(URLQueryItem(name: name, value: String(value)))
        }
    }
    
    mutating func appendItemIfSet<Subject>(name: String, value: Subject?) {
        if let value = value {
            append(URLQueryItem(name: name, value: String(describing: value)))
        }
    }
    
    mutating func appendItemIfSet(name: String, value: Date?) {
        if let value = value {
            if #available(iOS 10.0, *) {
                let format = ISO8601DateFormatter()
                format.formatOptions = .withInternetDateTime
                format.timeZone = TimeZone(identifier: "UTC")!
                
                append(URLQueryItem(name: name, value: format.string(from: value)))
            } else {
                let format = DateFormatter()
                format.locale = Locale(identifier: "en_US_POSIX")
                format.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
                format.timeZone = TimeZone(identifier: "UTC")!
                
                append(URLQueryItem(name: name, value: format.string(from: value)))
            }
        }
    }
    
    mutating func appendItemsIfSet(name: String, values: [String]?) {
        if let values = values {
            self += values.lazy.map { URLQueryItem(name: name, value: $0) }
        }
    }
    
    mutating func appendItemsIfSet<T: LosslessStringConvertible>(name: String, values: [T]?) {
        if let values = values {
            self += values.lazy.map { URLQueryItem(name: name, value: String($0)) }
        }
    }
    
    mutating func appendItemsIfSet<Subject>(name: String, values: [Subject]?) {
        if let values = values {
            self += values.lazy.map { URLQueryItem(name: name, value: String(describing: $0)) }
        }
    }
}
