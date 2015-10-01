//
//  ReviewTimeNotificationOperation.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import CocoaLumberjack
import FMDB
import OperationKit
import WaniKaniKit

final class ReviewTimeNotificationOperation: Operation {
    
    private let databaseQueue: FMDatabaseQueue
    
    init(databaseQueue: FMDatabaseQueue) {
        self.databaseQueue = databaseQueue
        
        super.init()
        
        let requestedNotificationSettings = UIUserNotificationSettings(forTypes: [.Badge, .Sound, .Alert], categories: nil)
        let reviewTimeNotificationCondition = UserNotificationCondition(settings: requestedNotificationSettings, application: UIApplication.sharedApplication())
        addCondition(reviewTimeNotificationCondition)
    }
    
    override func execute() {
        DDLogInfo("Fetching study queue for next review time local notification scheduling")
        
        do {
            guard let studyQueue = try databaseQueue.withDatabase({ try StudyQueue.coder.loadFromDatabase($0) }) else {
                DDLogWarn("Failed to schedule review notification: no entries in study queue table")
                finish()
                return
            }
            
            let application = UIApplication.sharedApplication()
            application.applicationIconBadgeNumber = studyQueue.reviewsAvailable
            
            guard let nextReviewDate = studyQueue.nextReviewDate where nextReviewDate.timeIntervalSinceNow > 0 else {
                DDLogInfo("Not setting local notification: next review date not set or in the past (\(studyQueue.nextReviewDate))")
                finish()
                return
            }
            
            if let scheduledLocalNotifications = application.scheduledLocalNotifications {
                for notification in scheduledLocalNotifications {
                    if let userInfo = notification.userInfo where userInfo["source"] as? String == "\(self.dynamicType)" {
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
            localNotification.userInfo = ["source": "\(self.dynamicType)"]
            
            application.scheduleLocalNotification(localNotification)
            
            finish()
        } catch {
            DDLogError("Failed to schedule review notification due to error: \(error)")
            finishWithError(error)
        }
    }
}
