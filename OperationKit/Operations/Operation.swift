/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This file contains the foundational subclass of NSOperation.
 */

import Foundation
import CocoaLumberjack

/**
 The subclass of `NSOperation` from which all other operations should be derived.
 This class adds both Conditions and Observers, which allow the operation to define
 extended readiness requirements, as well as notify many interested parties
 about interesting operation state changes
 */
open class Operation: Foundation.Operation {
    
    // use the KVO mechanism to indicate that changes to "state" affect other properties as well
    public class func keyPathsForValuesAffectingIsReady() -> Set<NSObject> {
        return ["state" as NSString, "isCancelled" as NSString]
    }
    
    public class func keyPathsForValuesAffectingIsExecuting() -> Set<NSObject> {
        return ["state" as NSString]
    }
    
    public class func keyPathsForValuesAffectingIsFinished() -> Set<NSObject> {
        return ["state" as NSString]
    }
    
    // MARK: State Management
    
    enum State: Int, Comparable {
        /// The initial state of an `Operation`.
        case initialized
        
        /// The `Operation` is ready to begin evaluating conditions.
        case pending
        
        /// The `Operation` is evaluating conditions.
        case evaluatingConditions
        
        /**
         The `Operation`'s conditions have all been satisfied, and it is ready
         to execute.
         */
        case ready
        
        /// The `Operation` is executing.
        case executing
        
        /**
         Execution of the `Operation` has finished, but it has not yet notified
         the queue of this.
         */
        case finishing
        
        /// The `Operation` has finished executing.
        case finished
        
        func canTransition(to target: State, isCancelled cancelled: Bool) -> Bool {
            switch (self, target) {
            case (.initialized, .pending):
                return true
            case (.pending, .evaluatingConditions):
                return true
            case (.pending, .finishing) where cancelled:
                return true
            case (.evaluatingConditions, .ready):
                return true
            case (.evaluatingConditions, .finishing) where cancelled:
                return true
            case (.ready, .executing):
                return true
            case (.ready, .finishing):
                return true
            case (.executing, .finishing):
                return true
            case (.finishing, .finished):
                return true
            default:
                return false
            }
        }
    }
    
    /**
     Indicates that the Operation can now begin to evaluate readiness conditions,
     if appropriate.
     */
    func willEnqueue() {
        state = .pending
    }
    
    /// Private storage for the `state` property that will be KVO observed.
    private var _state = State.initialized
    
    /// A lock to guard reads and writes to the `_state` property
    private let stateLock = NSLock()
    
    var state: State {
        get {
            return stateLock.withCriticalScope {
                _state
            }
        }
        
        set(newState) {
            /*
             It's important to note that the KVO notifications are NOT called from inside
             the lock. If they were, the app would deadlock, because in the middle of
             calling the `didChangeValueForKey()` method, the observers try to access
             properties like "isReady" or "isFinished". Since those methods also
             acquire the lock, then we'd be stuck waiting on our own lock. It's the
             classic definition of deadlock.
             */
            willChangeValue(forKey: "state")
            
            stateLock.withCriticalScope {
                guard _state != .finished else {
                    return
                }
                
                assert(_state.canTransition(to: newState, isCancelled: self.isCancelled), "Performing invalid state transition.")
                _state = newState
            }
            
            didChangeValue(forKey: "state")
        }
    }
    
    // We use a recursive lock here because retrieving the ready state can invoke evaluateConditions, which will change state
    // firing of KVO notifications for the ready property
    private let readyLock = NSRecursiveLock()
    
    // Here is where we extend our definition of "readiness".
    open override var isReady: Bool {
        var isReady = false
        
        readyLock.withCriticalScope {
            switch state {
                
            case .initialized:
                // If the operation has been cancelled, "isReady" should return true
                isReady = isCancelled
                
            case .pending:
                // If the operation has been cancelled, "isReady" should return true
                guard !isCancelled else {
                    isReady = true
                    return
                }
                
                // If super isReady, conditions can be evaluated
                if super.isReady {
                    evaluateConditions()
                }
                
                // Until conditions have been evaluated, "isReady" returns false
                isReady = false
                
            case .ready:
                isReady = super.isReady || isCancelled
                
            default:
                isReady = false
            }
        }
        
        return isReady
    }
    
    public var userInitiated: Bool {
        get {
            return qualityOfService == .userInitiated
        }
        
        set {
            assert(state < .executing, "Cannot modify userInitiated after execution has begun.")
            
            qualityOfService = newValue ? .userInitiated : .default
        }
    }
    
    private var _cancelled = false
    
    open override var isCancelled: Bool {
        return _cancelled || super.isCancelled
    }
    
    open override func cancel() {
        guard !isFinished else { return }
        
        _cancelled = true
        super.cancel()
    }
    
    open override var isExecuting: Bool {
        return state == .executing
    }
    
    open override var isFinished: Bool {
        return state == .finished
    }
    
    private func evaluateConditions() {
        guard state == .pending && !isCancelled else { return }
        
        state = .evaluatingConditions
        
        OperationConditionEvaluator.evaluate(conditions, for: self) { failures in
            DDLogVerbose("Conditions evaluated for \(type(of: self)), errors: \(failures)")
            if !failures.isEmpty {
                self.cancel(withErrors: failures)
            }
            self.state = .ready
        }
    }
    
