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
            
            let currentReviewCount = reviewTimeline.lazy.filter({ $0.dateAvailable <= now }).map({ $0.itemCounts.total }).reduce(0, +)
            os_log("Badging app icon: %d", type: .debug, currentReviewCount)
            
            UIApplication.shared.applicationIconBadgeNumber = currentReviewCount
            
            let futureReviews = reviewTimeline.lazy.filter({ $0.dateAvailable > now }).prefix(48)
            
            if let nextReview = futureReviews.first, currentReviewCount == 0 {
                let reviewNotificationText = notificationText(forCount: nextReview.itemCounts.total)
                scheduleNotification(body: reviewNotificationText, at: nextReview.dateAvailable)
            }
            
            var cumulativeReviewTotal = currentReviewCount
            for review in futureReviews {
                cumulativeReviewTotal += review.itemCounts.total
                scheduleNotification(badgeNumber: cumulativeReviewTotal, at: review.dateAvailable)
            }
        } catch ResourceRepositoryError.noDatabase {
            clearBadgeNumberAndRemoveAllNotifications()
        } catch {
            os_log("Failed to update badge count and send notifications: %@", type: .error, error as NSError)
        }
    }
    
    func updateDeliveredNotifications(resourceRepository: ResourceRepositoryReader, completionHandler: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getDeliveredNotifications { delivered in
            guard delivered.contains(where: { $0.request.identifier == NotificationManagerIdentifier.text.description }) else {
                os_log("No delivered notifications present", type: .debug)
                completionHandler(false)
                return
            }
            
            do {
                let didScheduleNotification = try self.scheduleNotificationForNextReviewCount(resourceRepository: resourceRepository)
                completionHandler(didScheduleNotification)
            } catch {
                os_log("Failed to refresh delivered notification text: %@", type: .error, error as NSError)
                completionHandler(false)
            }
        }
    }
    
    private func scheduleNotificationForNextReviewCount(resourceRepository: ResourceRepositoryReader) throws -> Bool {
        guard try resourceRepository.hasReviewTimeline() else {
            return false
        }
        
        let now = Date()
        let reviewTimeline = try resourceRepository.reviewTimeline()
        
        guard let nextReviewIndex = reviewTimeline.firstIndex(where: { $0.dateAvailable > now }) else {
            return false
        }
        
        let currentReviewCount = reviewTimeline[..<nextReviewIndex].lazy.map({ $0.itemCounts.total }).reduce(0, +)
        let nextReview = reviewTimeline[nextReviewIndex]
        
        let nextReviewCount = currentReviewCount + nextReview.itemCounts.total
        os_log("Next review notification scheduled for %d items", type: .debug, nextReviewCount)
        
        let reviewNotificationText = notificationText(forCount: nextReviewCount)
        scheduleNotification(body: reviewNotificationText, at: nextReview.dateAvailable, includeSound: false)
        
        return true
    }
    
    private func notificationText(forCount count: Int) -> String {
        let formattedCount = NumberFormatter.localizedString(from: count as NSNumber, number: .decimal)
        
        return count == 1
            ? "You have 1 new WaniKani review available"
            : "You have \(formattedCount) new WaniKani reviews available"
    }
    
    func removePendingNotificationRequests(withIdentifier identifier: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
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
    
    private func scheduleNotification(badgeNumber: Int, at date: Date) {
        os_log("Scheduling local notification with badge number %d at %@", type: .debug, badgeNumber, date as NSDate)
        
        let content = UNMutableNotificationContent()
        content.badge = badgeNumber as NSNumber
        
        scheduleNotification(content: content, identifier: .badge(badgeNumber), at: date)
    }
    
    private func scheduleNotification(body: String, at date: Date, includeSound: Bool = true) {
        os_log("Scheduling local notification at %@", type: .debug, date as NSDate)
        
        let content = UNMutableNotificationContent()
        content.body = body
        if includeSound {
            content.sound = UNNotificationSound.default
        }
        
        scheduleNotification(content: content, identifier: .text, at: date)
    }
    
    private func scheduleNotification(content: UNNotificationContent, identifier: NotificationManagerIdentifier, at date: Date) {
        let dateComponents = Calendar.current.dateComponents([.era, .year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier.description, content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.add(request, withCompletionHandler: nil)
    }
}
