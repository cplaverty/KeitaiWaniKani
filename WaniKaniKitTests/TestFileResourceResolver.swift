//
//  TestFileResourceResolver.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
@testable import WaniKaniKit

enum TestFileLoadingError: ErrorType {
    case IncorrectResourceRequested(requested: Resource, expected: Resource)
    case IncorrectArgumentRequested(requested: String?, expected: String?)
    case FailedToLoadResource(name: String, resourcePath: String?)
}

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
