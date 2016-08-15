/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

import Foundation

public enum NoCancelledDependenciesError: Error {
    case cancelledDependencies([Foundation.Operation])
}

/**
    A condition that specifies that every dependency must have succeeded.
    If any dependency was cancelled, the target operation will be cancelled as
    well.
*/
public struct NoCancelledDependencies: OperationCondition {
    public static let isMutuallyExclusive = false
    
    public init() {
        // No op.
    }
    
    public func dependency(for operation: Operation) -> Foundation.Operation? {
        return nil
    }
    
    public func evaluate(for operation: Operation, completion: (OperationConditionResult) -> Void) {
        // Verify that all of the dependencies executed.
        let cancelled = operation.dependencies.filter { $0.isCancelled }

        if !cancelled.isEmpty {
            // At least one dependency was cancelled; the condition was not satisfied.
            let error = NoCancelledDependenciesError.cancelledDependencies(cancelled)
            
            completion(.failed(error))
        }
        else {
            completion(.satisfied)
        }
    }
}
