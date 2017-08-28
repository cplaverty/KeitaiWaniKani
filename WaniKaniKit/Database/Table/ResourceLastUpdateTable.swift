//
//  ResourceLastUpdateTable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

final class ResourceLastUpdateTable: Table {
    let resourceType = Column(name: "type", type: .text, nullable: false, primaryKey: true)
    let dataUpdatedAt = Column(name: "data_updated_at", type: .float, nullable: false)
    
    init() {
        super.init(name: "resource_last_update")
    }
}
