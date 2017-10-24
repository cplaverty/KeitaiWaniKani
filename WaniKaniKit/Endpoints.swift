//
//  Endpoints.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public class Endpoints {
    public static let `default` = Endpoints(baseURL: URL(string: "https://www.wanikani.com/api/v2")!)
    
    public private(set) lazy var assignments: URL = baseURL.appendingPathComponent("assignments")
    public private(set) lazy var levelProgressions: URL = baseURL.appendingPathComponent("level_progressions")
    public private(set) lazy var reviewStatistics: URL = baseURL.appendingPathComponent("review_statistics")
    public private(set) lazy var studyMaterials: URL = baseURL.appendingPathComponent("study_materials")
    public private(set) lazy var subjects: URL = baseURL.appendingPathComponent("subjects")
    public private(set) lazy var user: URL = baseURL.appendingPathComponent("user")
    
    private let baseURL: URL
    
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
}
