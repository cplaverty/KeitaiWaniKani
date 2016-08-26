/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file contains the fundamental logic relating to Operation conditions.
*/

/**
    A protocol for defining conditions that must be satisfied in order for an
    operation to begin execution.
*/
public protocol OperationCondition {
    /**
        Specifies whether multiple instances of the conditionalized operation may
        be executing simultaneously.
    */
    static var isMutuallyExclusive: Bool { get }
    
    /**
        Some conditions may have the ability to satisfy the condition if another
        operation is executed first. Use this method to return an operation that
        (for example) asks for permission to perform the operation
        
        - parameter operation: The `Operation` to which the Condition has been added.
        - returns: An `NSOperation`, if a dependency should be automatically added. Otherwise, `nil`.
        - note: Only a single operation may be returned as a dependency. If you
            find that you need to return multiple operations, then you should be
            expressing that as multiple conditions. Alternatively, you could return
            a single `GroupOperation` that executes multiple operations internally.
    */
    func dependency(for: Operation) -> Foundation.Operation?
    
    /// Evaluate the condition, to see if it has been satisfied or not.
    func evaluate(for: Operation, completion: @escaping (OperationConditionResult) -> Void)
}

/**
    An enum to indicate whether an `OperationCondition` was satisfied, or if it
    failed with an error.
*/
public enum OperationConditionResult {
    case satisfied
    case failed(Error)
    
    var error: Error? {
        if case .failed(let error) = self {
            return error
        }
        
        return nil
    }
}

// MARK: Evaluate Conditions

public enum OperationConditionEvaluatorError: Error {
    case conditionFailed
}

struct OperationConditionEvaluator {
    static func evaluate(_ conditions: [OperationCondition], for operation: Operation, completion: @escaping ([Error]) -> Void) {
        // Check conditions.
        let conditionGroup = DispatchGroup()

        var results = [OperationConditionResult?](repeating: nil, count: conditions.count)
        
        // Ask each condition to evaluate and store its result in the "results" array.
        for (index, condition) in conditions.enumerated() {
            conditionGroup.enter()
            condition.evaluate(for: operation) { result in
                results[index] = result
                conditionGroup.leave()
            }
        }
        
        // After all the conditions have evaluated, this block will execute.
        conditionGroup.notify(queue: DispatchQueue.global(qos: .default)) {
            // Aggregate the errors that occurred, in order.
            var failures = results.flatMap { $0?.error }
            
            /*
                If any of the conditions caused this operation to be cancelled,
                check for that.
            */
            if operation.isCancelled {
                failures.append(OperationConditionEvaluatorError.conditionFailed)
            }
            
            completion(failures)
        }
    }
}
