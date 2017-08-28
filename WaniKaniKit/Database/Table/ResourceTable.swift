//
//  ResourceTable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

final class ResourceTable: Table {
    let id = Column(name: "id", type: .int, nullable: false, primaryKey: true)
    let resourceType = Column(name: "type", type: .text, nullable: false, primaryKey: true)
    let url = Column(name: "url", type: .text, nullable: false)
    let dataUpdatedAt = Column(name: "data_updated_at", type: .float, nullable: false)
    
    init() {
        super.init(name: "resources")
    }
}
