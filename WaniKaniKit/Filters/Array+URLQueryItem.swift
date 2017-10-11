//
//  Array+URLQueryItem.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

extension Array where Element == URLQueryItem {
    mutating func appendItemIfSet(name: String, value: String?) {
        guard let value = value else { return }
        
        append(URLQueryItem(name: name, value: value))
    }
    
    mutating func appendItemIfSet<T: LosslessStringConvertible>(name: String, value: T?) {
        guard let value = value else { return }
        
        append(URLQueryItem(name: name, value: String(value)))
    }
    
    mutating func appendItemIfSet<Subject>(name: String, value: Subject?) {
        guard let value = value else { return }
        
        append(URLQueryItem(name: name, value: String(describing: value)))
    }
    
    mutating func appendItemIfSet(name: String, value: Date?) {
        guard let value = value else { return }
        
        append(URLQueryItem(name: name, value: DateFormatter.iso8601.string(from: value)))
    }
    
    mutating func appendItemsIfSet(name: String, values: [String]?) {
        guard let values = values else { return }
        
        append(URLQueryItem(name: name, value: values.joined(separator: ",")))
    }
    
    mutating func appendItemsIfSet<T: LosslessStringConvertible>(name: String, values: [T]?) {
        guard let values = values else { return }
        
        append(URLQueryItem(name: name, value: values.lazy.map({ String($0) }).joined(separator: ",")))
    }
    
    mutating func appendItemsIfSet<Subject>(name: String, values: [Subject]?) {
        guard let values = values else { return }
        
        append(URLQueryItem(name: name, value: values.lazy.map({ String(describing: $0) }).joined(separator: ",")))
    }
}
