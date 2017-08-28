//
//  Sequence.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

extension Sequence {
    func group<Key: Hashable>(by: (Element) throws -> Key) rethrows -> [Key: [Element]] {
        return try reduce(into: [:]) { (grouping, element) in
            let key = try by(element)
            
            guard let _ = grouping[key]?.append(element) else {
                grouping[key] = [element]
                return
            }
        }
    }
}
