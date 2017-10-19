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
        var parameterNames = [String]()
        parameterNames.reserveCapacity(ids.count)
        var queryArgs = [String: Any]()
        queryArgs.reserveCapacity(ids.count)
        
        for (index, id) in ids.enumerated() {
            var parameterName = "id_\(index)"
            parameterNames.append(":" + parameterName)
            queryArgs[parameterName] = id
        }
        
        let query = """
        SELECT \(table.id), \(table.resourceType), \(table.url), \(table.dataUpdatedAt)
        FROM \(table)
        WHERE \(table.id) IN (\(parameterNames.joined(separator: ",")))
        """
        
        guard let resultSet = database.executeQuery(query, withParameterDictionary: queryArgs) else {
            throw database.lastError()
        }
        defer { resultSet.close() }
        
        var foundIDs = [Int]()
        foundIDs.reserveCapacity(ids.count)
        var resourceTypes = [ResourceCollectionItemObjectType]()
        resourceTypes.reserveCapacity(ids.count)
        var urls = [URL]()
        urls.reserveCapacity(ids.count)
        var dataUpdatedAts = [Date]()
        dataUpdatedAts.reserveCapacity(ids.count)
        
        while resultSet.next() {
            foundIDs.append(resultSet.long(forColumn: table.id.name))
            resourceTypes.append(resultSet.rawValue(ResourceCollectionItemObjectType.self, forColumn: table.resourceType.name)!)
            urls.append(resultSet.url(forColumn: table.url.name)!)
            dataUpdatedAts.append(resultSet.date(forColumn: table.dataUpdatedAt.name)!)
        }
        resultSet.close()
        
        let typesByID = zip(foundIDs, resourceTypes).reduce(into: [ResourceCollectionItemObjectType: [Int]]()) { (result, element) in
            let (id, type) = element
            result[type, default: []].append(id)
        }
        
        var dataByID = [Int: ResourceCollectionItemData]()
        dataByID.reserveCapacity(ids.count)
        for (type, ids) in typesByID {
            switch type {
            case .assignment:
                dataByID.merge(try Assignment.read(from: database, ids: ids),
                               uniquingKeysWith: { (lhs, _) in lhs })
            case .radical:
                dataByID.merge(try Radical.read(from: database, ids: ids),
                               uniquingKeysWith: { (lhs, _) in lhs })
            case .kanji:
                dataByID.merge(try Kanji.read(from: database, ids: ids),
                               uniquingKeysWith: { (lhs, _) in lhs })
            case .vocabulary:
                dataByID.merge(try Vocabulary.read(from: database, ids: ids),
                               uniquingKeysWith: { (lhs, _) in lhs })
            case .studyMaterial:
                dataByID.merge(try StudyMaterials.read(from: database, ids: ids),
                               uniquingKeysWith: { (lhs, _) in lhs })
            case .reviewStatistic:
                dataByID.merge(try ReviewStatistics.read(from: database, ids: ids),
                               uniquingKeysWith: { (lhs, _) in lhs })
            }
        }
        
        var items = [ResourceCollectionItem]()
        items.reserveCapacity(ids.count)
        
        for i in 0..<foundIDs.count {
            let id = foundIDs[i]
            guard let data = dataByID[id] else {
                continue
            }
            
            items.append(ResourceCollectionItem(id: id, type: resourceTypes[i], url: urls[i], dataUpdatedAt: dataUpdatedAts[i], data: data))
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
