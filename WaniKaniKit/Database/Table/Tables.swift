//
//  Tables.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

struct Tables {
    static let assignments = AssignmentTable()
    static let kanji = KanjiTable()
    static let levelProgression = LevelProgressionTable()
    static let meanings = MeaningTable()
    static let radicals = RadicalTable()
    static let radicalCharacterImages = RadicalCharacterImagesTable()
    static let readings = ReadingTable()
    static let resources = ResourceTable()
    static let resourceLastUpdate = ResourceLastUpdateTable()
    static let reviewStatistics = ReviewStatisticsTable()
    static let studyMaterials = StudyMaterialsTable()
    static let studyMaterialsMeaningSynonyms = StudyMaterialsMeaningSynonymsTable()
    static let subjectComponents = SubjectComponentsTable()
    static let subjectSearch = SubjectSearchVirtualTable()
    static let userInformation = UserInformationTable()
    static let vocabulary = VocabularyTable()
    static let vocabularyPartsOfSpeech = VocabularyPartsOfSpeechTable()
    
    static var all: [TableProtocol] {
        return [
            assignments, kanji, levelProgression, meanings, radicals, radicalCharacterImages, readings, resources,
            resourceLastUpdate, reviewStatistics, studyMaterials, studyMaterialsMeaningSynonyms,
            subjectComponents, subjectSearch, userInformation, vocabulary, vocabularyPartsOfSpeech
        ]
    }
}
