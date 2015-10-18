//
//  TestFileResourceResolver.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import OHHTTPStubs
@testable import WaniKaniKit

final class TestFileResourceResolver: ResourceResolver {
    let bundle = NSBundle(forClass: TestFileResourceResolver.self)
    let fileName: String
    let apiKey: String
    
    convenience init(fileName: String) {
        self.init(fileName: fileName, forApiKey: "TEST")
    }
    
    init(fileName: String, forApiKey apiKey: String) {
        self.fileName = fileName
        self.apiKey = apiKey
    }
    
    func URLForResource(resource: Resource, withArgument argument: String?) -> NSURL {
        guard let url = bundle.URLForResource(fileName, withExtension: "json", subdirectory: "WaniKani API Responses") else {
            fatalError("Could not load file \(fileName).json from bundle")
        }
        
        return url
    }
}

private class BundleMark {}

protocol ResourceHTTPStubs {
    var resourceResolver: ResourceResolver { get }
    func stubForResource(resouce: Resource, file: String)
}

extension ResourceHTTPStubs {
    var resourceResolver: ResourceResolver {
        return WaniKaniAPIResourceResolver(forAPIKey: "TEST_API_KEY")
    }
    
    func stubForResource(resouce: Resource, file: String) {
        let expectedURL = resourceResolver.URLForResource(resouce, withArgument: nil)
        OHHTTPStubs.stubRequestsPassingTest({ (request: NSURLRequest) in
            request.URL?.host == expectedURL.host && request.URL?.path.map { $0.hasPrefix(expectedURL.path!) } == true
            }) { _ in
                let stubPath = OHPathForFile("WaniKani API Responses/\(file).json", BundleMark.self)
                return fixture(stubPath!, headers: ["Content-Type": "application/json"])
        }
    }
}