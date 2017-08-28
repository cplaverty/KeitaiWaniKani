//
//  ResourceCollection+DatabaseWriteable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB
import os

extension ResourceCollection {
    func write(to database: FMDatabase) throws {
        for resource in data {
            try resource.write(to: database)
        }
    }
}
