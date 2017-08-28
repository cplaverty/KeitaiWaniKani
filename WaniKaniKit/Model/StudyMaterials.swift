//
//  StudyMaterials.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct StudyMaterials: ResourceCollectionItemData {
    public let createdAt: Date
    public let subjectID: Int
    public let subjectType: SubjectType
    public let meaningNote: String?
    public let readingNote: String?
    public let meaningSynonyms: [String]
    
    private enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case subjectID = "subject_id"
        case subjectType = "subject_type"
        case meaningNote = "meaning_note"
        case readingNote = "reading_note"
        case meaningSynonyms = "meaning_synonyms"
    }
}

extension StudyMaterials: Equatable {
    public static func ==(lhs: StudyMaterials, rhs: StudyMaterials) -> Bool {
        return lhs.createdAt == rhs.createdAt
            && lhs.subjectID == rhs.subjectID
            && lhs.subjectType == rhs.subjectType
            && lhs.meaningNote == rhs.meaningNote
            && lhs.readingNote == rhs.readingNote
            && lhs.meaningSynonyms == rhs.meaningSynonyms
    }
}
