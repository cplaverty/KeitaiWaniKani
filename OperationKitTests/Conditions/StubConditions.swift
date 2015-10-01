//
//  StubConditions.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
@testable import OperationKit

struct AlwaysSatisfiedCondition: OperationCondition {
    static let isMutuallyExclusive = false
    
    init() {
        // No op.
    }
    
    func dependencyForOperation(operation: Operation) -> NSOperation? {
        return nil
    }
    
    func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        completion(.Satisfied)
    }
}

enum AlwaysFailedConditionError: ErrorType {
    case Error
}

struct AlwaysFailedCondition: OperationCondition {
    static let isMutuallyExclusive = false
    
    init() {
        // No op.
    }
    
    func dependencyForOperation(operation: Operation) -> NSOperation? {
        return nil
    }
    
    func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        completion(.Failed(AlwaysFailedConditionError.Error))
    }
}
