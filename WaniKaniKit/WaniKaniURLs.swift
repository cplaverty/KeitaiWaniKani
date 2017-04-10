//
//  WaniKaniURLs.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public struct WaniKaniURLs {
    public static let home = URL(string: "https://www.wanikani.com/")!
    public static let apiBaseURL = URL(string: "api/v1.4/user/", relativeTo: home)!.absoluteURL
    public static let loginPage = URL(string: "login", relativeTo: home)!.absoluteURL
    public static let dashboard = URL(string: "dashboard", relativeTo: home)!.absoluteURL
    public static let communityCentre = URL(string: "https://community.wanikani.com/")!
    public static let account = URL(string: "settings/account", relativeTo: home)!.absoluteURL
    public static let subscription = URL(string: "account/subscription", relativeTo: home)!.absoluteURL
    
    public static let reviewHome = URL(string: "review", relativeTo: home)!.absoluteURL
    public static let reviewSession = URL(string: "review/session", relativeTo: home)!.absoluteURL
    
    public static let lessonHome = URL(string: "lesson", relativeTo: home)!.absoluteURL
    public static let lessonSession = URL(string: "lesson/session", relativeTo: home)!.absoluteURL
    
    public static let levelRoot = URL(string: "level/", relativeTo: home)!.absoluteURL
    public static let radicalRoot = URL(string: "radicals/", relativeTo: home)!.absoluteURL
    public static let kanjiRoot = URL(string: "kanji/", relativeTo: home)!.absoluteURL
    public static let vocabularyRoot = URL(string: "vocabulary/", relativeTo: home)!.absoluteURL
}
