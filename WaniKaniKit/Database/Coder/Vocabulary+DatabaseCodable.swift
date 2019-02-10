//
//  Vocabulary+DatabaseCodable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB

private let table = Tables.vocabulary

extension Vocabulary: DatabaseCodable {
    static func read(from database: FMDatabase, level: Int) throws -> [ResourceCollectionItem] {
        let query = "SELECT \(table.id) FROM \(table) WHERE \(table.level) = ? AND \(table.hiddenAt) IS NULL"
        
        let resultSet = try database.executeQuery(query, values: [level])
        
        var subjectIDs = [Int]()
        while resultSet.next() {
            subjectIDs.append(resultSet.long(forColumnIndex: 0))
        }
        resultSet.close()
        
        return try ResourceCollectionItem.read(from: database, ids: subjectIDs, type: .vocabulary)
    }
    
    static func read(from database: FMDatabase, ids: [Int]) throws -> [Int: Vocabulary] {
        var items = [Int: Vocabulary]()
        items.reserveCapacity(ids.count)
        
        for id in ids {
            items[id] = try Vocabulary(from: database, id: id)
        }
        
        return items
    }
    
    init(from database: FMDatabase, id: Int) throws {
        let meanings = try Meaning.read(from: database, id: id)
        let auxiliaryMeanings = try AuxiliaryMeaning.read(from: database, id: id)
        let readings = try Reading.read(from: database, id: id)
        let partsOfSpeech = try PartOfSpeech.read(from: database, id: id)
        let subjectComponents = try SubjectRelation.read(from: database, type: .component, id: id)
        let contextSentences = try ContextSentence.read(from: database, id: id)
        let pronunciationAudios = try PronunciationAudio.read(from: database, id: id)
        
        let query = """
        SELECT \(table.createdAt), \(table.level), \(table.slug), \(table.hiddenAt), \(table.documentURL), \(table.characters), \(table.meaningMnemonic), \(table.readingMnemonic), \(table.lessonPosition)
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
        self.characters = resultSet.string(forColumn: table.characters.name)!
        self.meanings = meanings
        self.auxiliaryMeanings = auxiliaryMeanings
        self.readings = readings
        self.partsOfSpeech = partsOfSpeech
        self.componentSubjectIDs = subjectComponents
        self.meaningMnemonic = resultSet.string(forColumn: table.meaningMnemonic.name)!
        self.readingMnemonic = resultSet.string(forColumn: table.readingMnemonic.name)!
        self.contextSentences = contextSentences
        self.pronunciationAudios = pronunciationAudios
        self.lessonPosition = resultSet.long(forColumn: table.lessonPosition.name)
    }
    
    func write(to database: FMDatabase, id: Int) throws {
        try Meaning.write(items: meanings, to: database, id: id)
        try AuxiliaryMeaning.write(items: auxiliaryMeanings, to: database, id: id)
        try Reading.write(items: readings, to: database, id: id)
        try PartOfSpeech.write(items: partsOfSpeech, to: database, id: id)
        try SubjectRelation.write(items: componentSubjectIDs, to: database, type: .component, id: id)
        try ContextSentence.write(items: contextSentences, to: database, id: id)
        try PronunciationAudio.write(items: pronunciationAudios, to: database, id: id)
        
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.id.name), \(table.createdAt.name), \(table.level.name), \(table.slug.name), \(table.hiddenAt.name), \(table.documentURL.name), \(table.characters.name), \(table.meaningMnemonic.name), \(table.readingMnemonic.name), \(table.lessonPosition.name))
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        let values: [Any] = [
            id, createdAt, level, slug, hiddenAt as Any, documentURL.absoluteString, characters, meaningMnemonic, readingMnemonic, lessonPosition
        ]
        try database.executeUpdate(query, values: values)
        
        try SubjectSearch.write(to: database, id: id, characters: characters, level: level, meanings: meanings, readings: readings, hidden: hiddenAt != nil)
    }
}

struct PartOfSpeech: BulkDatabaseCodable {
    private static let table = Tables.vocabularyPartsOfSpeech
    
    static func read(from database: FMDatabase, id: Int) throws -> [String] {
        let query = """
        SELECT \(table.partOfSpeech)
        FROM \(table)
        WHERE \(table.subjectID) = ?
        ORDER BY \(table.index)
        """
        
        let resultSet = try database.executeQuery(query, values: [id])
        defer { resultSet.close() }
        
        var items = [String]()
        while resultSet.next() {
            items.append(resultSet.string(forColumn: table.partOfSpeech.name)!)
        }
        
        return items
    }
    
    static func read(from database: FMDatabase, ids: [Int]) throws -> [Int: [String]] {
        var items = [Int: [String]]()
        items.reserveCapacity(ids.count)
        
        for id in ids {
            items[id] = try read(from: database, id: id)
        }
        
        return items
    }
    
    static func write(items: [String], to database: FMDatabase, id: Int) throws {
        try database.executeUpdate("DELETE FROM \(table) WHERE \(table.subjectID) = ?", values: [id])
        
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.subjectID.name), \(table.index.name), \(table.partOfSpeech.name))
        VALUES (?, ?, ?)
        """
        
        for (index, item) in items.enumerated() {
            let values: [Any] = [
                id, index, item
            ]
            try database.executeUpdate(query, values: values)
        }
    }
}

