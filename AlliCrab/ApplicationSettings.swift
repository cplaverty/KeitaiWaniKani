//
//  ApplicationSettings.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import WaniKaniKit

enum ApplicationSettingKey: String {
    case apiKey = "apiKeyV2"
    case notificationStrategy = "notificationStrategy"
    case purgeDatabase = "purgeDatabase"
    case purgeCaches = "purgeCaches"
    case disableLessonSwipe = "disableLessonSwipe"
    case userScriptCloseButNoCigarEnabled = "userScript-CloseButNoCigar"
    case userScriptJitaiEnabled = "userScript-Jitai"
    case userScriptIgnoreAnswerEnabled = "userScript-IgnoreAnswer"
    case userScriptDoubleCheckEnabled = "userScript-DoubleCheck"
    case userScriptWaniKaniImproveEnabled = "userScript-WaniKaniImprove"
    case userScriptReorderUltimateEnabled = "userScript-ReorderUltimate"
    case reviewTimelineFilterType = "reviewTimelineFilterType"
    case reviewTimelineValueType = "reviewTimelineValueType"
}

extension UIColor {
    class var globalTintColor: UIColor {
        return UIColor(named: "Colours/GlobalTint")!
    }
    
    class var globalBarTintColor: UIColor {
        return UIColor(named: "Colours/GlobalBarTint")!
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
    
    static var notificationStrategy: NotificationStrategy {
        get { return userDefaults.rawValue(NotificationStrategy.self, forKey: .notificationStrategy) ?? .firstReviewSession }
        set { userDefaults.set(newValue, forKey: .notificationStrategy) }
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
    
    static var userScriptReorderUltimateEnabled: Bool {
        get { return userDefaults.bool(forKey: .userScriptReorderUltimateEnabled) }
        set { userDefaults.set(newValue, forKey: .userScriptReorderUltimateEnabled) }
    }
    
    static var reviewTimelineFilterType: ReviewTimelineFilter? {
        get { return ReviewTimelineFilter(rawValue: userDefaults.integer(forKey: .reviewTimelineFilterType)) }
        set {
            guard let timelineFilterValue = newValue else {
                return
            }
            userDefaults.set(timelineFilterValue.rawValue, forKey: .reviewTimelineFilterType)
        }
    }
    
    static var reviewTimelineValueType: ReviewTimelineCountMethod? {
        get { return ReviewTimelineCountMethod(rawValue: userDefaults.integer(forKey: .reviewTimelineValueType))}
        set {
            guard let timelineCountMethod = newValue else {
                return
            }
            userDefaults.set(timelineCountMethod.rawValue, forKey: .reviewTimelineValueType)
        }
    }
    
    static func resetToDefaults() {
        apiKey = nil
        notificationStrategy = .firstReviewSession
        purgeDatabase = false
        purgeCaches = false
        disableLessonSwipe = false
        userScriptCloseButNoCigarEnabled = false
        userScriptJitaiEnabled = false
        userScriptIgnoreAnswerEnabled = false
        userScriptDoubleCheckEnabled = false
        userScriptWaniKaniImproveEnabled = false
        userScriptReorderUltimateEnabled = false
        reviewTimelineFilterType = ReviewTimelineFilter.none
        reviewTimelineValueType = ReviewTimelineCountMethod.histogram
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
    
    func set<T: RawRepresentable>(_ value: T?, forKey defaultName: ApplicationSettingKey) {
        set(value?.rawValue, forKey: defaultName.rawValue)
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

    func integer(forKey defaultName: ApplicationSettingKey) -> Int {
        return integer(forKey: defaultName.rawValue)
    }
    
    func rawValue<T: RawRepresentable>(_ type: T.Type, forKey defaultName: ApplicationSettingKey) -> T? {
        guard let rawValue = object(forKey: defaultName) as? T.RawValue else {
            return nil
        }
        return type.init(rawValue: rawValue)
    }
}
