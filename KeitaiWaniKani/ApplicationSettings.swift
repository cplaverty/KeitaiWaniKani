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
    static let lastRefreshTime = "lastRefreshTime"
    static let userScriptIgnoreAnswerEnabled = "userScript-IgnoreAnswer"
    static let userScriptDoubleCheckEnabled = "userScript-DoubleCheck"
    static let userScriptWaniKaniImproveEnabled = "userScript-WaniKaniImprove"
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
    
    static var lastRefreshTime: NSDate? {
        get { return userDefaults.objectForKey(ApplicationSettingKeys.lastRefreshTime) as? NSDate }
        set { userDefaults.setObject(newValue, forKey: ApplicationSettingKeys.lastRefreshTime) }
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
    
    static func resetToDefaults() {
        apiKey = nil
        apiKeyVerified = false
        purgeDatabase = false
        lastRefreshTime = nil
        userScriptIgnoreAnswerEnabled = false
        userScriptDoubleCheckEnabled = false
        userScriptWaniKaniImproveEnabled = false
    }
}

extension ApplicationSettings {
    
    static func nextRefreshTime() -> NSDate {
        // Find the next refresh boundary
        return WaniKaniAPI.nextRefreshTimeFromNow()
    }
    
    static func needsRefresh() -> Bool {
        guard let lastRefreshTime = self.lastRefreshTime else { return true }
        
        return WaniKaniAPI.needsRefresh(lastRefreshTime)
    }
    
}