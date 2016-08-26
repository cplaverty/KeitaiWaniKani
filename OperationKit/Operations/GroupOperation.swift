/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows how operations can be composed together to form new operations.
*/

import Foundation
import CocoaLumberjack

/**
    A subclass of `Operation` that executes zero or more operations as part of its
    own execution. This class of operation is very useful for abstracting several
    smaller operations into a larger operation. As an example, the `GetEarthquakesOperation`
    is composed of both a `DownloadEarthquakesOperation` and a `ParseEarthquakesOperation`.

    Additionally, `GroupOperation`s are useful if you establish a chain of dependencies,
    but part of the chain may "loop". For example, if you have an operation that
    requires the user to be authenticated, you may consider putting the "login"
    operation inside a group operation. That way, the "login" operation may produce
    subsequent operations (still within the outer `GroupOperation`) that will all
    be executed before the rest of the operations in the initial chain of operations.
*/
open class GroupOperation: Operation {
    
    open override var name: String? {
        didSet {
            if let name = name {
                internalQueue.name = "\(name) internal queue"
            } else {
                internalQueue.name = "\(type(of: self)) internal queue"
            }
        }
    }
    
    let internalQueue: OperationQueue = {
        let oq = OperationQueue()
        oq.name = "\(type(of: self)) internal queue"
        return oq
    }()
    fileprivate let startingOperation = Foundation.BlockOperation() {}
    fileprivate let finishingOperation = Foundation.BlockOperation() {}
    
    fileprivate var aggregatedErrors = [Error]()
    
    public convenience init(operations: Foundation.Operation...) {
        self.init(operations: operations)
    }
    
    public init(operations: [Foundation.Operation]) {
        super.init()
        
        internalQueue.isSuspended = true
        internalQueue.delegate = self
        add(startingOperation)

        for operation in operations {
            add(operation)
        }
    }
    
    open override func cancel() {
        DDLogVerbose("Cancelling group operation \(type(of: self))")
        super.cancel()
        internalQueue.cancelAllOperations()
        if internalQueue.isSuspended {
            internalQueue.isSuspended = false
        }
    }
    
    open override func execute() {
        DDLogVerbose("Executing group operation \(type(of: self))")
        internalQueue.isSuspended = false
        add(finishingOperation)
    }
    
    public func add(_ operation: Foundation.Operation) {
        assert(!finishingOperation.isFinished && !finishingOperation.isExecuting, "cannot add new operations to a group after the group has completed")
        
        /*
        Some operation in this group has produced a new operation to execute.
        We want to allow that operation to execute before the group completes,
        so we'll make the finishing operation dependent on this newly-produced operation.
        */
        if operation !== finishingOperation {
            finishingOperation.addDependency(operation)
        }
        
        /*
        All operations should be dependent on the "startingOperation".
        This way, we can guarantee that the conditions for other operations
        will not evaluate until just before the operation is about to run.
        Otherwise, the conditions could be evaluated at any time, even
        before the internal operation queue is unsuspended.
        */
        if operation !== startingOperation {
            operation.addDependency(startingOperation)
        }
        
        internalQueue.addOperation(operation)
    }
    
    /**
        Note that some part of execution has produced an error.
        Errors aggregated through this method will be included in the final array
        of errors reported to observers and to the `finished(_:)` method.
    */
    public final func aggregateError(_ error: Error) {
        aggregatedErrors.append(error)
    }
    
    open func operationDidFinish(_ operation: Foundation.Operation, withErrors errors: [Error]) {
        // For use by subclassers.
    }
}

extension GroupOperation: OperationQueueDelegate {
    public final func operationQueue(_ operationQueue: OperationQueue, willAddOperation operation: Foundation.Operation) {}
    
    public final func operationQueue(_ operationQueue: OperationQueue, operationDidFinish operation: Foundation.Operation, withErrors errors: [Error]) {
        DDLogVerbose("Completed execution of \(type(of: operation)) in group operation \(type(of: self))")
        aggregatedErrors.append(contentsOf: errors)
        
        if operation === finishingOperation {
            internalQueue.isSuspended = true
            finish(aggregatedErrors)
        }
        else if operation !== startingOperation {
            operationDidFinish(operation, withErrors: errors)
        }
    }
}
