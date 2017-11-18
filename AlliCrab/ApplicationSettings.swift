//
//  ApplicationSettings.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import WaniKaniKit

enum ApplicationSettingKey: String {
    case apiKey = "apiKeyV2"
    case purgeDatabase = "purgeDatabase"
    case purgeCaches = "purgeCaches"
    case disableLessonSwipe = "disableLessonSwipe"
    case userScriptCloseButNoCigarEnabled = "userScript-CloseButNoCigar"
    case userScriptJitaiEnabled = "userScript-Jitai"
    case userScriptIgnoreAnswerEnabled = "userScript-IgnoreAnswer"
    case userScriptDoubleCheckEnabled = "userScript-DoubleCheck"
    case userScriptWaniKaniImproveEnabled = "userScript-WaniKaniImprove"
    case userScriptMarkdownNotesEnabled = "userScript-MarkdownNotes"
    case userScriptHideMnemonicsEnabled = "userScript-HideMnemonics"
    case userScriptReorderUltimateEnabled = "userScript-ReorderUltimate"
}

extension UIColor {
    class var globalTintColor: UIColor {
        return UIColor(red: 29 / 255, green: 148 / 255, blue: 149 / 255, alpha: 1)
    }
    
    class var globalBarTintColor: UIColor {
        return UIColor(hue: 180 / 360, saturation: 0.05, brightness: 0.9, alpha: 1)
    }
}

struct ApplicationSettings {
    static var userDefaults: UserDefaults {
        return UserDefaults.standard
    }
    
    static var apiKey: String? {
        get { return userDefaults.string(forKey: .apiKey) }
        set { userDefaults.set(newValue, forKey: .apiKey) }
    }
    
    static var purgeDatabase: Bool {
        get { return userDefaults.bool(forKey: .purgeDatabase) }
        set { userDefaults.set(newValue, forKey: .purgeDatabase) }
    }
    
    static var purgeCaches: Bool {
        get { return userDefaults.bool(forKey: .purgeCaches) }
        set { userDefaults.set(newValue, forKey: .purgeCaches) }
    }
    
    static var disableLessonSwipe: Bool {
        get { return userDefaults.bool(forKey: .disableLessonSwipe) }
        set { userDefaults.set(newValue, forKey: .disableLessonSwipe) }
    }
    
    static var userScriptCloseButNoCigarEnabled: Bool {
        get { return userDefaults.bool(forKey: .userScriptCloseButNoCigarEnabled) }
        set { userDefaults.set(newValue, forKey: .userScriptCloseButNoCigarEnabled) }
    }
    
    static var userScriptJitaiEnabled: Bool {
        get { return userDefaults.bool(forKey: .userScriptJitaiEnabled) }
        set { userDefaults.set(newValue, forKey: .userScriptJitaiEnabled) }
    }
    
    static var userScriptIgnoreAnswerEnabled: Bool {
        get { return userDefaults.bool(forKey: .userScriptIgnoreAnswerEnabled) }
        set { userDefaults.set(newValue, forKey: .userScriptIgnoreAnswerEnabled) }
    }
    
    static var userScriptDoubleCheckEnabled: Bool {
        get { return userDefaults.bool(forKey: .userScriptDoubleCheckEnabled) }
        set { userDefaults.set(newValue, forKey: .userScriptDoubleCheckEnabled) }
    }
    
    static var userScriptWaniKaniImproveEnabled: Bool {
        get { return userDefaults.bool(forKey: .userScriptWaniKaniImproveEnabled) }
        set { userDefaults.set(newValue, forKey: .userScriptWaniKaniImproveEnabled) }
    }
    
    static var userScriptMarkdownNotesEnabled: Bool {
        get { return userDefaults.bool(forKey: .userScriptMarkdownNotesEnabled) }
        set { userDefaults.set(newValue, forKey: .userScriptMarkdownNotesEnabled) }
    }
    
    static var userScriptHideMnemonicsEnabled: Bool {
        get { return userDefaults.bool(forKey: .userScriptHideMnemonicsEnabled) }
        set { userDefaults.set(newValue, forKey: .userScriptHideMnemonicsEnabled) }
    }
    
    static var userScriptReorderUltimateEnabled: Bool {
        get { return userDefaults.bool(forKey: .userScriptReorderUltimateEnabled) }
        set { userDefaults.set(newValue, forKey: .userScriptReorderUltimateEnabled) }
    }
    
    static func resetToDefaults() {
        apiKey = nil
        purgeDatabase = false
        purgeCaches = false
        disableLessonSwipe = false
        userScriptCloseButNoCigarEnabled = false
        userScriptJitaiEnabled = false
        userScriptIgnoreAnswerEnabled = false
        userScriptDoubleCheckEnabled = false
        userScriptWaniKaniImproveEnabled = false
        userScriptMarkdownNotesEnabled = false
        userScriptHideMnemonicsEnabled = false
        userScriptReorderUltimateEnabled = false
    }
}

extension UserDefaults {
    func set(_ value: Any?, forKey defaultName: ApplicationSettingKey) {
        set(value, forKey: defaultName.rawValue)
    }
    
    func set(_ value: Int, forKey defaultName: ApplicationSettingKey) {
        set(value, forKey: defaultName.rawValue)
    }
    
    func set(_ value: Float, forKey defaultName: ApplicationSettingKey) {
        set(value, forKey: defaultName.rawValue)
    }
    
    func set(_ value: Double, forKey defaultName: ApplicationSettingKey) {
        set(value, forKey: defaultName.rawValue)
    }
    
    func set(_ value: Bool, forKey defaultName: ApplicationSettingKey) {
        set(value, forKey: defaultName.rawValue)
    }
    
    func set(_ url: URL?, forKey defaultName: ApplicationSettingKey) {
        set(url, forKey: defaultName.rawValue)
    }
    
    func object(forKey defaultName: ApplicationSettingKey) -> Any? {
        return object(forKey: defaultName.rawValue)
    }
    
    func string(forKey defaultName: ApplicationSettingKey) -> String? {
        return string(forKey: defaultName.rawValue)
    }
    
    func bool(forKey defaultName: ApplicationSettingKey) -> Bool {
        return bool(forKey: defaultName.rawValue)
    }
}
