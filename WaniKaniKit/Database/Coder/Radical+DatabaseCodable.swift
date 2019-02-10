//
//  Radical+DatabaseCodable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB

private let table = Tables.radicals

extension Radical: DatabaseCodable {
    static func read(from database: FMDatabase, level: Int) throws -> [ResourceCollectionItem] {
        let query = "SELECT \(table.id) FROM \(table) WHERE \(table.level) = ? AND \(table.hiddenAt) IS NULL"
        
        let resultSet = try database.executeQuery(query, values: [level])
        
        var subjectIDs = [Int]()
        while resultSet.next() {
            subjectIDs.append(resultSet.long(forColumnIndex: 0))
        }
        resultSet.close()
        
        return try ResourceCollectionItem.read(from: database, ids: subjectIDs, type: .radical)
    }
    
    static func read(from database: FMDatabase, ids: [Int]) throws -> [Int: Radical] {
        var items = [Int: Radical]()
        items.reserveCapacity(ids.count)
        
        for id in ids {
            items[id] = try Radical(from: database, id: id)
        }
        
        return items
    }
    
    init(from database: FMDatabase, id: Int) throws {
        let characterImages = try CharacterImage.read(from: database, id: id)
        let meanings = try Meaning.read(from: database, id: id)
        let auxiliaryMeaning = try AuxiliaryMeaning.read(from: database, id: id)
        let subjectAmalgamation = try SubjectRelation.read(from: database, type: .amalgamation, id: id)
        
        let query = """
        SELECT \(table.createdAt), \(table.level), \(table.slug), \(table.hiddenAt), \(table.documentURL), \(table.characters), \(table.meaningMnemonic), \(table.lessonPosition)
        FROM \(table)
        WHERE \(table.id) = ?
        """
        
        let resultSet = try database.executeQuery(query, values: [id])
        defer { resultSet.close() }
        
        guard resultSet.next() else {
            throw DatabaseError.itemNotFound(id: id)
        }
        
        self.createdAt = resultSet.date(forColumn: table.createdAt.name)!
        self.level = resultSet.long(forColumn: table.level.name)
        self.slug = resultSet.string(forColumn: table.slug.name)!
        self.hiddenAt = resultSet.date(forColumn: table.hiddenAt.name)
        self.documentURL = resultSet.url(forColumn: table.documentURL.name)!
        self.characters = resultSet.string(forColumn: table.characters.name)
        self.characterImages = characterImages
        self.meanings = meanings
        self.auxiliaryMeanings = auxiliaryMeaning
        self.amalgamationSubjectIDs = subjectAmalgamation
        self.meaningMnemonic = resultSet.string(forColumn: table.meaningMnemonic.name)!
        self.lessonPosition = resultSet.long(forColumn: table.lessonPosition.name)
    }
    
    func write(to database: FMDatabase, id: Int) throws {
        try CharacterImage.write(items: characterImages, to: database, id: id)
        try Meaning.write(items: meanings, to: database, id: id)
        try AuxiliaryMeaning.write(items: auxiliaryMeanings, to: database, id: id)
        try SubjectRelation.write(items: amalgamationSubjectIDs, to: database, type: .amalgamation, id: id)
        
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.id.name), \(table.createdAt.name), \(table.level.name), \(table.slug.name), \(table.hiddenAt.name), \(table.documentURL.name), \(table.characters.name), \(table.meaningMnemonic.name), \(table.lessonPosition.name))
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        let values: [Any] = [
            id, createdAt, level, slug, hiddenAt as Any, documentURL.absoluteString, characters as Any, meaningMnemonic, lessonPosition
        ]
        try database.executeUpdate(query, values: values)
        
        try SubjectSearch.write(to: database, id: id, characters: characters, level: level, meanings: meanings, readings: [], hidden: hiddenAt != nil)
    }
}

extension Radical.CharacterImage: BulkDatabaseCodable {
    private static let imagesTable = Tables.radicalCharacterImages
    private static let metadataTable = Tables.radicalCharacterImagesMetadata
    
