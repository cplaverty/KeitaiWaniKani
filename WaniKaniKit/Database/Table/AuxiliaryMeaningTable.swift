//
//  AuxiliaryMeaningTable.swift
//  WaniKaniKit
//
//  Copyright © 2019 Chris Laverty. All rights reserved.
//

final class AuxiliaryMeaningTable: Table {
    let subjectID = Column(name: "subject_id", type: .int, nullable: false, primaryKey: true)
    let index = Column(name: "idx", type: .int, nullable: false, primaryKey: true)
    let type = Column(name: "type", type: .text, nullable: false)
    let meaning = Column(name: "meaning", type: .text, nullable: false)

    init() {
        super.init(name: "auxiliary_meanings")
    }
}
