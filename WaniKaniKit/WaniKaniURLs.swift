//
//  WaniKaniURLs.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public struct WaniKaniURLs {
    public static let home = NSURL(string: "https://www.wanikani.com/")!
    public static let apiBaseURL = NSURL(string: "api/v1.4/user/", relativeToURL: home)!.absoluteURL
    public static let loginPage = NSURL(string: "login", relativeToURL: home)!.absoluteURL
    public static let dashboard = NSURL(string: "dashboard", relativeToURL: home)!.absoluteURL
    public static let communityCentre = NSURL(string: "community", relativeToURL: home)!.absoluteURL
    public static let account = NSURL(string: "account", relativeToURL: home)!.absoluteURL
    public static let subscription = NSURL(string: "account/subscription", relativeToURL: home)!.absoluteURL
    
    public static let reviewHome = NSURL(string: "review", relativeToURL: home)!.absoluteURL
    public static let reviewSession = NSURL(string: "review/session", relativeToURL: home)!.absoluteURL
    
    public static let lessonHome = NSURL(string: "lesson", relativeToURL: home)!.absoluteURL
    public static let lessonSession = NSURL(string: "lesson/session", relativeToURL: home)!.absoluteURL

    public static let radicalRoot = NSURL(string: "radicals/", relativeToURL: home)!.absoluteURL
    public static let kanjiRoot = NSURL(string: "kanji/", relativeToURL: home)!.absoluteURL
}
