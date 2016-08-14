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
    
    init(apiKey: String) {
        assert(!apiKey.isEmpty, "Must specify a non-empty API key")
        self.apiKey = apiKey
    }
    
    func resolveURL(resource: Resource, withArgument argument: String?) -> URL {
        let resourceKey = apiName(forResource: resource)
        let path = argument == nil || argument?.isEmpty == true ? "\(apiKey)/\(resourceKey)" : "\(apiKey)/\(resourceKey)/\(argument!)"
        
        guard let url = URL(string: path, relativeTo: baseURL) else {
            fatalError("Created an invalid URL: base: \(baseURL), path: \(path)")
        }
        
        return url
    }
    
    private func apiName(forResource resource: Resource) -> String {
        switch resource {
        case .studyQueue: return "study-queue"
        case .userInformation: return "user-information"
        case .levelProgression: return "level-progression"
        case .srsDistribution: return "srs-distribution"
        case .radicals: return "radicals"
        case .kanji: return "kanji"
        case .vocabulary: return "vocabulary"
        }
    }
}
