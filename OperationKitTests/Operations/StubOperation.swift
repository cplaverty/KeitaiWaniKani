//
//  StubOperation.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
@testable import OperationKit

struct OperationWorkflows {
    static let New: [Operation.State] = [.Initialized]
    static let Pending: [Operation.State] = [.Initialized, .Pending]
    static let Ready: [Operation.State] = [.Initialized, .Pending, .EvaluatingConditions, .Ready]
    static let Executing: [Operation.State] = [.Initialized, .Pending, .EvaluatingConditions, .Ready, .Executing]
    static let CancelledBeforeReady: [Operation.State] = [.Initialized, .Pending, .Finishing, .Finished]
    static let CancelledByCondition: [Operation.State] = [.Initialized, .Pending, .EvaluatingConditions, .Finishing, .Finished]
    static let CancelledAfterReady: [Operation.State] = [.Initialized, .Pending, .EvaluatingConditions, .Ready, .Finishing, .Finished]
    static let Finished: [Operation.State] = [.Initialized, .Pending, .EvaluatingConditions, .Ready, .Executing, .Finishing, .Finished]
}

enum StubOperationError: ErrorType {
    case Error
}

class StubOperation: Operation {
    private(set) var wasRun: Bool = false
    private(set) var stateTransitions: [Operation.State] = []
    
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
            finishWithError(StubOperationError.Error)
        } else {
            finish()
        }
    }
}

class StubGroupOperation: GroupOperation {
    private(set) var stateTransitions: [Operation.State] = []
    
    convenience init(operations: NSOperation...) {
        self.init(operations: operations)
    }
    
    init(immediatelyFinish: Bool = true, operations: [NSOperation]) {
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
    
    func createOperationQueue() -> OperationQueue {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }
    
}