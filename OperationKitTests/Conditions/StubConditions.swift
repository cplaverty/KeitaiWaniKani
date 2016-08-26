//
//  StubConditions.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
@testable import OperationKit

typealias Operation = OperationKit.Operation

struct AlwaysSatisfiedCondition: OperationCondition {

    static let isMutuallyExclusive = false
    
    init() {
        // No op.
    }
    
    func dependency(for operation: Operation) -> Foundation.Operation? {
        return nil
    }
    
    func evaluate(for operation: Operation, completion: @escaping (OperationConditionResult) -> Void) {
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
    
    func dependency(for operation: Operation) -> Foundation.Operation? {
        return nil
    }
    
    func evaluate(for operation: Operation, completion: @escaping (OperationConditionResult) -> Void) {
        completion(.failed(AlwaysFailedConditionError.error))
    }
}
