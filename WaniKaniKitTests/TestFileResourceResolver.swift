//
//  TestFileResourceResolver.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import OHHTTPStubs
import OperationKit
@testable import WaniKaniKit

private class BundleMark {}

protocol ResourceHTTPStubs {
    var resourceResolver: ResourceResolver { get }
    func stubRequest(for resouce: Resource, file: String)
}

private var testResourceResolver = WaniKaniAPIResourceResolver(apiKey: "TEST_API_KEY")

extension ResourceHTTPStubs {
    var resourceResolver: ResourceResolver { return testResourceResolver }
    
    func stubRequest(for resouce: Resource, file: String) {
        ReachabilityCondition.isEnabled = false
        let expectedURL = resourceResolver.resolveURL(resource: resouce, withArgument: nil)
        _ = stub(condition: isHost(expectedURL.host!) && pathStartsWith(expectedURL.path)) { _ in
            let stubPath = OHPathForFile("WaniKani API Responses/\(file).json", BundleMark.self)
            if let stubPath = stubPath {
                return fixture(filePath: stubPath, headers: ["Content-Type" as NSString: "application/json" as NSString])
            } else {
                return fixture(filePath: "", status: 404, headers: [:])
            }
        }
    }
}
