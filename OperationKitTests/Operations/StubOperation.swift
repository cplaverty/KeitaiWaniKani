//
//  StubOperation.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
@testable import OperationKit

struct OperationWorkflows {
    typealias Operation = OperationKit.Operation
    static let new: [Operation.State] = [.initialized]
    static let pending: [Operation.State] = [.initialized, .pending]
    static let ready: [Operation.State] = [.initialized, .pending, .evaluatingConditions, .ready]
    static let executing: [Operation.State] = [.initialized, .pending, .evaluatingConditions, .ready, .executing]
    static let cancelledBeforeReady: [Operation.State] = [.initialized, .pending, .finishing, .finished]
    static let cancelledByCondition: [Operation.State] = [.initialized, .pending, .evaluatingConditions, .finishing, .finished]
    static let cancelledAfterReady: [Operation.State] = [.initialized, .pending, .evaluatingConditions, .ready, .finishing, .finished]
    static let finished: [Operation.State] = [.initialized, .pending, .evaluatingConditions, .ready, .executing, .finishing, .finished]
}

enum StubOperationError: Error {
    case error
}

class StubOperation: OperationKit.Operation {
    private(set) var wasRun: Bool = false
    private(set) var stateTransitions: [OperationKit.Operation.State] = []
    
    private let shouldImmediatelyFinish: Bool
    private let shouldFail: Bool
    
    init(immediatelyFinish: Bool = true, shouldFail: Bool = false) {
        self.shouldImmediatelyFinish = immediatelyFinish
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
        if shouldImmediatelyFinish {
            markAsFinished()
        }
    }
    
    override func cancel() {
        super.cancel()
        if !shouldImmediatelyFinish {
            markAsFinished()
        }
    }
    
    private func markAsFinished() {
        if shouldFail {
            finish(withError: StubOperationError.error)
        } else {
            finish()
        }
    }
}

class StubGroupOperation: GroupOperation {
    private(set) var stateTransitions: [OperationKit.Operation.State] = []
    
    init(operations: Foundation.Operation...) {
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
    
    func makeOperationQueue() -> OperationKit.OperationQueue {
        let operationQueue = OperationKit.OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }
    
}
