//
//  FileMissingCondition.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public enum FileMissingConditionError: ErrorType {
    case FileExists(NSURL)
}

public struct FileMissingCondition: OperationCondition {
    public static let isMutuallyExclusive = false
    
    public let fileURL: NSURL
    
    public init(fileURL: NSURL) {
        assert(fileURL.fileURL, "Destination URL must be a file path")
        self.fileURL = fileURL
    }
    
    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return nil
    }
    
    /// Evaluate the condition, to see if it has been satisfied or not.
    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        if NSFileManager.defaultManager().fileExistsAtPath(fileURL.path!) {
            completion(.Failed(FileMissingConditionError.FileExists(fileURL)))
        } else {
            completion(.Satisfied)
        }
    }

}
