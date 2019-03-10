//
//  Collection.swift
//  AlliCrab
//
//  Copyright © 2019 Chris Laverty. All rights reserved.
//

extension Collection where Element: Hashable {
    func filterDuplicates() -> [Element] {
        var set = Set<Element>(minimumCapacity: count)
        return filter {
            set.insert($0).inserted
        }
    }
}
