//
//  ResourceCollectionItem+DatabaseCodable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB

private let table = Tables.resources

extension ResourceCollectionItem {
    static func read(from database: FMDatabase, ids: [Int]) throws -> [ResourceCollectionItem] {
        var items = [ResourceCollectionItem]()
        items.reserveCapacity(ids.count)
        
        for id in ids {
            items.append(try ResourceCollectionItem(from: database, id: id))
        }
        
        return items
    }
    
    init(from database: FMDatabase, id: Int) throws {
        let query = """
        SELECT \(table.resourceType), \(table.url), \(table.dataUpdatedAt)
        FROM \(table)
        WHERE \(table.id) = ?
        """
        
        let resultSet = try database.executeQuery(query, values: [id])
        
        guard resultSet.next() else {
            resultSet.close()
            throw DatabaseError.itemNotFound(id: id)
        }
        
        let type = resultSet.rawValue(ResourceCollectionItemObjectType.self, forColumn: table.resourceType.name)!
        self.id = id
        self.type = type
        self.url = resultSet.url(forColumn: table.url.name)!
        self.dataUpdatedAt = resultSet.date(forColumn: table.dataUpdatedAt.name)!
        resultSet.close()
        
        let data: ResourceCollectionItemData
        switch type {
        case .assignment:
            data = try Assignment(from: database, id: id)
        case .radical:
            data = try Radical(from: database, id: id)
        case .kanji:
            data = try Kanji(from: database, id: id)
        case .vocabulary:
            data = try Vocabulary(from: database, id: id)
        case .studyMaterial:
            data = try StudyMaterials(from: database, id: id)
        case .reviewStatistic:
            data = try ReviewStatistics(from: database, id: id)
        case .levelProgression:
            data = try LevelProgression(from: database, id: id)
        }
        
        self.data = data
    }
    
    func write(to database: FMDatabase) throws {
        switch data {
        case let writable as DatabaseWriteable:
            try writable.write(to: database, id: id)
        default:
            fatalError("Unable to persist data (does not implement DatabaseWriteable)")
        }
        
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.id.name), \(table.resourceType.name), \(table.url.name), \(table.dataUpdatedAt.name))
        VALUES (?, ?, ?, ?)
        """
        
        let values: [Any] = [
            id, type.rawValue, url.absoluteString, dataUpdatedAt
        ]
        try database.executeUpdate(query, values: values)
    }
}
