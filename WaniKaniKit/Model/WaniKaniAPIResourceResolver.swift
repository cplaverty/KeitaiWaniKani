//
//  WaniKaniAPIResourceResolver.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

final class WaniKaniAPIResourceResolver: ResourceResolver {
    let apiKey: String
    private let baseURL = WaniKaniURLs.apiBaseURL
    
    init(forAPIKey apiKey: String) {
        assert(!apiKey.isEmpty, "Must specify a non-empty API key")
        self.apiKey = apiKey
    }
    
    func URLForResource(resource: Resource, withArgument argument: String?) -> NSURL {
        let resourceKey = apiResourceName(resource)
        let path = argument == nil || argument?.isEmpty == true ? "\(apiKey)/\(resourceKey)" : "\(apiKey)/\(resourceKey)/\(argument!)"
        
        guard let url = NSURL(string: path, relativeToURL: baseURL) else {
            fatalError("Created an invalid URL: base: \(baseURL), path: \(path)")
        }
        
        return url
    }
    
    private func apiResourceName(resource: Resource) -> String {
        switch resource {
        case .StudyQueue: return "study-queue"
        case .UserInformation: return "user-information"
        case .LevelProgression: return "level-progression"
        case .SRSDistribution: return "srs-distribution"
        case .Radicals: return "radicals"
        case .Kanji: return "kanji"
        case .Vocabulary: return "vocabulary"
        }
    }
}
