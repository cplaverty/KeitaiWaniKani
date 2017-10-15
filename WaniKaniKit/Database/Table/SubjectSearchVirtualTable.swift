//
//  SubjectSearchVirtualTable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import Foundation

final class SubjectSearchVirtualTable: Table {
    let subjectID = "docid"
    let character = Column(name: "characters", type: .text, nullable: true)
    let primaryMeanings = Column(name: "primary_meanings", type: .text, nullable: false)
    let primaryReadings = Column(name: "primary_readings", type: .text, nullable: false)
    let nonprimaryMeanings = Column(name: "nonprimary_meanings", type: .text, nullable: false)
    let nonprimaryReadings = Column(name: "nonprimary_readings", type: .text, nullable: false)
    
    init() {
        super.init(name: "subject_search", isVirtual: true)
    }
}
