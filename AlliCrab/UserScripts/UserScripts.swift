//
//  UserScripts.swift
//  AlliCrab
//
//  Copyright © 2016 Chris Laverty. All rights reserved.
//

import WaniKaniKit

enum UserScriptInjectionRule {
    case ExactMatch(URL)
    case PrefixedWith(URL)
    
    func matches(_ url: URL) -> Bool {
        switch self {
        case let .ExactMatch(x):
            return url == x
        case let .PrefixedWith(x):
            return url.host == x.host && url.path.hasPrefix(x.path)
        }
    }
}

class UserScript {
    let name: String
    let author: String?
    let description: String
    let forumLink: URL?
    let requiresFonts: Bool
    private let settingKey: ApplicationSettingKey?
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
    
    init(name: String, author: String? = nil, description: String, forumLink: URL? = nil, settingKey: ApplicationSettingKey? = nil, requiresFonts: Bool = false, stylesheetNames: [String]? = nil, scriptNames: [String]? = nil, injectionRules: [UserScriptInjectionRule]) {
        self.name = name
        self.author = author
        self.description = description
        self.forumLink = forumLink
        self.settingKey = settingKey
        self.requiresFonts = requiresFonts
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
                   injectionRules: [.ExactMatch(WaniKaniURL.loginPage), .ExactMatch(WaniKaniURL.lessonSession), .ExactMatch(WaniKaniURL.reviewSession)]),
        UserScript(name: "Resize",
                   description: "Resizes fonts for legibility",
                   stylesheetNames: ["resize"],
                   injectionRules: [.ExactMatch(WaniKaniURL.lessonSession), .ExactMatch(WaniKaniURL.reviewSession)]),
        ]
    
    static let custom: [UserScript] = [
        UserScript(name: "Disable Lesson Swipe",
                   description: "Disables the horizontal swipe gesture on the info text during lessons to prevent it being accidentally triggered while scrolling.",
                   settingKey: ApplicationSettingKey.disableLessonSwipe,
                   scriptNames: ["noswipe"],
                   injectionRules: [.ExactMatch(WaniKaniURL.lessonSession)]),
        ]
    
    static let community: [UserScript] = [
        UserScript(name: "Close But No Cigar",
                   author: "Ethan",
                   description: "Prevent \"Your answer was a bit off\" answers from being accepted.  Script by Ethan.",
                   forumLink: WaniKaniURL.forumTopic(withRelativePath: "userscript-prevent-your-answer-was-a-bit-off-answers-from-being-accepted-a-k-a-close-but-no-cigar/7134"),
                   settingKey: ApplicationSettingKey.userScriptCloseButNoCigarEnabled,
                   requiresFonts: true,
                   scriptNames: ["WKButNoCigar.user"],
                   injectionRules: [.ExactMatch(WaniKaniURL.lessonSession), .ExactMatch(WaniKaniURL.reviewSession)]),
        
        UserScript(name: "Jitai",
                   author: "obskyr",
                   description: "Display WaniKani reviews in randomised fonts, for more varied reading training.  Script by obskyr.",
                   forumLink: WaniKaniURL.forumTopic(withRelativePath: "jitai-the-font-randomizer-that-fits/12617"),
                   settingKey: ApplicationSettingKey.userScriptJitaiEnabled,
                   requiresFonts: true,
                   scriptNames: ["jitai.user"],
                   injectionRules: [.ExactMatch(WaniKaniURL.reviewSession)]),
        
        UserScript(name: "Markdown Notes",
                   author: "rfindley",
                   description: "Allows you to write Markdown in the notes, which will be rendered as HTML when the page loads.  Script by rfindley.",
                   forumLink: WaniKaniURL.forumTopic(withRelativePath: "userscript-markdown-notes-updated/11462"),
                   settingKey: ApplicationSettingKey.userScriptMarkdownNotesEnabled,
                   scriptNames: ["showdown.min", "markdown.user"],
                   injectionRules: [.ExactMatch(WaniKaniURL.reviewSession),
                                    .PrefixedWith(WaniKaniURL.levelRoot), .PrefixedWith(WaniKaniURL.radicalRoot),
                                    .PrefixedWith(WaniKaniURL.kanjiRoot), .PrefixedWith(WaniKaniURL.vocabularyRoot)]),
        
        UserScript(name: "WaniKani Hide Mnemonics",
                   author: "nibarius",
                   description: "Allows you to hide the reading and meaning mnemonics on the site.  Script by nibarius.",
                   forumLink: WaniKaniURL.forumTopic(withRelativePath: "userscript-wanikani-hide-mnemonics/3923"),
                   settingKey: ApplicationSettingKey.userScriptHideMnemonicsEnabled,
                   scriptNames: ["wkhidem.user"],
                   injectionRules: [.ExactMatch(WaniKaniURL.lessonSession), .ExactMatch(WaniKaniURL.reviewSession),
                                    .PrefixedWith(WaniKaniURL.levelRoot), .PrefixedWith(WaniKaniURL.radicalRoot),
                                    .PrefixedWith(WaniKaniURL.kanjiRoot), .PrefixedWith(WaniKaniURL.vocabularyRoot)]),
        
        UserScript(name: "WaniKani Improve",
                   author: "Seiji",
                   description: "Automatically moves to the next item if the answer was correct (also known as \"lightning mode\").  Script by Seiji.",
                   forumLink: WaniKaniURL.forumTopic(withRelativePath: "wanikani-improve-2-2-2-faster-and-smarter-reviews/2858"),
                   settingKey: ApplicationSettingKey.userScriptWaniKaniImproveEnabled,
                   stylesheetNames: ["jquery.qtip.min"],
                   scriptNames: ["jquery.qtip.min", "wkimprove"],
                   injectionRules: [.ExactMatch(WaniKaniURL.reviewSession)]),
        
        UserScript(name: "WaniKani Override",
                   author: "ruipgpinheiro, Mempo",
                   description: "Adds an \"Ignore Answer\" button to the bottom of WaniKani review pages, permitting incorrect answers to be ignored.  This script is intended to be used to correct genuine mistakes, like typographical errors.  Script by ruipgpinheiro, updated by Mempo.",
                   forumLink: WaniKaniURL.forumTopic(withRelativePath: "userscript-wanikani-override-ignore-answer-button-active-support/17999"),
                   settingKey: ApplicationSettingKey.userScriptIgnoreAnswerEnabled,
                   scriptNames: ["wkoverride.user"],
                   injectionRules: [.ExactMatch(WaniKaniURL.reviewSession)]),
        ]
    
    static let all = alwaysEnabled + custom + community
}
