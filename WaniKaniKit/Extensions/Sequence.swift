//
//  Sequence.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

extension Sequence {
    public func group<Key: Hashable>(by: (Element) throws -> Key) rethrows -> [Key: [Element]] {
        return try reduce(into: [:]) { (grouping, element) in
            let key = try by(element)
            grouping[key, default: []].append(element)
        }
    }
}
