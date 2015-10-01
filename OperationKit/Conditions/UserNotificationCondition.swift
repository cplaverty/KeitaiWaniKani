/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

#if os(iOS)

import UIKit

public enum UserNotificationConditionError: ErrorType {
    case SettingsMismatch(currentSettings: UIUserNotificationSettings?, desiredSettings: UIUserNotificationSettings)
}

/**
    A condition for verifying that we can present alerts to the user via 
    `UILocalNotification` and/or remote notifications.
*/
public struct UserNotificationCondition: OperationCondition {
    
    public enum Behavior {
        /// Merge the new `UIUserNotificationSettings` with the `currentUserNotificationSettings`.
        case Merge

        /// Replace the `currentUserNotificationSettings` with the new `UIUserNotificationSettings`.
        case Replace
    }
    
    public static let isMutuallyExclusive = false
    
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
    public init(settings: UIUserNotificationSettings, application: UIApplication, behavior: Behavior = .Merge) {
        self.settings = settings
        self.application = application
        self.behavior = behavior
    }
    
    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return UserNotificationPermissionOperation(settings: settings, application: application, behavior: behavior)
    }
    
    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        let result: OperationConditionResult
        
        let current = application.currentUserNotificationSettings()

        switch (current, settings)  {
            case (let current?, let settings) where current.contains(settings):
                result = .Satisfied

            default:
                let error = UserNotificationConditionError.SettingsMismatch(currentSettings: current, desiredSettings: settings)
                
                result = .Failed(error)
        }
        
        completion(result)
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
        dispatch_async(dispatch_get_main_queue()) {
            let current = self.application.currentUserNotificationSettings()
            
            let settingsToRegister: UIUserNotificationSettings
            
            switch (current, self.behavior) {
                case (let currentSettings?, .Merge):
                    settingsToRegister = currentSettings.settingsByMerging(self.settings)

                default:
                    settingsToRegister = self.settings
            }
            
            self.application.registerUserNotificationSettings(settingsToRegister)
            self.finish()
        }
    }
}
    
#endif
