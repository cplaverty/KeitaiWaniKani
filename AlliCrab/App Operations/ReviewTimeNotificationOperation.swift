//
//  ReviewTimeNotificationOperation.swift
//  AlliCrab
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import CocoaLumberjack
import FMDB
import OperationKit
import WaniKaniKit

final class ReviewTimeNotificationOperation: OperationKit.Operation {
    
    private let databaseQueue: FMDatabaseQueue
    
    init(databaseQueue: FMDatabaseQueue) {
        self.databaseQueue = databaseQueue
        
        super.init()
        
        let requestedNotificationSettings = UIUserNotificationSettings(types: [.sound, .alert], categories: nil)
        let reviewTimeNotificationCondition = UserNotificationCondition(settings: requestedNotificationSettings, application: UIApplication.shared)
        addCondition(reviewTimeNotificationCondition)
    }
    
    override func execute() {
        DDLogInfo("Fetching study queue for next review time local notification scheduling")
        
        do {
            guard let studyQueue = try databaseQueue.withDatabase({ try StudyQueue.coder.load(from: $0) }) else {
                DDLogWarn("Failed to schedule review notification: no entries in study queue table")
                finish()
                return
            }
            
            guard let nextReviewDate = studyQueue.nextReviewDate, nextReviewDate.timeIntervalSinceNow > 0 else {
                DDLogInfo("Not setting local notification: next review date not set or in the past (\(String(describing: studyQueue.nextReviewDate)))")
                finish()
                return
            }
            
            let application = UIApplication.shared
            if let scheduledLocalNotifications = application.scheduledLocalNotifications {
                for notification in scheduledLocalNotifications {
                    if let userInfo = notification.userInfo, userInfo["source"] as? String == "\(type(of: self))" {
                        DDLogDebug("Cancelling existing local notification \(notification)")
                        application.cancelLocalNotification(notification)
                    }
                }
            }
            
            DDLogInfo("Scheduling local notification for \(nextReviewDate)")
            let localNotification = UILocalNotification()
            localNotification.fireDate = nextReviewDate
            localNotification.alertBody = "Review time!"
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.userInfo = ["source": "\(type(of: self))"]
            
            application.scheduleLocalNotification(localNotification)
            
            finish()
        } catch {
            DDLogError("Failed to schedule review notification due to error: \(error)")
            finish(withError: error)
        }
    }
}
