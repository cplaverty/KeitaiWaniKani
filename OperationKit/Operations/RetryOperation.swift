//
//  RetryOperation.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import CocoaLumberjack

public class RetryOperation<T: Operation>: GroupOperation, ProgressReporting {
    public let progress: Progress
    
    private let maximumRetryCount: Int
    private let createOperation: () -> T
    private let shouldRetry: (T, [Error]) -> Bool
    private var numberOfRetries = 0
    
    public init(maximumRetryCount: Int, createOperation: @autoclosure @escaping () -> T, shouldRetry: @escaping (T, [Error]) -> Bool) {
        self.progress = Progress(totalUnitCount: 1)
        
        self.maximumRetryCount = maximumRetryCount
        self.createOperation = createOperation
        self.shouldRetry = shouldRetry
        
        let initialOperation = createOperation()
        super.init(operations: [initialOperation])
        name = "RetryOperation<\(type(of: T.self))>"
    }
    
    public override func operationDidFinish(_ operation: Foundation.Operation, withErrors errors: [Error]) {
        guard let op = operation as? T else { return }
        
        if !self.isCancelled && !errors.isEmpty && numberOfRetries < maximumRetryCount && shouldRetry(op, errors) {
            numberOfRetries += 1
            progress.totalUnitCount = Int64(numberOfRetries + 1)
            progress.completedUnitCount = Int64(numberOfRetries)
            DDLogDebug("Retrying failed operation \(operation) (\(self.numberOfRetries) of \(self.maximumRetryCount))")
            add(createOperation())
        }
    }
    
    public override func finished(_ errors: [Error]) {
        super.finished(errors)
        
        // Ensure progress is 100%
        progress.completedUnitCount = progress.totalUnitCount
    }
}
