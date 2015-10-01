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
}

struct ApplicationSettings {
    
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
    
    static func resetToDefaults() {
        apiKey = nil
        apiKeyVerified = false
        purgeDatabase = false
        lastRefreshTime = nil
        userScriptIgnoreAnswerEnabled = false
    }
}

extension ApplicationSettings {
    
    static func nextRefreshTime() -> NSDate {
        // Find the next refresh boundary
        return WaniKaniAPI.nextRefreshTimeFromNow()
    }
    
    static func needsRefresh() -> Bool {
        guard let lastRefreshTime = self.lastRefreshTime else { return true }
        
        let mostRecentAPIDataChangeTime = WaniKaniAPI.lastRefreshTimeFromNow()
        let secondsSinceLastRefreshTime = lastRefreshTime.timeIntervalSinceDate(mostRecentAPIDataChangeTime)
        // Only update if we haven't updated since the last refresh time
        return secondsSinceLastRefreshTime <= 0
    }
    
}