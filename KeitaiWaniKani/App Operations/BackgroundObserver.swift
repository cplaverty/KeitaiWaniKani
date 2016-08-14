/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Contains the code related to automatic background tasks
*/

import UIKit
import OperationKit
import WaniKaniKit

/** 
    `BackgroundObserver` is an `OperationObserver` that will automatically begin 
    and end a background task if the application transitions to the background. 
    This would be useful if you had a vital `Operation` whose execution *must* complete, 
    regardless of the activation state of the app. Some kinds network connections   
    may fall in to this category, for example.
*/
class BackgroundObserver: NSObject, OperationObserver {
    // MARK: Properties

    private var identifier = UIBackgroundTaskInvalid
    private var isInBackground = false
    
    override init() {
        super.init()
        
        // We need to know when the application moves to/from the background.
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(didEnterForeground(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        isInBackground = UIApplication.shared.applicationState == .background
        
        // If we're in the background already, immediately begin the background task.
        if isInBackground {
            startBackgroundTask()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func didEnterBackground(_ notification: Notification) {
        if !isInBackground {
            isInBackground = true
            startBackgroundTask()
        }
    }
    
    @objc func didEnterForeground(_ notification: Notification) {
        if isInBackground {
            isInBackground = false
            endBackgroundTask()
        }
    }
    
    private func startBackgroundTask() {
        if identifier == UIBackgroundTaskInvalid {
            identifier = UIApplication.shared.beginBackgroundTask(withName: "BackgroundObserver", expirationHandler: {
                self.endBackgroundTask()
            })
        }
    }
    
    private func endBackgroundTask() {
        if identifier != UIBackgroundTaskInvalid {
            UIApplication.shared.endBackgroundTask(identifier)
            identifier = UIBackgroundTaskInvalid
        }
    }
    
    // MARK: Operation Observer
    
    func operationDidStart(_ operation: OperationKit.Operation) { }
    
    func operation(_ operation: OperationKit.Operation, didProduceOperation newOperation: Foundation.Operation) { }

    func operationDidFinish(_ operation: OperationKit.Operation, errors: [Error]) {
        endBackgroundTask()
    }
}
