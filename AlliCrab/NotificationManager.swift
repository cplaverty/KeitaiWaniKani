//
//  NotificationManager.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os
import UserNotifications
import WaniKaniKit

class NotificationManager {
    private let notificationScheduler: NotificationScheduler
    private var assignmentsChangeObserver: NSObjectProtocol?
    
    init() {
        if #available(iOS 10.0, *) {
            notificationScheduler = UserNotificationScheduler()
        } else {
            notificationScheduler = LocalNotificationScheduler()
        }
    }
    
    deinit {
        unregisterForNotifications()
    }
    
    public func registerForNotifications(resourceRepository: ResourceRepositoryReader) {
        notificationScheduler.requestAuthorisation { (granted, error) in
            if let error = error {
                if #available(iOS 10.0, *) {
                    os_log("Got error from notification authorisation: %@", type: .error, error as NSError)
                }
            }
            if #available(iOS 10.0, *) {
                os_log("Notification authorisation granted = %@", type: .info, String(granted))
            }
            
            if granted {
                self.listenForAssignmentChanges(resourceRepository: resourceRepository)
            }
        }
    }
    
    public func unregisterForNotifications() {
        if let assignmentsChangeObserver = assignmentsChangeObserver {
            NotificationCenter.default.removeObserver(assignmentsChangeObserver)
        }
        assignmentsChangeObserver = nil
    }
    
    private func listenForAssignmentChanges(resourceRepository: ResourceRepositoryReader) {
        unregisterForNotifications()
        assignmentsChangeObserver = NotificationCenter.default.addObserver(forName: .waniKaniAssignmentsDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.scheduleNotifications(resourceRepository: resourceRepository)
        }
    }
    
    public func scheduleNotifications(resourceRepository: ResourceRepositoryReader) {
        do {
            notificationScheduler.removeAllNotifications()
            
            let now = Date()
            let reviewTimeline = try resourceRepository.reviewTimeline()
            
            let currentReviewCount = reviewTimeline.lazy.filter({ review in review.dateAvailable <= now }).reduce(0, { count, review in count + review.itemCounts.total })
            if #available(iOS 10.0, *) {
                os_log("Badging app icon: %d", type: .debug, currentReviewCount)
            }
            
            UIApplication.shared.applicationIconBadgeNumber = currentReviewCount
            
            let futureReviews = reviewTimeline.lazy.filter({ review in review.dateAvailable > now }).prefix(48)
            let nextReviewDate = futureReviews.first?.dateAvailable
            
            if let nextReviewDate = nextReviewDate, currentReviewCount == 0 {
                notificationScheduler.scheduleNotification(at: nextReviewDate, body: "You have new WaniKani reviews available")
            }
            
            var cumulativeReviewTotal = currentReviewCount
            for review in futureReviews {
                cumulativeReviewTotal += review.itemCounts.total
                notificationScheduler.scheduleNotification(at: review.dateAvailable, badgeNumber: cumulativeReviewTotal)
            }
        } catch ResourceRepositoryError.noDatabase {
            clearBadgeNumberAndRemoveAllNotifications()
        } catch {
            if #available(iOS 10.0, *) {
                os_log("Failed to update badge count and send notifications: %@", type: .error, error as NSError)
            }
        }
    }
    
    public func clearBadgeNumberAndRemoveAllNotifications() {
        clearBadgeNumber()
        notificationScheduler.removeAllNotifications()
    }
    
    private func clearBadgeNumber() {
        if #available(iOS 10.0, *) {
            os_log("Clearing badge number", type: .debug)
        }
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}

private protocol NotificationScheduler {
    func requestAuthorisation(completionHandler: @escaping (Bool, Error?) -> Void)
    func scheduleNotification(at date: Date, badgeNumber: Int)
    func scheduleNotification(at date: Date, body: String)
    func removeAllNotifications()
}

private class LocalNotificationScheduler: NotificationScheduler {
    func requestAuthorisation(completionHandler: @escaping (Bool, Error?) -> Void) {
        UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))
        // We assume success
        completionHandler(true, nil)
    }
    
    func removeAllNotifications() {
        if #available(iOS 10.0, *) {
            os_log("Removing all notifications", type: .debug)
        }
        
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    func scheduleNotification(at date: Date, badgeNumber: Int) {
        if #available(iOS 10.0, *) {
            os_log("Scheduling local notification with badge number %d at %@", type: .debug, badgeNumber, date as NSDate)
        }
        
        let localNotification = UILocalNotification()
        localNotification.fireDate = date
        localNotification.applicationIconBadgeNumber = badgeNumber
        
        UIApplication.shared.scheduleLocalNotification(localNotification)
    }
    
    func scheduleNotification(at date: Date, body: String) {
        if #available(iOS 10.0, *) {
            os_log("Scheduling local notification at %@", type: .debug, date as NSDate)
        }
        
        let localNotification = UILocalNotification()
        localNotification.fireDate = date
        localNotification.alertBody = body
        localNotification.soundName = UILocalNotificationDefaultSoundName
        
        UIApplication.shared.scheduleLocalNotification(localNotification)
    }
}

@available(iOS 10.0, *)
private class UserNotificationScheduler: NotificationScheduler {
    func requestAuthorisation(completionHandler: @escaping (Bool, Error?) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: completionHandler)
    }
    
    func removeAllNotifications() {
        os_log("Removing all notifications", type: .debug)
        
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
    
    func scheduleNotification(at date: Date, badgeNumber: Int) {
        os_log("Scheduling local notification with badge number %d at %@", type: .debug, badgeNumber, date as NSDate)
        
        let content = UNMutableNotificationContent()
        content.badge = badgeNumber as NSNumber
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: "ACBadge-\(badgeNumber)", content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.add(request, withCompletionHandler: nil)
    }
    
    func scheduleNotification(at date: Date, body: String) {
        os_log("Scheduling local notification at %@", type: .debug, date as NSDate)
        
        let content = UNMutableNotificationContent()
        content.body = body
        content.sound = UNNotificationSound.default()
        
        let dateComponents = Calendar.current.dateComponents([.era, .year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: "ACText", content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.add(request, withCompletionHandler: nil)
    }
}
