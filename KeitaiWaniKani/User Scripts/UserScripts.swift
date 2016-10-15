//
//  UserScripts.swift
//  KeitaiWaniKani
//
//  Copyright © 2016 Chris Laverty. All rights reserved.
//

import WaniKaniKit

private enum UserScriptInjectionRule {
    case ExactMatch(URL)
    case StartsWith(URL)
    
    func matches(_ url: URL) -> Bool {
        switch self {
        case let .ExactMatch(x):
            return url == x
        case let .StartsWith(x):
            return url.host == x.host && url.path.hasPrefix(x.path)
        }
    }
}

class UserScript {
    let name: String
    let description: String
    let forumLink: URL?
    private let settingKey: String?
    private let stylesheetNames: [String]?
    private let scriptNames: [String]?
    private let injectionRules: [UserScriptInjectionRule]
    
    var isEnabled: Bool {
        get {
            guard let settingKey = self.settingKey else { return true }
            return ApplicationSettings.userDefaults.bool(forKey: settingKey)
        }
        set {
            guard let settingKey = self.settingKey else { return }
            ApplicationSettings.userDefaults.set(newValue, forKey: settingKey)
        }
    }
    
    fileprivate init(name: String, description: String, forumLink: URL? = nil, settingKey: String? = nil, stylesheetNames: [String]? = nil, scriptNames: [String]? = nil, injectionRules: [UserScriptInjectionRule]) {
        self.name = name
        self.description = description
        self.forumLink = forumLink
        self.settingKey = settingKey
        self.stylesheetNames = stylesheetNames
        self.scriptNames = scriptNames
        self.injectionRules = injectionRules
    }
    
    func canBeInjected(toPageAt url: URL) -> Bool {
        guard isEnabled else { return false }
        
        for rule in injectionRules {
            if rule.matches(url) {
                return true
            }
        }
        return false
    }
    
    func inject(into page: UserScriptSupport) {
        guard isEnabled else { return }
        
        if let stylesheetNames = stylesheetNames {
            for stylesheetName in stylesheetNames {
                page.injectStyleSheet(name: stylesheetName)
            }
        }
        if let scriptNames = scriptNames {
            for scriptName in scriptNames {
                page.injectScript(name: scriptName)
            }
        }
    }
}

struct UserScriptDefinitions {
    
    static let alwaysEnabled: [UserScript] = [
        UserScript(name: "Common",
                   description: "Common functions",
                   stylesheetNames: ["common"],
                   scriptNames: ["common"],
                   injectionRules: [.ExactMatch(WaniKaniURLs.loginPage), .ExactMatch(WaniKaniURLs.lessonSession), .ExactMatch(WaniKaniURLs.reviewSession)]),
        UserScript(name: "Resize",
                   description: "Resizes fonts for legibility",
                   stylesheetNames: ["resize"],
                   injectionRules: [.ExactMatch(WaniKaniURLs.lessonSession), .ExactMatch(WaniKaniURLs.reviewSession)]),
        ]
    
    static let custom: [UserScript] = [
        UserScript(name: "Disable Lesson Swipe",
                   description: "Disables the horizontal swipe gesture on the info text during lessons to prevent it being accidentally triggered while scrolling.",
                   settingKey: ApplicationSettingKeys.disableLessonSwipe,
                   scriptNames: ["noswipe"],
                   injectionRules: [.ExactMatch(WaniKaniURLs.lessonSession)]),
        ]
    