    static func read(from database: FMDatabase, id: Int) throws -> [Radical.CharacterImage] {
        let allMetadata = try readMetadata(from: database, id: id)
        
        let table = imagesTable
        
        let query = """
        SELECT \(table.url), \(table.contentType)
        FROM \(table)
        WHERE \(table.subjectID) = ?
        ORDER BY \(table.index)
        """
        
        let resultSet = try database.executeQuery(query, values: [id])
        defer { resultSet.close() }
        
        var index = 0
        var items = [Radical.CharacterImage]()
        while resultSet.next() {
            items.append(Radical.CharacterImage(url: resultSet.url(forColumn: table.url.name)!,
                                                metadata: allMetadata[index]!,
                                                contentType: resultSet.string(forColumn: table.contentType.name)!))
            index += 1
        }
        
        return items
    }
    
    static func read(from database: FMDatabase, ids: [Int]) throws -> [Int: [Radical.CharacterImage]] {
        var items = [Int: [Radical.CharacterImage]]()
        items.reserveCapacity(ids.count)
        
        for id in ids {
            items[id] = try read(from: database, id: id)
        }
        
        return items
    }
    
    private static func readMetadata(from database: FMDatabase, id: Int) throws -> [Int: Metadata] {
        let table = metadataTable
        
        let query = """
        SELECT \(table.index), \(table.key), \(table.value)
        FROM \(table)
        WHERE \(table.subjectID) = ?
        ORDER BY \(table.index)
        """
        
        let resultSet = try database.executeQuery(query, values: [id])
        defer { resultSet.close() }
        
        var items = [Int: [String: String]]()
        while resultSet.next() {
            let index = resultSet.long(forColumn: table.index.name)
            let key = resultSet.string(forColumn: table.key.name)!
            let value = resultSet.string(forColumn: table.value.name)!
            var metadataForItem = items[index, default: [String: String]()]
            metadataForItem[key] = value
            items[index] = metadataForItem
        }
        
        return items.mapValues({ dictionary in
            return Metadata(color: dictionary[Metadata.CodingKeys.color.rawValue],
                            dimensions: dictionary[Metadata.CodingKeys.dimensions.rawValue],
                            styleName: dictionary[Metadata.CodingKeys.styleName.rawValue],
                            inlineStyles: dictionary[Metadata.CodingKeys.inlineStyles.rawValue].flatMap({ Bool($0) })
            )
        })
    }
    
    static func write(items: [Radical.CharacterImage], to database: FMDatabase, id: Int) throws {
        try database.executeUpdate("DELETE FROM \(imagesTable) WHERE \(imagesTable.subjectID) = ?", values: [id])
        try database.executeUpdate("DELETE FROM \(metadataTable) WHERE \(metadataTable.subjectID) = ?", values: [id])
        
        let table = imagesTable
        
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.subjectID.name), \(table.index.name), \(table.url.name), \(table.contentType.name))
        VALUES (?, ?, ?, ?)
        """
        
        for (index, item) in items.enumerated() {
            let values: [Any] = [
                id, index, item.url.absoluteString, item.contentType
            ]
            try database.executeUpdate(query, values: values)
            
            try write(metadata: item.metadata, to: database, id: id, index: index)
        }
    }
    
    private static func write(metadata: Metadata, to database: FMDatabase, id: Int, index: Int) throws {
        try writeMetadataAttributeIfPresent(key: .color, value: metadata.color, to: database, id: id, index: index)
        try writeMetadataAttributeIfPresent(key: .dimensions, value: metadata.dimensions, to: database, id: id, index: index)
        try writeMetadataAttributeIfPresent(key: .styleName, value: metadata.styleName, to: database, id: id, index: index)
        try writeMetadataAttributeIfPresent(key: .inlineStyles, value: metadata.inlineStyles, to: database, id: id, index: index)
    }
    
    private static func writeMetadataAttributeIfPresent<T>(key: Metadata.CodingKeys, value: T?, to database: FMDatabase, id: Int, index: Int) throws {
        guard let value = value else {
            return
        }
        
        let table = metadataTable
        
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.subjectID.name), \(table.index.name), \(table.key.name), \(table.value.name))
        VALUES (?, ?, ?, ?)
        """
        
        try database.executeUpdate(query, values: [id, index, key.rawValue, value])
    }
}
