//
//  ResourceCollectionItem+DatabaseCodable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB

private let table = Tables.resources

extension ResourceCollectionItem {
    static func read(from database: FMDatabase, ids: [Int], type: ResourceCollectionItemObjectType) throws -> [ResourceCollectionItem] {
        var items = [ResourceCollectionItem]()
        items.reserveCapacity(ids.count)
        
        for id in ids {
            items.append(try ResourceCollectionItem(from: database, id: id, type: type))
        }
        
        return items
    }
    
    static func readSubjects(from database: FMDatabase, ids: [Int]) throws -> [ResourceCollectionItem] {
        var items = [ResourceCollectionItem]()
        items.reserveCapacity(ids.count)
        
        for id in ids {
            let item = try readSubject(from: database, id: id)
            items.append(item)
        }
        
        return items
    }
    
    static func readSubject(from database: FMDatabase, id: Int) throws -> ResourceCollectionItem {
        let type = try getSubjectTypeForSubjectId(from: database, id: id)
        return try ResourceCollectionItem(from: database, id: id, type: type)
    }
    
    private static func getSubjectTypeForSubjectId(from database: FMDatabase, id: Int) throws -> ResourceCollectionItemObjectType {
        let subjects = Tables.subjectsView
        
        let query = """
        SELECT \(subjects.subjectType)
        FROM \(subjects)
        WHERE \(subjects.id) = ?
        """
        
        let resultSet = try database.executeQuery(query, values: [id])
        defer { resultSet.close() }
        
        guard resultSet.next() else {
            throw DatabaseError.itemNotFound(id: id)
        }
        
        let subjectType = resultSet.rawValue(SubjectType.self, forColumn: subjects.subjectType.name)!
        
        switch subjectType {
        case .radical: return .radical
        case .kanji: return .kanji
        case .vocabulary: return .vocabulary
        }
    }
    
    init(from database: FMDatabase, id: Int, type: ResourceCollectionItemObjectType) throws {
        let query = """
        SELECT \(table.url), \(table.dataUpdatedAt)
        FROM \(table)
        WHERE \(table.id) = ?
        AND \(table.resourceType) = ?
        """
        
        let resultSet = try database.executeQuery(query, values: [id, type.rawValue])
        
        guard resultSet.next() else {
            resultSet.close()
            throw DatabaseError.itemNotFound(id: id)
        }
        
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
        guard let writable = data as? DatabaseWritable else {
            fatalError("Unable to persist data (does not implement DatabaseWritable)")
        }
        
        try writable.write(to: database, id: id)
        
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
