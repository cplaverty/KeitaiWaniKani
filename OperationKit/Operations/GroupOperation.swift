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
public class GroupOperation: Operation {
    
    public override var name: String? {
        didSet {
            if let name = name {
                internalQueue.name = "\(name) internal queue"
            } else {
                internalQueue.name = "\(self.dynamicType) internal queue"
            }
        }
    }

    private let internalQueue: OperationQueue = {
        let oq = OperationQueue()
        oq.name = "\(self.dynamicType) internal queue"
        return oq
        }()
    private lazy var startingOperation: NSBlockOperation = {
        NSBlockOperation() { DDLogVerbose("Starting start marker operation \(self.dynamicType) on internal queue") }
        }()
    private lazy var finishingOperation: NSBlockOperation = {
        NSBlockOperation() { DDLogVerbose("Starting finish marker operation of \(self.dynamicType) on internal queue") }
        }()
    
    private var aggregatedErrors = [ErrorType]()
    
    public convenience init(operations: NSOperation...) {
        self.init(operations: operations)
    }
    
    public init(operations: [NSOperation]) {
        super.init()
        
        internalQueue.suspended = true
        internalQueue.delegate = self
        addOperation(startingOperation)

        for operation in operations {
            addOperation(operation)
        }
    }
    
    public override func cancel() {
        DDLogVerbose("Cancelling group operation \(self.dynamicType)")
        super.cancel()
        internalQueue.cancelAllOperations()
        if internalQueue.suspended {
            internalQueue.suspended = false
        }
    }
    
    public override func execute() {
        DDLogVerbose("Executing group operation \(self.dynamicType)")
        internalQueue.suspended = false
        addOperation(finishingOperation)
    }
    
    public func addOperation(operation: NSOperation) {
        assert(!finishingOperation.finished && !finishingOperation.executing, "cannot add new operations to a group after the group has completed")
        
        DDLogVerbose("Adding operation \(operation.dynamicType) to group operation \(self.dynamicType)")
        
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
    public final func aggregateError(error: ErrorType) {
        aggregatedErrors.append(error)
    }
    
    public func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        // For use by subclassers.
    }
}

extension GroupOperation: OperationQueueDelegate {
    public final func operationQueue(operationQueue: OperationQueue, willAddOperation operation: NSOperation) {}
    
    public final func operationQueue(operationQueue: OperationQueue, operationDidFinish operation: NSOperation, withErrors errors: [ErrorType]) {
        DDLogVerbose("Completed execution of \(operation.dynamicType) in group operation \(self.dynamicType)")
        aggregatedErrors.appendContentsOf(errors)
        
        if operation === finishingOperation {
            internalQueue.suspended = true
            DDLogVerbose("Marking \(self.dynamicType) finished")
            finish(aggregatedErrors)
        }
        else if operation !== startingOperation {
            operationDidFinish(operation, withErrors: errors)
        }
    }
}
