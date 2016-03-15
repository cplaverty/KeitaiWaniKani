//
//  ApplicationSettings.swift
//  KeitaiWaniKani
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
}

struct ApplicationSettings {
    
    static func globalTintColor() -> UIColor {
        return UIColor(red: 29 / 255, green: 148 / 255, blue: 149 / 255, alpha: 1)
    }
    
    static func globalBarTintColor() -> UIColor {
        return UIColor(hue: 180 / 360, saturation: 0.05, brightness: 0.9, alpha: 1)
    }
    
    static var userDefaults: NSUserDefaults {
        return NSUserDefaults.standardUserDefaults()
    }
    
    static var apiKey: String? {
        get { return userDefaults.stringForKey(ApplicationSettingKeys.apiKey) }
        set { userDefaults.setObject(newValue, forKey: ApplicationSettingKeys.apiKey) }
    }
    
    static var apiKeyVerified: Bool {
        get { return userDefaults.boolForKey(ApplicationSettingKeys.apiKeyVerified) }
        set { userDefaults.setBool(newValue, forKey: ApplicationSettingKeys.apiKeyVerified) }
    }
    
    static var purgeDatabase: Bool {
        get { return userDefaults.boolForKey(ApplicationSettingKeys.purgeDatabase) }
        set { userDefaults.setBool(newValue, forKey: ApplicationSettingKeys.purgeDatabase) }
    }
    
    static var disableLessonSwipe: Bool {
        get { return userDefaults.boolForKey(ApplicationSettingKeys.disableLessonSwipe) }
        set { userDefaults.setBool(newValue, forKey: ApplicationSettingKeys.disableLessonSwipe) }
    }
    
    static var lastRefreshTime: NSDate? {
        get { return userDefaults.objectForKey(ApplicationSettingKeys.lastRefreshTime) as? NSDate }
        set { userDefaults.setObject(newValue, forKey: ApplicationSettingKeys.lastRefreshTime) }
    }
    
    static var forceRefresh: Bool {
        get { return userDefaults.boolForKey(ApplicationSettingKeys.forceRefresh) }
        set { userDefaults.setBool(newValue, forKey: ApplicationSettingKeys.forceRefresh) }
    }
    
    static var userScriptJitaiEnabled: Bool {
        get { return userDefaults.boolForKey(ApplicationSettingKeys.userScriptJitaiEnabled) }
        set { userDefaults.setBool(newValue, forKey: ApplicationSettingKeys.userScriptJitaiEnabled) }
    }
    
    static var userScriptIgnoreAnswerEnabled: Bool {
        get { return userDefaults.boolForKey(ApplicationSettingKeys.userScriptIgnoreAnswerEnabled) }
        set { userDefaults.setBool(newValue, forKey: ApplicationSettingKeys.userScriptIgnoreAnswerEnabled) }
    }
    
    static var userScriptDoubleCheckEnabled: Bool {
        get { return userDefaults.boolForKey(ApplicationSettingKeys.userScriptDoubleCheckEnabled) }
        set { userDefaults.setBool(newValue, forKey: ApplicationSettingKeys.userScriptDoubleCheckEnabled) }
    }
    
    static var userScriptWaniKaniImproveEnabled: Bool {
        get { return userDefaults.boolForKey(ApplicationSettingKeys.userScriptWaniKaniImproveEnabled) }
        set { userDefaults.setBool(newValue, forKey: ApplicationSettingKeys.userScriptWaniKaniImproveEnabled) }
    }
    
    static var userScriptMarkdownNotesEnabled: Bool {
        get { return userDefaults.boolForKey(ApplicationSettingKeys.userScriptMarkdownNotesEnabled) }
        set { userDefaults.setBool(newValue, forKey: ApplicationSettingKeys.userScriptMarkdownNotesEnabled) }
    }
    
    static var userScriptHideMnemonicsEnabled: Bool {
        get { return userDefaults.boolForKey(ApplicationSettingKeys.userScriptHideMnemonicsEnabled) }
        set { userDefaults.setBool(newValue, forKey: ApplicationSettingKeys.userScriptHideMnemonicsEnabled) }
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
    }
}

extension ApplicationSettings {
    
    static func nextRefreshTime() -> NSDate {
        // Find the next refresh boundary
        return WaniKaniAPI.nextRefreshTimeFromNow()
    }
    
    static func needsRefresh() -> Bool {
        if forceRefresh { return true }
        guard let lastRefreshTime = self.lastRefreshTime else { return true }
        
        return WaniKaniAPI.needsRefresh(lastRefreshTime)
    }
    
}