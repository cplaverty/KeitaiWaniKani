//
//  NotificationManager.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os
import UserNotifications
import WaniKaniKit

enum NotificationManagerIdentifier: CustomStringConvertible {
    case badge(Int)
    case text
    
    var description: String {
        switch self {
        case let .badge(badgeNumber):
            return "ACBadge-\(badgeNumber)"
        case .text:
            return "ACText"
        }
    }
}

class NotificationManager {
    private var notificationObservers: [NSObjectProtocol]?
    
    var delegate: UNUserNotificationCenterDelegate? {
        get { return UNUserNotificationCenter.current().delegate }
        set { UNUserNotificationCenter.current().delegate = newValue }
    }
    
    deinit {
        unregisterForNotifications()
    }
    
    func registerForNotifications(resourceRepository: ResourceRepositoryReader) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if let error = error {
                os_log("Got error from notification authorisation: %@", type: .error, error as NSError)
            }
            os_log("Notification authorisation granted = %@", type: .info, String(granted))
            
            if granted {
                self.unregisterForNotifications()
                self.notificationObservers = self.addNotificationObservers(resourceRepository: resourceRepository)
            }
        }
    }
    
    func unregisterForNotifications() {
        if let notificationObservers = notificationObservers {
            os_log("Removing NotificationCenter observers from %@", type: .debug, String(describing: type(of: self)))
            notificationObservers.forEach(NotificationCenter.default.removeObserver(_:))
        }
        notificationObservers = nil
    }
    
    private func addNotificationObservers(resourceRepository: ResourceRepositoryReader) -> [NSObjectProtocol] {
        os_log("Adding NotificationCenter observers to %@", type: .debug, String(describing: type(of: self)))
        let notificationObservers = [
            NotificationCenter.default.addObserver(forName: .waniKaniUserInformationDidChange, object: nil, queue: .main) { [weak self] _ in
                self?.scheduleNotifications(resourceRepository: resourceRepository)
            },
            NotificationCenter.default.addObserver(forName: .waniKaniAssignmentsDidChange, object: nil, queue: .main) { [weak self] _ in
                self?.scheduleNotifications(resourceRepository: resourceRepository)
            },
            NotificationCenter.default.addObserver(forName: .waniKaniSubjectsDidChange, object: nil, queue: .main) { [weak self] _ in
                self?.scheduleNotifications(resourceRepository: resourceRepository)
            }
        ]
        
        return notificationObservers
    }
    
    func scheduleNotifications(resourceRepository: ResourceRepositoryReader) {
        do {
            removeAllNotifications()
            
            guard try resourceRepository.hasReviewTimeline() else {
                return
            }
            
            let now = Date()
            let reviewTimeline = try resourceRepository.reviewTimeline()
            
            let currentReviewCount = reviewTimeline.lazy.filter({ review in review.dateAvailable <= now }).reduce(0, { count, review in count + review.itemCounts.total })
            os_log("Badging app icon: %d", type: .debug, currentReviewCount)
            
            UIApplication.shared.applicationIconBadgeNumber = currentReviewCount
            
            let futureReviews = reviewTimeline.lazy.filter({ review in review.dateAvailable > now }).prefix(48)
            
            if let nextReview = futureReviews.first, currentReviewCount == 0 {
                let nextReviewDate = nextReview.dateAvailable
                let nextReviewCount = nextReview.itemCounts.total
                let formattedCount = NumberFormatter.localizedString(from: nextReviewCount as NSNumber, number: .decimal)
                
                scheduleNotification(at: nextReviewDate,
                                     body: nextReviewCount == 1
                                        ? "You have 1 new WaniKani review available"
                                        : "You have \(formattedCount) new WaniKani reviews available")
            }
            
            var cumulativeReviewTotal = currentReviewCount
            for review in futureReviews {
                cumulativeReviewTotal += review.itemCounts.total
                scheduleNotification(at: review.dateAvailable, badgeNumber: cumulativeReviewTotal)
            }
        } catch ResourceRepositoryError.noDatabase {
            clearBadgeNumberAndRemoveAllNotifications()
        } catch {
            os_log("Failed to update badge count and send notifications: %@", type: .error, error as NSError)
        }
    }
    
    func clearBadgeNumberAndRemoveAllNotifications() {
        clearBadgeNumber()
        removeAllNotifications()
    }
    
    private func clearBadgeNumber() {
        os_log("Clearing badge number", type: .debug)
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    private func removeAllNotifications() {
        os_log("Removing all notifications", type: .debug)
        
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
    
    private func scheduleNotification(at date: Date, badgeNumber: Int) {
        os_log("Scheduling local notification with badge number %d at %@", type: .debug, badgeNumber, date as NSDate)
        
        let content = UNMutableNotificationContent()
        content.badge = badgeNumber as NSNumber
        
        let dateComponents = Calendar.current.dateComponents([.era, .year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: NotificationManagerIdentifier.badge(badgeNumber).description,
                                            content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.add(request, withCompletionHandler: nil)
    }
    
    private func scheduleNotification(at date: Date, body: String) {
        os_log("Scheduling local notification at %@", type: .debug, date as NSDate)
        
        let content = UNMutableNotificationContent()
        content.body = body
        content.sound = UNNotificationSound.default
        
        let dateComponents = Calendar.current.dateComponents([.era, .year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: NotificationManagerIdentifier.text.description,
                                            content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.add(request, withCompletionHandler: nil)
    }
}
