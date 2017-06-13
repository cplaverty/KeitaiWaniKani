//
//  ReviewCountNotificationOperation.swift
//  AlliCrab
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import CocoaLumberjack
import FMDB
import OperationKit
import WaniKaniKit

final class ReviewCountNotificationOperation: OperationKit.Operation {
    
    private let databaseQueue: FMDatabaseQueue
    
    init(databaseQueue: FMDatabaseQueue) {
        self.databaseQueue = databaseQueue
        
        super.init()
        
        let requestedNotificationSettings = UIUserNotificationSettings(types: [.badge], categories: nil)
        let reviewCountNotificationCondition = UserNotificationCondition(settings: requestedNotificationSettings, application: UIApplication.shared)
        addCondition(reviewCountNotificationCondition)
    }
    
    override func execute() {
        DDLogInfo("Fetching SRS data items for review count local notification scheduling")
        
        do {
            guard let studyQueue = try databaseQueue.withDatabase({ try StudyQueue.coder.load(from: $0) }) else {
                DDLogWarn("Failed to schedule review count notification: no entries in study queue table")
                finish()
                return
            }
            
            guard studyQueue.reviewsAvailable == 0 else {
                finish()
                return
            }
            
            let reviews = try databaseQueue.withDatabase({ try SRSDataItemCoder.reviewTimeline($0, since: studyQueue.lastUpdateTimestamp, rowLimit: 1) })
            
            // Cancel all notifications where we are the source
            let application = UIApplication.shared
            if let scheduledLocalNotifications = application.scheduledLocalNotifications {
                for notification in scheduledLocalNotifications {
                    if let userInfo = notification.userInfo, userInfo["source"] as? String == "\(type(of: self))" {
                        DDLogDebug("Cancelling existing local notification \(notification)")
                        application.cancelLocalNotification(notification)
                    }
                }
            }
            
            var cumulativeReviewTotal = studyQueue.reviewsAvailable
            for review in reviews where review.dateAvailable > studyQueue.lastUpdateTimestamp {
                cumulativeReviewTotal += review.itemCounts.total
                DDLogInfo("Scheduling local notification for \(cumulativeReviewTotal) items at \(review.dateAvailable)")
                let localNotification = UILocalNotification()
                localNotification.fireDate = review.dateAvailable
                localNotification.applicationIconBadgeNumber = cumulativeReviewTotal
                localNotification.userInfo = ["source": "\(type(of: self))"]
                
                application.scheduleLocalNotification(localNotification)
            }
            
            finish()
        } catch {
            DDLogError("Failed to schedule review count notifications due to error: \(error)")
            finish(withError: error)
        }
    }
    
}
