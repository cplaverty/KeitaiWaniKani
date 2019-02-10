//
//  Tables.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

struct Tables {
    static let assignments = AssignmentTable()
    static let auxiliaryMeanings = AuxiliaryMeaningTable()
    static let kanji = KanjiTable()
    static let levelProgression = LevelProgressionTable()
    static let meanings = MeaningTable()
    static let radicals = RadicalTable()
    static let radicalCharacterImages = RadicalCharacterImagesTable()
    static let radicalCharacterImagesMetadata = RadicalCharacterImagesMetadataTable()
    static let readings = ReadingTable()
    static let resources = ResourceTable()
    static let resourceLastUpdate = ResourceLastUpdateTable()
    static let reviewStatistics = ReviewStatisticsTable()
    static let studyMaterials = StudyMaterialsTable()
    static let studyMaterialsMeaningSynonyms = StudyMaterialsMeaningSynonymsTable()
    static let subjectRelations = SubjectRelationsTable()
    static let subjectSearch = SubjectSearchVirtualTable()
    static let userInformation = UserInformationTable()
    static let vocabulary = VocabularyTable()
    static let vocabularyContextSentences = VocabularyContextSentencesTable()
    static let vocabularyPartsOfSpeech = VocabularyPartsOfSpeechTable()
    static let vocabularyPronunciationAudios = VocabularyPronunciationAudiosTable()
    static let vocabularyPronunciationAudiosMetadata = VocabularyPronunciationAudiosMetadataTable()
    
    static let subjectsView = SubjectsView(radicals: radicals, kanji: kanji, vocabulary: vocabulary)
    
    static var all: [TableProtocol] {
        return [
            assignments,
            auxiliaryMeanings,
            kanji,
            levelProgression,
            meanings,
            radicals,
            radicalCharacterImages,
            radicalCharacterImagesMetadata,
            readings,
            resources,
            resourceLastUpdate,
            reviewStatistics,
            studyMaterials,
            studyMaterialsMeaningSynonyms,
            subjectRelations,
            subjectSearch,
            userInformation,
            vocabulary,
            vocabularyContextSentences,
            vocabularyPartsOfSpeech,
            vocabularyPronunciationAudios,
            vocabularyPronunciationAudiosMetadata,
            subjectsView
        ]
    }
    
    static func subjectTable(for subjectType: SubjectType) -> SubjectTable {
        switch subjectType {
        case .radical: return Tables.radicals
        case .kanji: return Tables.kanji
        case .vocabulary: return Tables.vocabulary
        }
    }
}
