//
//  WaniKaniURL.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct WaniKaniURL {
    public static let home = URL(string: "https://www.wanikani.com/")!
    public static let communityCentre = URL(string: "https://community.wanikani.com/")!
    
    public static let loginPage = home.appendingPathComponent("login")
    public static let dashboard = home.appendingPathComponent("dashboard")
    
    public static let accountSettings = home.appendingPathComponent("settings").appendingPathComponent("account")
    
    public static let reviewHome = home.appendingPathComponent("review")
    public static let reviewSession = reviewHome.appendingPathComponent("session")
    
    public static let lessonHome = home.appendingPathComponent("lesson")
    public static let lessonSession = lessonHome.appendingPathComponent("session")
    
    public static let levelRoot = home.appendingPathComponent("level")
    public static let radicalRoot = home.appendingPathComponent("radicals")
    public static let kanjiRoot = home.appendingPathComponent("kanji")
    public static let vocabularyRoot = home.appendingPathComponent("vocabulary")
}
