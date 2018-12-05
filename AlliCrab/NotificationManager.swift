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
        notificationScheduler = UserNotificationScheduler()
    }
    
    deinit {
        unregisterForNotifications()
    }
    
    public func registerForNotifications(resourceRepository: ResourceRepositoryReader) {
        notificationScheduler.requestAuthorisation { (granted, error) in
            if let error = error {
                os_log("Got error from notification authorisation: %@", type: .error, error as NSError)
            }
            os_log("Notification authorisation granted = %@", type: .info, String(granted))
            
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
            os_log("Badging app icon: %d", type: .debug, currentReviewCount)
            
            UIApplication.shared.applicationIconBadgeNumber = currentReviewCount
            
            let futureReviews = reviewTimeline.lazy.filter({ review in review.dateAvailable > now }).prefix(48)
            let nextReviewDate = futureReviews.first?.dateAvailable

            if let nextReviewDate = nextReviewDate, currentReviewCount == 0 {
                let nextReviewCount = futureReviews.first!.itemCounts.total
                if (nextReviewCount == 1) {
                    notificationScheduler.scheduleNotification(at: nextReviewDate, body: "You have 1 new WaniKani review available")
                } else {
                    notificationScheduler.scheduleNotification(at: nextReviewDate, body: "You have \(nextReviewCount) new WaniKani reviews available")
                }
            }
            
            var cumulativeReviewTotal = currentReviewCount
            for review in futureReviews {
                cumulativeReviewTotal += review.itemCounts.total
                notificationScheduler.scheduleNotification(at: review.dateAvailable, badgeNumber: cumulativeReviewTotal)
            }
        } catch ResourceRepositoryError.noDatabase {
            clearBadgeNumberAndRemoveAllNotifications()
        } catch {
            os_log("Failed to update badge count and send notifications: %@", type: .error, error as NSError)
        }
    }
    
    public func clearBadgeNumberAndRemoveAllNotifications() {
        clearBadgeNumber()
        notificationScheduler.removeAllNotifications()
    }
    
    private func clearBadgeNumber() {
        os_log("Clearing badge number", type: .debug)
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}

private protocol NotificationScheduler {
    func requestAuthorisation(completionHandler: @escaping (Bool, Error?) -> Void)
    func scheduleNotification(at date: Date, badgeNumber: Int)
    func scheduleNotification(at date: Date, body: String)
    func removeAllNotifications()
}

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
        content.sound = UNNotificationSound.default
        
        let dateComponents = Calendar.current.dateComponents([.era, .year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: "ACText", content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.add(request, withCompletionHandler: nil)
    }
}
