/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

#if os(iOS)

import UIKit
import CocoaLumberjack

public enum UserNotificationConditionError: Error {
    case settingsMismatch(currentSettings: UIUserNotificationSettings?, desiredSettings: UIUserNotificationSettings)
}

/**
    A condition for verifying that we can present alerts to the user via 
    `UILocalNotification` and/or remote notifications.
*/
public struct UserNotificationCondition: OperationCondition {
    
    public enum Behavior {
        /// Merge the new `UIUserNotificationSettings` with the `currentUserNotificationSettings`.
        case merge

        /// Replace the `currentUserNotificationSettings` with the new `UIUserNotificationSettings`.
        case replace
    }
    
    public static let isMutuallyExclusive = false
    public static var isEnabled = true
    
    public let settings: UIUserNotificationSettings
    public let application: UIApplication
    public let behavior: Behavior
    
    /** 
        The designated initializer.
        
        - parameter settings: The `UIUserNotificationSettings` you wish to be 
            registered.

        - parameter application: The `UIApplication` on which the `settings` should 
            be registered.

        - parameter behavior: The way in which the `settings` should be applied 
            to the `application`. By default, this value is `.Merge`, which means
            that the `settings` will be combined with the existing settings on the
            `application`. You may also specify `.Replace`, which means the `settings` 
            will overwrite the existing settings.
    */
    public init(settings: UIUserNotificationSettings, application: UIApplication, behavior: Behavior = .merge) {
        self.settings = settings
        self.application = application
        self.behavior = behavior
    }
    
    public func dependency(for operation: Operation) -> Foundation.Operation? {
        return type(of: self).isEnabled ? UserNotificationPermissionOperation(settings: settings, application: application, behavior: behavior) : nil
    }
    
    public func evaluate(for operation: Operation, completion: @escaping (OperationConditionResult) -> Void) {
        guard type(of: self).isEnabled else {
            completion(.failed(UserNotificationConditionError.settingsMismatch(currentSettings: nil, desiredSettings: settings)))
            return
        }
        
        var current: UIUserNotificationSettings? = nil
        if Thread.isMainThread {
            current = application.currentUserNotificationSettings
        } else {
            DispatchQueue.main.sync {
                current = application.currentUserNotificationSettings
            }
        }
        
        if let current = current, current.contains(settings) {
            completion(.satisfied)
        } else {
            completion(.failed(UserNotificationConditionError.settingsMismatch(currentSettings: current, desiredSettings: settings)))
        }
    }
    
}

/**
    A private `Operation` subclass to register a `UIUserNotificationSettings`
    object with a `UIApplication`, prompting the user for permission if necessary.
*/
private class UserNotificationPermissionOperation: Operation {
    let settings: UIUserNotificationSettings
    let application: UIApplication
    let behavior: UserNotificationCondition.Behavior
    
    init(settings: UIUserNotificationSettings, application: UIApplication, behavior: UserNotificationCondition.Behavior) {
        self.settings = settings
        self.application = application
        self.behavior = behavior
        
        super.init()
        
        addCondition(AlertPresentation())
    }
    
    override func execute() {
        DispatchQueue.main.async {
            let current = self.application.currentUserNotificationSettings
            
            let settingsToRegister: UIUserNotificationSettings
            
            if let currentSettings = current, self.behavior == .merge {
                settingsToRegister = currentSettings.merged(with: self.settings)
            } else {
                settingsToRegister = self.settings
            }
            
            self.application.registerUserNotificationSettings(settingsToRegister)
            self.finish()
        }
    }
}
    
#endif
