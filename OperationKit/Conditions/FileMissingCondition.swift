//
//  FileMissingCondition.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public enum FileMissingConditionError: Error {
    case fileExists(URL)
}

public struct FileMissingCondition: OperationCondition {
    public static let isMutuallyExclusive = false
    
    public let url: URL
    
    public init(url: URL) {
        assert(url.isFileURL, "Destination URL must be a file path")
        self.url = url
    }
    
    public func dependency(for operation: Operation) -> Foundation.Operation? {
        return nil
    }
    
    /// Evaluate the condition, to see if it has been satisfied or not.
    public func evaluate(for operation: Operation, completion: @escaping (OperationConditionResult) -> Void) {
        if FileManager.default.fileExists(atPath: url.path) {
            completion(.failed(FileMissingConditionError.fileExists(url)))
        } else {
            completion(.satisfied)
        }
    }

}
