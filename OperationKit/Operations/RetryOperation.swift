//
//  RetryOperation.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import CocoaLumberjack

public class RetryOperation<T: Operation>: GroupOperation, NSProgressReporting {
    public let progress: NSProgress
    
    private let maximumRetryCount: Int
    private let createOperation: () -> T
    private let shouldRetry: (T, [ErrorType]) -> Bool
    private var numberOfRetries = 0
    
    public init(maximumRetryCount: Int, @autoclosure(escaping) createOperation: () -> T, shouldRetry: (T, [ErrorType]) -> Bool) {
        self.progress = NSProgress(totalUnitCount: 1)
        
        self.maximumRetryCount = maximumRetryCount
        self.createOperation = createOperation
        self.shouldRetry = shouldRetry
        
        let initialOperation = createOperation()
        super.init(operations: [initialOperation])
        name = "RetryOperation<\(T.self.dynamicType)>"
    }
    
    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        guard let op = operation as? T else { return }
        
        if !self.cancelled && !errors.isEmpty && numberOfRetries < maximumRetryCount && shouldRetry(op, errors) {
            ++numberOfRetries
            progress.totalUnitCount = Int64(numberOfRetries + 1)
            progress.completedUnitCount = Int64(numberOfRetries)
            DDLogDebug("Retrying failed operation \(operation) (\(self.numberOfRetries) of \(self.maximumRetryCount))")
            addOperation(createOperation())
        }
    }
    
    public override func finished(errors: [ErrorType]) {
        super.finished(errors)
        
        // Ensure progress is 100%
        progress.completedUnitCount = progress.totalUnitCount
    }
}
