//
//  StubOperation.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
@testable import OperationKit

struct OperationWorkflows {
    static let New: [OperationKit.Operation.State] = [.initialized]
    static let Pending: [OperationKit.Operation.State] = [.initialized, .pending]
    static let Ready: [OperationKit.Operation.State] = [.initialized, .pending, .evaluatingConditions, .ready]
    static let Executing: [OperationKit.Operation.State] = [.initialized, .pending, .evaluatingConditions, .ready, .executing]
    static let CancelledBeforeReady: [OperationKit.Operation.State] = [.initialized, .pending, .finishing, .finished]
    static let CancelledByCondition: [OperationKit.Operation.State] = [.initialized, .pending, .evaluatingConditions, .finishing, .finished]
    static let CancelledAfterReady: [OperationKit.Operation.State] = [.initialized, .pending, .evaluatingConditions, .ready, .finishing, .finished]
    static let Finished: [OperationKit.Operation.State] = [.initialized, .pending, .evaluatingConditions, .ready, .executing, .finishing, .finished]
}

enum StubOperationError: Error {
    case error
}

class StubOperation: OperationKit.Operation {
    private(set) var wasRun: Bool = false
    private(set) var stateTransitions: [OperationKit.Operation.State] = []
    
    private let immediatelyFinish: Bool
    private let shouldFail: Bool
    
    init(immediatelyFinish: Bool = true, shouldFail: Bool = false) {
        self.immediatelyFinish = immediatelyFinish
        self.shouldFail = shouldFail
        
        super.init()
        
        stateTransitions.append(state)
    }
    
    override var state: State {
        willSet {
            stateTransitions.append(newValue)
        }
    }
    
    override func execute() {
        wasRun = true
        if immediatelyFinish {
            markAsFinished()
        }
    }
    
    override func cancel() {
        super.cancel()
        if !immediatelyFinish {
            markAsFinished()
        }
    }
    
    private func markAsFinished() {
        if shouldFail {
            finishWithError(StubOperationError.error)
        } else {
            finish()
        }
    }
}

class StubGroupOperation: GroupOperation {
    private(set) var stateTransitions: [OperationKit.Operation.State] = []
    
    convenience init(operations: Foundation.Operation...) {
        self.init(operations: operations)
    }
    
    init(immediatelyFinish: Bool = true, operations: [Foundation.Operation]) {
        super.init(operations: operations)
        stateTransitions.append(state)
    }
    
    override var state: State {
        willSet {
            stateTransitions.append(newValue)
        }
    }
}

extension XCTest {
    
    func createOperationQueue() -> OperationKit.OperationQueue {
        let operationQueue = OperationKit.OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }
    
}
