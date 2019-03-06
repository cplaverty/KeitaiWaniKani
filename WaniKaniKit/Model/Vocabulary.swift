//
//  Vocabulary.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct Vocabulary: ResourceCollectionItemData, Equatable {
    public let createdAt: Date
    public let level: Int
    public let slug: String
    public let hiddenAt: Date?
    public let documentURL: URL
    public let characters: String
    public let meanings: [Meaning]
    public let auxiliaryMeanings: [AuxiliaryMeaning]
    public let readings: [Reading]
    public let partsOfSpeech: [String]
    public let componentSubjectIDs: [Int]
    public let meaningMnemonic: String
    public let readingMnemonic: String
    public let contextSentences: [ContextSentence]
    public let pronunciationAudios: [PronunciationAudio]
    public let lessonPosition: Int
    
    public var normalisedPartsOfSpeech: [String] {
        get {
            return partsOfSpeech.map({ normalisePartOfSpeech($0).capitalized })
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case level
        case slug
        case hiddenAt = "hidden_at"
        case documentURL = "document_url"
        case characters
        case meanings
        case auxiliaryMeanings = "auxiliary_meanings"
        case readings
        case partsOfSpeech = "parts_of_speech"
        case componentSubjectIDs = "component_subject_ids"
        case meaningMnemonic = "meaning_mnemonic"
        case readingMnemonic = "reading_mnemonic"
        case contextSentences = "context_sentences"
        case pronunciationAudios = "pronunciation_audios"
        case lessonPosition = "lesson_position"
    }
    
    private func normalisePartOfSpeech(_ str: String) -> String {
        switch str {
        case "godan_verb":
            return "godan verb"
        case "i_adjective":
            return "い adjective"
        case "ichidan_verb":
            return "ichidan verb"
        case "intransitive_verb":
            return "intransitive verb"
        case "na_adjective":
            return "な adjective"
        case "no_adjective":
            return "の adjective"
        case "proper_noun":
            return "proper noun"
        case "suru_verb":
            return "する verb"
        case "transitive_verb":
            return "transitive verb"
        default:
            return str
        }
    }
}

extension Vocabulary: Subject {
    public var subjectType: SubjectType {
        return .vocabulary
    }
}

extension Vocabulary {
    public struct ContextSentence: Codable, Equatable {
        public let english: String
        public let japanese: String
        
        private enum CodingKeys: String, CodingKey {
            case english = "en"
            case japanese = "ja"
        }
    }
}

extension Vocabulary {
    public var allReadings: String {
        return readings.lazy
            .map({ $0.reading })
            .joined(separator: ", ")
    }
}

extension Vocabulary {
    public struct PronunciationAudio: Codable, Equatable {
        public let url: URL
        public let metadata: Metadata
        public let contentType: String
        
        private enum CodingKeys: String, CodingKey {
            case url
            case metadata
            case contentType = "content_type"
        }
    }
}

extension Vocabulary.PronunciationAudio {
    public struct Metadata: Codable, Equatable {
        public let gender: String
        public let sourceID: Int
        public let pronunciation: String
        public let voiceActorID: Int
        public let voiceActorName: String
        public let voiceDescription: String
        
        enum CodingKeys: String, CodingKey {
            case gender
            case sourceID = "source_id"
            case pronunciation
            case voiceActorID = "voice_actor_id"
            case voiceActorName = "voice_actor_name"
            case voiceDescription = "voice_description"
        }
    }
}
