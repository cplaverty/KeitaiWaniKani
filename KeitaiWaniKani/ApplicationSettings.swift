//
//  ApplicationSettings.swift
//  AlliCrab
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import WaniKaniKit

struct ApplicationSettingKeys {
    static let apiKey = "apiKey"
    static let apiKeyVerified = "apiKeyVerified"
    static let purgeDatabase = "purgeDatabase"
    static let disableLessonSwipe = "disableLessonSwipe"
    static let lastRefreshTime = "lastRefreshTime"
    static let forceRefresh = "forceRefresh"
    static let userScriptJitaiEnabled = "userScript-Jitai"
    static let userScriptIgnoreAnswerEnabled = "userScript-IgnoreAnswer"
    static let userScriptDoubleCheckEnabled = "userScript-DoubleCheck"
    static let userScriptWaniKaniImproveEnabled = "userScript-WaniKaniImprove"
    static let userScriptMarkdownNotesEnabled = "userScript-MarkdownNotes"
    static let userScriptHideMnemonicsEnabled = "userScript-HideMnemonics"
    static let userScriptReorderUltimateEnabled = "userScript-ReorderUltimate"
}

struct ApplicationSettings {
    
    static var globalTintColor: UIColor {
        return UIColor(red: 29 / 255, green: 148 / 255, blue: 149 / 255, alpha: 1)
    }
    
    static var globalBarTintColor: UIColor {
        return UIColor(hue: 180 / 360, saturation: 0.05, brightness: 0.9, alpha: 1)
    }
    
    static var userDefaults: UserDefaults {
        return UserDefaults.standard
    }
    
    static var apiKey: String? {
        get { return userDefaults.string(forKey: ApplicationSettingKeys.apiKey) }
        set { userDefaults.set(newValue, forKey: ApplicationSettingKeys.apiKey) }
    }
    
    static var apiKeyVerified: Bool {
        get { return userDefaults.bool(forKey: ApplicationSettingKeys.apiKeyVerified) }
        set { userDefaults.set(newValue, forKey: ApplicationSettingKeys.apiKeyVerified) }
    }
    
    static var purgeDatabase: Bool {
        get { return userDefaults.bool(forKey: ApplicationSettingKeys.purgeDatabase) }
        set { userDefaults.set(newValue, forKey: ApplicationSettingKeys.purgeDatabase) }
    }
    
    static var disableLessonSwipe: Bool {
        get { return userDefaults.bool(forKey: ApplicationSettingKeys.disableLessonSwipe) }
        set { userDefaults.set(newValue, forKey: ApplicationSettingKeys.disableLessonSwipe) }
    }
    
    static var lastRefreshTime: Date? {
        get { return userDefaults.object(forKey: ApplicationSettingKeys.lastRefreshTime) as? Date }
        set { userDefaults.set(newValue, forKey: ApplicationSettingKeys.lastRefreshTime) }
    }
    
    static var forceRefresh: Bool {
        get { return userDefaults.bool(forKey: ApplicationSettingKeys.forceRefresh) }
        set { userDefaults.set(newValue, forKey: ApplicationSettingKeys.forceRefresh) }
    }
    
    static var userScriptJitaiEnabled: Bool {
        get { return userDefaults.bool(forKey: ApplicationSettingKeys.userScriptJitaiEnabled) }
        set { userDefaults.set(newValue, forKey: ApplicationSettingKeys.userScriptJitaiEnabled) }
    }
    
    static var userScriptIgnoreAnswerEnabled: Bool {
        get { return userDefaults.bool(forKey: ApplicationSettingKeys.userScriptIgnoreAnswerEnabled) }
        set { userDefaults.set(newValue, forKey: ApplicationSettingKeys.userScriptIgnoreAnswerEnabled) }
    }
    
    static var userScriptDoubleCheckEnabled: Bool {
        get { return userDefaults.bool(forKey: ApplicationSettingKeys.userScriptDoubleCheckEnabled) }
        set { userDefaults.set(newValue, forKey: ApplicationSettingKeys.userScriptDoubleCheckEnabled) }
    }
    
    static var userScriptWaniKaniImproveEnabled: Bool {
        get { return userDefaults.bool(forKey: ApplicationSettingKeys.userScriptWaniKaniImproveEnabled) }
        set { userDefaults.set(newValue, forKey: ApplicationSettingKeys.userScriptWaniKaniImproveEnabled) }
    }
    
    static var userScriptMarkdownNotesEnabled: Bool {
        get { return userDefaults.bool(forKey: ApplicationSettingKeys.userScriptMarkdownNotesEnabled) }
        set { userDefaults.set(newValue, forKey: ApplicationSettingKeys.userScriptMarkdownNotesEnabled) }
    }
    
    static var userScriptHideMnemonicsEnabled: Bool {
        get { return userDefaults.bool(forKey: ApplicationSettingKeys.userScriptHideMnemonicsEnabled) }
        set { userDefaults.set(newValue, forKey: ApplicationSettingKeys.userScriptHideMnemonicsEnabled) }
    }
    
    static var userScriptReorderUltimateEnabled: Bool {
        get { return userDefaults.bool(forKey: ApplicationSettingKeys.userScriptReorderUltimateEnabled) }
        set { userDefaults.set(newValue, forKey: ApplicationSettingKeys.userScriptReorderUltimateEnabled) }
    }
    
    static func resetToDefaults() {
        apiKey = nil
        apiKeyVerified = false
        purgeDatabase = false
        disableLessonSwipe = false
        lastRefreshTime = nil
        forceRefresh = false
        userScriptJitaiEnabled = false
        userScriptIgnoreAnswerEnabled = false
        userScriptDoubleCheckEnabled = false
        userScriptWaniKaniImproveEnabled = false
        userScriptMarkdownNotesEnabled = false
        userScriptHideMnemonicsEnabled = false
        userScriptReorderUltimateEnabled = false
    }
}

extension ApplicationSettings {
    
    static func nextRefreshTime() -> Date {
        // Find the next refresh boundary
        return WaniKaniAPI.nextRefreshTimeFromNow()
    }
    
    static func needsRefresh() -> Bool {
        if forceRefresh { return true }
        guard let lastRefreshTime = self.lastRefreshTime else { return true }
        
        return WaniKaniAPI.needsRefresh(since: lastRefreshTime)
    }
    
}