    static let community: [UserScript] = [
        UserScript(name: "Jitai",
                   description: "Display WaniKani reviews in randomised fonts, for more varied reading training.  Original script written by obskyr.",
                   forumLink: URL(string: "https://www.wanikani.com/chat/api-and-third-party-apps/12858")!,
                   settingKey: ApplicationSettingKeys.userScriptJitaiEnabled,
                   scriptNames: ["jitai.user"],
                   injectionRules: [.ExactMatch(WaniKaniURLs.reviewSession)]),
        
        UserScript(name: "WaniKani Override",
                   description: "Adds an \"Ignore Answer\" button to the bottom of WaniKani review pages, permitting incorrect answers to be ignored.  This script is intended to be used to correct genuine mistakes, like typographical errors.  Original script written by ruipgpinheiro.",
                   forumLink: URL(string: "https://www.wanikani.com/chat/api-and-third-party-apps/2940")!,
                   settingKey: ApplicationSettingKeys.userScriptIgnoreAnswerEnabled,
                   scriptNames: ["wkoverride.user"],
                   injectionRules: [.ExactMatch(WaniKaniURLs.reviewSession)]),
        
        UserScript(name: "WaniKani Double Check",
                   description: "Adds a thumbs up/down button that permits incorrect answers to be marked correct, and correct answers to be marked incorrect.  This script is intended to be used to correct genuine mistakes, like typographical errors.  Original script written by Ethan.",
                   forumLink: URL(string: "https://www.wanikani.com/chat/api-and-third-party-apps/8598")!,
                   settingKey: ApplicationSettingKeys.userScriptDoubleCheckEnabled,
                   scriptNames: ["wkdoublecheck"],
                   injectionRules: [.ExactMatch(WaniKaniURLs.reviewSession)]),
        
        UserScript(name: "WaniKani Improve",
                   description: "Automatically moves to the next item if the answer was correct (also known as \"lightning mode\").  Original script written by Seiji.",
                   forumLink: URL(string: "https://www.wanikani.com/chat/api-and-third-party-apps/2952")!,
                   settingKey: ApplicationSettingKeys.userScriptWaniKaniImproveEnabled,
                   stylesheetNames: ["jquery.qtip.min"],
                   scriptNames: ["jquery.qtip.min", "wkimprove"],
                   injectionRules: [.ExactMatch(WaniKaniURLs.reviewSession)]),
        
        UserScript(name: "Markdown Notes",
                   description: "Allows you to write Markdown in the notes, which will be rendered as HTML when the page loads.  Original script written by rfindley.",
                   forumLink: URL(string: "https://www.wanikani.com/chat/api-and-third-party-apps/11698")!,
                   settingKey: ApplicationSettingKeys.userScriptMarkdownNotesEnabled,
                   scriptNames: ["showdown.min", "markdown.user"],
                   injectionRules: [.ExactMatch(WaniKaniURLs.reviewSession),
                                    .StartsWith(WaniKaniURLs.levelRoot), .StartsWith(WaniKaniURLs.radicalRoot),
                                    .StartsWith(WaniKaniURLs.kanjiRoot), .StartsWith(WaniKaniURLs.vocabularyRoot)]),
        
        UserScript(name: "WaniKani Hide Mnemonics",
                   description: "Allows you to hide the reading and meaning mnemonics on the site.  Original script written by nibarius.",
                   forumLink: URL(string: "https://www.wanikani.com/chat/api-and-third-party-apps/4021")!,
                   settingKey: ApplicationSettingKeys.userScriptHideMnemonicsEnabled,
                   scriptNames: ["wkhidem.user"],
                   injectionRules: [.ExactMatch(WaniKaniURLs.lessonSession), .ExactMatch(WaniKaniURLs.reviewSession),
                                    .StartsWith(WaniKaniURLs.levelRoot), .StartsWith(WaniKaniURLs.radicalRoot),
                                    .StartsWith(WaniKaniURLs.kanjiRoot), .StartsWith(WaniKaniURLs.vocabularyRoot)]),
        
//        UserScript(name: "WaniKani Reorder Ultimate",
//                   description: "Allows you to reorder your lessons and reviews by type and level, and also force reading/meaning first.  Original script written by xMunch.",
//                   forumLink: URL(string: "https://www.wanikani.com/chat/api-and-third-party-apps/8471"),
//                   settingKey: ApplicationSettingKeys.userScriptReorderUltimateEnabled,
//                   scriptNames: ["WKU.user"],
//                   injectionRules: [.ExactMatch(WaniKaniURLs.lessonSession), .ExactMatch(WaniKaniURLs.reviewSession)]),
        ]
    
    static let all = alwaysEnabled + custom + community
    
}