extension Vocabulary.ContextSentence: BulkDatabaseCodable {
    private static let contextSentencesTable = Tables.vocabularyContextSentences
    
    static func read(from database: FMDatabase, id: Int) throws -> [Vocabulary.ContextSentence] {
        let table = contextSentencesTable
        
        let query = """
        SELECT \(table.english), \(table.japanese)
        FROM \(table)
        WHERE \(table.subjectID) = ?
        ORDER BY \(table.index)
        """
        
        let resultSet = try database.executeQuery(query, values: [id])
        defer { resultSet.close() }
        
        var index = 0
        var items = [Vocabulary.ContextSentence]()
        while resultSet.next() {
            items.append(Vocabulary.ContextSentence(english: resultSet.string(forColumn: table.english.name)!,
                                                    japanese: resultSet.string(forColumn: table.japanese.name)!))
            index += 1
        }
        
        return items
    }
    
    static func read(from database: FMDatabase, ids: [Int]) throws -> [Int: [Vocabulary.ContextSentence]] {
        var items = [Int: [Vocabulary.ContextSentence]]()
        items.reserveCapacity(ids.count)
        
        for id in ids {
            items[id] = try read(from: database, id: id)
        }
        
        return items
    }
    
    static func write(items: [Vocabulary.ContextSentence], to database: FMDatabase, id: Int) throws {
        let table = contextSentencesTable
        
        try database.executeUpdate("DELETE FROM \(table) WHERE \(table.subjectID) = ?", values: [id])
        
        let query = """
        INSERT OR REPLACE INTO \(table)
        (\(table.subjectID.name), \(table.index.name), \(table.english.name), \(table.japanese.name))
        VALUES (?, ?, ?, ?)
        """
        
        for (index, item) in items.enumerated() {
            let values: [Any] = [
                id, index, item.english, item.japanese
            ]
            try database.executeUpdate(query, values: values)
        }
    }
}

extension Vocabulary.PronunciationAudio: BulkDatabaseCodable {
    private static let audioTable = Tables.vocabularyPronunciationAudios
    private static let metadataTable = Tables.vocabularyPronunciationAudiosMetadata
    
    static func read(from database: FMDatabase, id: Int) throws -> [Vocabulary.PronunciationAudio] {
        let allMetadata = try readMetadata(from: database, id: id)
        
        let table = audioTable
        
        let query = """
        SELECT \(table.url), \(table.contentType)
        FROM \(table)
        WHERE \(table.subjectID) = ?
        ORDER BY \(table.index)
        """
        
        let resultSet = try database.executeQuery(query, values: [id])
        defer { resultSet.close() }
        
        var index = 0
        var items = [Vocabulary.PronunciationAudio]()
        while resultSet.next() {
            items.append(Vocabulary.PronunciationAudio(url: resultSet.url(forColumn: table.url.name)!,
                                                       metadata: allMetadata[index]!,
                                                       contentType: resultSet.string(forColumn: table.contentType.name)!))
            index += 1
        }
        
        return items
    }
    
    static func read(from database: FMDatabase, ids: [Int]) throws -> [Int: [Vocabulary.PronunciationAudio]] {
        var items = [Int: [Vocabulary.PronunciationAudio]]()
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
            return Metadata(gender: dictionary[Metadata.CodingKeys.gender.rawValue]!,
                            sourceID: dictionary[Metadata.CodingKeys.sourceID.rawValue].flatMap({ Int($0) })!,
                            pronunciation: dictionary[Metadata.CodingKeys.pronunciation.rawValue]!,
                            voiceActorID: dictionary[Metadata.CodingKeys.voiceActorID.rawValue].flatMap({ Int($0) })!,
                            voiceActorName: dictionary[Metadata.CodingKeys.voiceActorName.rawValue]!,
                            voiceDescription: dictionary[Metadata.CodingKeys.voiceDescription.rawValue]!)
        })
    }
    
    static func write(items: [Vocabulary.PronunciationAudio], to database: FMDatabase, id: Int) throws {
        try database.executeUpdate("DELETE FROM \(audioTable) WHERE \(audioTable.subjectID) = ?", values: [id])
        try database.executeUpdate("DELETE FROM \(metadataTable) WHERE \(metadataTable.subjectID) = ?", values: [id])
        
        let table = audioTable
        
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
        try writeMetadataAttributeIfPresent(key: .gender, value: metadata.gender, to: database, id: id, index: index)
        try writeMetadataAttributeIfPresent(key: .sourceID, value: metadata.sourceID, to: database, id: id, index: index)
        try writeMetadataAttributeIfPresent(key: .pronunciation, value: metadata.pronunciation, to: database, id: id, index: index)
        try writeMetadataAttributeIfPresent(key: .voiceActorID, value: metadata.voiceActorID, to: database, id: id, index: index)
        try writeMetadataAttributeIfPresent(key: .voiceActorName, value: metadata.voiceActorName, to: database, id: id, index: index)
        try writeMetadataAttributeIfPresent(key: .voiceDescription, value: metadata.voiceDescription, to: database, id: id, index: index)
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
