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
    
    func dependency(forOperation operation: OperationKit.Operation) -> Foundation.Operation? {
        return nil
    }
    
    func evaluate(forOperation operation: OperationKit.Operation, completion: (OperationConditionResult) -> Void) {
        completion(.satisfied)
    }
}

enum AlwaysFailedConditionError: Error {
    case error
}

struct AlwaysFailedCondition: OperationCondition {
    static let isMutuallyExclusive = false
    
    init() {
        // No op.
    }
    
    func dependency(forOperation operation: OperationKit.Operation) -> Foundation.Operation? {
        return nil
    }
    
    func evaluate(forOperation operation: OperationKit.Operation, completion: (OperationConditionResult) -> Void) {
        completion(.failed(AlwaysFailedConditionError.error))
    }
}
