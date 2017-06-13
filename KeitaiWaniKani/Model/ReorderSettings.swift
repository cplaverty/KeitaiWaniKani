//
//  ReorderSettings.swift
//  AlliCrab
//
//  Copyright © 2016 Chris Laverty. All rights reserved.
//

import Foundation
import SwiftyJSON

struct ReorderSettings {
    enum ItemType: String { case radical = "rad", kanji = "kan", vocabulary = "voc" }
    enum QuestionTypeMode: String { case random = "0", readingHeavy = "1", meaningHeavy = "2" }
    enum TypePriorityMode: String { case random = "0", levelHeavy = "1", typeHeavy = "2" }
    
    var sortTypes = true
    var sortLevels = true
    var oneByOne = false
    var questionTypeMode = QuestionTypeMode.random
    var typePriorityMode = TypePriorityMode.random
    
    var itemPriority = [ItemType.radical, .kanji, .vocabulary]
    var levelPriority: [Int] = []
}

extension ReorderSettings {
    private struct Keys {
        static let sortTypes = "sorttypes"
        static let sortLevels = "sortlevels"
        static let oneByOne = "onebyone"
        static let priority = "priority"
        static let questionTypeMode = "questionTypeMode"
        static let typePriorityMode = "typePriorityMode"
    }
    
    static func from(json string: String, withLevelJson levelJson: String) -> ReorderSettings? {
        let levels = JSON.parse(levelJson).arrayValue.map { $0.intValue }
        let settings = JSON.parse(string)
        
        guard
            let sortTypes = settings[Keys.sortTypes].bool,
            let sortLevels = settings[Keys.sortLevels].bool,
            let oneByOne = settings[Keys.oneByOne].bool,
            let itemPriorityJSONDict = settings[Keys.priority].dictionary,
            let questionTypeMode = ReorderSettings.QuestionTypeMode(rawValue: settings[Keys.questionTypeMode].stringValue),
            let typePriorityMode = ReorderSettings.TypePriorityMode(rawValue: settings[Keys.typePriorityMode].stringValue),
            !levels.isEmpty
            else {
                return nil;
        }
        
        let itemPriority = itemPriorityJSONDict.sorted { $0.1.intValue < $1.1.intValue }.map { ReorderSettings.ItemType(rawValue: $0.0)! }
        
        return ReorderSettings(sortTypes: sortTypes,
                               sortLevels: sortLevels,
                               oneByOne: oneByOne,
                               questionTypeMode: questionTypeMode,
                               typePriorityMode: typePriorityMode,
                               itemPriority: itemPriority,
                               levelPriority: levels)
    }
    
    func toJSON() -> String? {
        let json = JSON([
            Keys.sortTypes: sortTypes,
            Keys.sortLevels: sortLevels,
            Keys.oneByOne: oneByOne,
            Keys.priority: NSDictionary(
                objects: (1...itemPriority.count).map { NSNumber(value: $0) },
                forKeys: itemPriority.map { $0.rawValue as NSString }
            ),
            Keys.questionTypeMode: questionTypeMode.rawValue,
            Keys.typePriorityMode: typePriorityMode.rawValue
            ])
        
        return json.rawString()
    }
    
    func levelPriorityJSON() -> String? {
        return JSON(levelPriority).rawString()
    }
}