    // MARK: Observers and Conditions
    
    private(set) var conditions = [OperationCondition]()
    
    public func addCondition(_ condition: OperationCondition) {
        assert(state < .evaluatingConditions, "Cannot modify conditions after execution has begun.")
        
        conditions.append(condition)
    }
    
    private(set) var observers = [OperationObserver]()
    
    public func addObserver(_ observer: OperationObserver) {
        assert(state < .executing, "Cannot modify observers after execution has begun.")
        
        observers.append(observer)
    }
    
    open override func addDependency(_ operation: Foundation.Operation) {
        assert(state < .executing, "Dependencies cannot be modified after execution has begun.")
        
        super.addDependency(operation)
    }
    
    // MARK: Execution and Cancellation
    
    public override final func start() {
        DDLogVerbose("Starting \(type(of: self))")
        
        // NSOperation.start() contains important logic that shouldn't be bypassed.
        super.start()
        
        // If the operation has been cancelled, we still need to enter the "Finished" state.
        if isCancelled {
            finish()
        }
    }
    
    public override final func main() {
        assert(state == .ready, "This operation must be performed on an operation queue.")
        
        if _internalErrors.isEmpty && !isCancelled {
            DDLogVerbose("Executing \(type(of: self))")
            
            state = .executing
            
            for observer in observers {
                observer.operationDidStart(self)
            }
            
            execute()
        }
        else {
            DDLogVerbose("Not executing \(type(of: self)) due to cancellation (\(self.isCancelled)) or condition errors: \(self._internalErrors)")
            finish()
        }
    }
    
    /**
     `execute()` is the entry point of execution for all `Operation` subclasses.
     If you subclass `Operation` and wish to customize its execution, you would
     do so by overriding the `execute()` method.
     
     At some point, your `Operation` subclass must call one of the "finish"
     methods defined below; this is how you indicate that your operation has
     finished its execution, and that operations dependent on yours can re-evaluate
     their readiness state.
     */
    open func execute() {
        print("\(type(of: self)) must override `execute()`.")
        
        finish()
    }
    
    private var _internalErrors = [Error]()
    public func cancel(withError error: Error? = nil) {
        if let error = error {
            cancel(withErrors: [error])
        }
        else {
            cancel(withErrors: [])
        }
    }
    
    open func cancel(withErrors errors: [Error] = []) {
        DDLogVerbose("Cancelling \(type(of: self)), errors: \(errors)")
        if !errors.isEmpty {
            _internalErrors.append(contentsOf: errors)
        }
        
        cancel()
    }
    
    public final func produce(_ operation: Foundation.Operation) {
        for observer in observers {
            observer.operation(self, didProduceOperation: operation)
        }
    }
    
    // MARK: Finishing
    
    /**
     Most operations may finish with a single error, if they have one at all.
     This is a convenience method to simplify calling the actual `finish()`
     method. This is also useful if you wish to finish with an error provided
     by the system frameworks. As an example, see `DownloadEarthquakesOperation`
     for how an error from an `NSURLSession` is passed along via the
     `finishWithError()` method.
     */
    public final func finish(withError error: Error?) {
        if let error = error {
            finish([error])
        }
        else {
            finish()
        }
    }
    
    /**
     A private property to ensure we only notify the observers once that the
     operation has finished.
     */
    private var hasFinishedAlready = false
    public final func finish(_ errors: [Error] = []) {
        if !hasFinishedAlready {
            hasFinishedAlready = true
            state = .finishing
            
            let combinedErrors = _internalErrors + errors
            finished(combinedErrors)
            
            DDLogVerbose("Finished \(type(of: self)), all errors: \(combinedErrors)")
            
            for observer in observers {
                observer.operationDidFinish(self, errors: combinedErrors)
            }
            
            state = .finished
        }
    }
    
    /**
     Subclasses may override `finished(_:)` if they wish to react to the operation
     finishing with errors. For example, the `LoadModelOperation` implements
     this method to potentially inform the user about an error when trying to
     bring up the Core Data stack.
     */
    open func finished(_ errors: [Error]) {
        // No op.
    }
    
    public override final func waitUntilFinished() {
        /*
         Waiting on operations is almost NEVER the right thing to do. It is
         usually superior to use proper locking constructs, such as `dispatch_semaphore_t`
         or `dispatch_group_notify`, or even `NSLocking` objects. Many developers
         use waiting when they should instead be chaining discrete operations
         together using dependencies.
         
         To reinforce this idea, invoking `waitUntilFinished()` will crash your
         app, as incentive for you to find a more appropriate way to express
         the behavior you're wishing to create.
         */
        fatalError("Waiting on operations is an anti-pattern. Remove this ONLY if you're absolutely sure there is No Other Way™.")
    }
    
}

// Simple operator functions to simplify the assertions used above.
func <(lhs: Operation.State, rhs: Operation.State) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

func ==(lhs: Operation.State, rhs: Operation.State) -> Bool {
    return lhs.rawValue == rhs.rawValue
}
