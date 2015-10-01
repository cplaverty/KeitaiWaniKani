//
//  WaniKaniURLs.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public struct WaniKaniURLs {
    public static let home = NSURL(string: "https://www.wanikani.com/")!
    public static let apiBaseURL = NSURL(string: "api/v1.4/user/", relativeToURL: home)!
    public static let loginPage = NSURL(string: "login", relativeToURL: home)!
    public static let dashboard = NSURL(string: "dashboard", relativeToURL: home)!
    public static let communityCentre = NSURL(string: "community", relativeToURL: home)!
    public static let account = NSURL(string: "account", relativeToURL: home)!
    public static let reviewSession = NSURL(string: "review/session", relativeToURL: home)!
    public static let lessonSession = NSURL(string: "lesson/session", relativeToURL: home)!
}
