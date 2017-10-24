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
    let primaryMeanings = Column(name: "primary_meanings", rank: 10)
    let primaryReadings = Column(name: "primary_readings", rank: 10)
    let nonprimaryMeanings = Column(name: "nonprimary_meanings")
    let nonprimaryReadings = Column(name: "nonprimary_readings")
    
    init() {
        super.init(name: "subject_search")
    }
}
