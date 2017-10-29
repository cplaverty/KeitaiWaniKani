//
//  SubjectSearchVirtualTable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import Foundation

final class SubjectSearchVirtualTable: VirtualTable {
    let subjectID = "rowid"
    let character = Column(name: "characters", rank: 25)
    let level = Column(name: "level")
    let primaryMeanings = Column(name: "primary_meaning", rank: 10)
    let primaryReadings = Column(name: "primary_reading", rank: 10)
    let nonprimaryMeanings = Column(name: "nonprimary_meaning")
    let nonprimaryReadings = Column(name: "nonprimary_reading")
    
    init() {
        super.init(name: "subject_search")
    }
}
