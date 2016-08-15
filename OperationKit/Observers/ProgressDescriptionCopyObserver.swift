//
//  ProgressDescriptionCopyObserver.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import CocoaLumberjack

public class ProgressDescriptionCopyObserver: NSObject, OperationObserver {
    public let sourceProgress: Progress?
    public let destinationProgress: Progress
    public let localizedDescription: String?
    public let localizedAdditionalDescription: String?

    // Operations hold a collection of OperationObserver, which this class is expected to be a retained in
    private weak var operation: Operation?
    
    private var localizedDescriptionListenerAttached = false
    private var localizedAdditionalDescriptionListenerAttached = false
    
    private var observationContext = 0
    
    // MARK: OperationObserver
    
    public init(operation: Operation, sourceProgress: Progress? = nil, destinationProgress: Progress, localizedDescription: String? = nil, localizedAdditionalDescription: String? = nil) {
        if sourceProgress == nil {
            assert(localizedDescription != nil, "Source progress must be set if localizedDescription is not provided")
            assert(localizedAdditionalDescription != nil, "Source progress must be set if localizedAdditionalDescription is not provided")
        }
        
        self.operation = operation
        self.sourceProgress = sourceProgress
        self.destinationProgress = destinationProgress
        self.localizedDescription = localizedDescription
        self.localizedAdditionalDescription = localizedAdditionalDescription
    }
    
    public func operationDidStart(_ operation: Operation) {
        guard operation === self.operation else {
            return
        }
        
        if let localizedDescription = self.localizedDescription {
            destinationProgress.localizedDescription = localizedDescription
        } else {
            sourceProgress!.addObserver(self, forKeyPath: "localizedDescription", options: [], context: &observationContext)
            localizedDescriptionListenerAttached = true
            destinationProgress.localizedDescription = sourceProgress!.localizedDescription
        }
        
        if let localizedAdditionalDescription = self.localizedAdditionalDescription {
            destinationProgress.localizedAdditionalDescription = localizedAdditionalDescription
        } else {
            sourceProgress!.addObserver(self, forKeyPath: "localizedAdditionalDescription", options: [], context: &observationContext)
            localizedAdditionalDescriptionListenerAttached = true
            destinationProgress.localizedAdditionalDescription = sourceProgress!.localizedAdditionalDescription
        }
    }
    
    public func operation(_ operation: Operation, didProduceOperation newOperation: Foundation.Operation) {
    }
    
    public func operationDidFinish(_ operation: Operation, errors: [Error]) {
        guard operation === self.operation else {
            return
        }
        
        if localizedDescriptionListenerAttached {
            sourceProgress!.removeObserver(self, forKeyPath: "localizedDescription", context: &observationContext)
            localizedDescriptionListenerAttached = false
        }
        if localizedAdditionalDescriptionListenerAttached {
            sourceProgress!.removeObserver(self, forKeyPath: "localizedAdditionalDescription", context: &observationContext)
            localizedAdditionalDescriptionListenerAttached = false
        }
    }
    
    // MARK: Key-Value Observing
    
    public override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        guard context == &observationContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        switch keyPath {
        case "localizedDescription"?: destinationProgress.localizedDescription = sourceProgress!.localizedDescription
        case "localizedAdditionalDescription"?: destinationProgress.localizedAdditionalDescription = sourceProgress!.localizedAdditionalDescription
        default: break
        }
    }
}

public extension Operation {
    public func addProgressListener(copyingTo destinationProgress: Progress, from sourceProgress: Progress? = nil, localizedDescription: String? = nil, localizedAdditionalDescription: String? = nil) {
        self.addObserver(ProgressDescriptionCopyObserver(operation: self, sourceProgress: sourceProgress ?? (self as? ProgressReporting)?.progress,
            destinationProgress: destinationProgress, localizedDescription: localizedDescription, localizedAdditionalDescription: localizedAdditionalDescription))
    }
}
