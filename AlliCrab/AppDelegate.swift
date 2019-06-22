//
//  AppDelegate.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import AVFoundation
import os
import UIKit
import UserNotifications
import WaniKaniKit
import WebKit

struct ApplicationURL {
    static let launchLessons = URL(string: "kwk://launch/lessons")!
    static let launchReviews = URL(string: "kwk://launch/reviews")!
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    private var rootNavigationController: UINavigationController! {
        return window?.rootViewController as? UINavigationController
    }
    
    override init() {
        databaseConnectionFactory = AppGroupDatabaseConnectionFactory()
        databaseManager = DatabaseManager(factory: databaseConnectionFactory)
        notificationManager = NotificationManager()
        
        super.init()
        
        notificationManager.delegate = self
    }
    
    // MARK: - Properties
    
    private let databaseConnectionFactory: DatabaseConnectionFactory
    private let databaseManager: DatabaseManager
    let notificationManager: NotificationManager
    
    private var shouldSendNotifications = true
    
    var resourceRepository: ResourceRepository? {
        didSet {
            guard let resourceRepository = resourceRepository else {
                UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
                notificationManager.unregisterForNotifications()
                return
            }
            
            if shouldSendNotifications {
                notificationManager.registerForNotifications(resourceRepository: resourceRepository)
            }
            
            UIApplication.shared.setMinimumBackgroundFetchInterval(5 * .oneMinute)
        }
    }
    
    lazy var webKitProcessPool = WKProcessPool()
    
    // MARK: - UIApplicationDelegate
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UINavigationBar.appearance().tintColor = .globalTintColor
        UINavigationBar.appearance().barTintColor = .globalBarTintColor
        UIToolbar.appearance().tintColor = .globalTintColor
        UIToolbar.appearance().barTintColor = .globalBarTintColor
        
        #if targetEnvironment(simulator)
        // Check if we've been launched by Snapshot
        if UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") {
            os_log("Detected snapshot run: setting login cookie and disabling notification prompts", type: .info)
            if let loginCookieValue = UserDefaults.standard.string(forKey: "LOGIN_COOKIE") {
                let loginCookie = HTTPCookie(properties: [
                    .domain: "www.wanikani.com",
                    .name: "remember_user_token",
                    .path: "/",
                    .secure: "TRUE",
                    .value: loginCookieValue
                    ])!
                
                if #available(iOS 11.0, *) {
                    WKWebsiteDataStore.default().httpCookieStore.setCookie(loginCookie) {
                        os_log("Login cookie set", type: .info)
                    }
                } else {
                    HTTPCookieStorage.shared.setCookie(loginCookie)
                    os_log("Login cookie set", type: .info)
                }
            } else {
                os_log("Not setting login cookie (LOGIN_COOKIE not found)", type: .info)
            }
            
            shouldSendNotifications = false
        }
        #endif
        
        if ApplicationSettings.purgeCaches {
            os_log("Clearing caches directory", type: .info)
            ApplicationSettings.purgeCaches = false
            let fileManager = FileManager.default
            let cachesDir = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            do {
                try fileManager.contentsOfDirectory(at: cachesDir, includingPropertiesForKeys: nil, options: [])
                    .forEach(fileManager.removeItem(at:))
            } catch {
                os_log("Failed to purge caches directory: %@", type: .error, error as NSError)
            }
        }
        
        if ApplicationSettings.purgeDatabase {
            os_log("Purging database", type: .info)
            try! databaseConnectionFactory.destroyDatabase()
            ApplicationSettings.purgeDatabase = false
        }
        
        if !databaseManager.open() {
            os_log("Failed to open database!", type: .fault)
            fatalError("Failed to open database!")
        }
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .default, options: [.interruptSpokenAudioAndMixWithOthers])
            os_log("Audio session category assigned", type: .debug)
        } catch {
            os_log("Failed to set audio session category", type: .error, error as NSError)
        }
        
        if let apiKey = ApplicationSettings.apiKey, !apiKey.isEmpty {
            resourceRepository = makeResourceRepository(forAPIKey: apiKey)
            initialiseDashboardViewController(rootNavigationController.viewControllers[0] as! DashboardTableViewController)
            
            UIApplication.shared.shortcutItems = makeShortcutItems()
            
            return true
        } else {
            notificationManager.clearBadgeNumberAndRemoveAllNotifications()
            presentLoginViewController(animated: false)
            
            return false
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        os_log("Handling url %@", type: .info, url as NSURL)
        
        guard let rootViewController = rootNavigationController else {
            return false
        }
        
        switch url {
        case ApplicationURL.launchLessons:
            presentLessonViewController(on: rootViewController.topPresentedViewController, animated: true)
            return true
        case ApplicationURL.launchReviews:
            presentReviewViewController(on: rootViewController.topPresentedViewController, animated: true)
            return true
        default: return false
        }
    }
    
    // MARK: - Background Fetch
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        os_log("In background fetch handler", type: .debug)
        
        guard let resourceRepository = self.resourceRepository else {
            os_log("Background fetch result = .noData (No resource repository)", type: .debug)
            completionHandler(.noData)
            return
        }
        
        os_log("Updating app data from background fetch handler", type: .info)
        
        resourceRepository.updateAppData(minimumFetchInterval: 15 * .oneMinute) { result in
            switch result {
            case .success:
                os_log("Background fetch result = .newData", type: .debug)
                completionHandler(.newData)
            case .noData:
                self.notificationManager.updateDeliveredNotifications(resourceRepository: resourceRepository) { didScheduleNotification in
                    if didScheduleNotification {
                        os_log("Background fetch result = .newData", type: .debug)
                        completionHandler(.newData)
                    } else {
                        os_log("Background fetch result = .noData", type: .debug)
                        completionHandler(.noData)
                    }
                }
            case let .error(error):
                os_log("Background fetch result = .failed (%@)", type: .error, error as NSError)
                completionHandler(.failed)
            }
        }
    }
    
    // MARK: - Application Shortcuts
    
    enum ShortcutItemType: String {
        case lesson
        case review
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        os_log("Handling shortcut item of type %@", type: .info, shortcutItem.type)
        
        guard let shortcutItemType = ShortcutItemType(rawValue: shortcutItem.type), let rootViewController = rootNavigationController else {
            completionHandler(false)
            return
        }
        
        switch shortcutItemType {
        case .lesson:
            presentLessonViewController(on: rootViewController.topPresentedViewController, animated: true) {
                completionHandler(true)
            }
        case .review:
            presentReviewViewController(on: rootViewController.topPresentedViewController, animated: true) {
                completionHandler(true)
            }
        }
    }
    
    func makeShortcutItems() -> [UIApplicationShortcutItem] {
        return [
            UIApplicationShortcutItem(type: ShortcutItemType.lesson.rawValue, localizedTitle: "Lessons"),
            UIApplicationShortcutItem(type: ShortcutItemType.review.rawValue, localizedTitle: "Reviews")
        ]
    }
    
    // MARK: - Login
    
    func presentLoginViewController(animated: Bool) {
        let storyboard = Storyboard.login.instance
        let vc = storyboard.instantiateViewController(withIdentifier: "Login") as! LoginRootViewController
        
        rootNavigationController.setViewControllers([vc], animated: animated)
    }
    
    func presentDashboardViewController(animated: Bool) {
        let storyboard = Storyboard.main.instance
        let vc = storyboard.instantiateViewController(withIdentifier: "Main") as! DashboardTableViewController
        initialiseDashboardViewController(vc)
        
        rootNavigationController.setViewControllers([vc], animated: animated)
    }
    
    func presentLessonViewController(on viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        let vc = WaniKaniReviewPageWebViewController.wrapped(url: WaniKaniURL.lessonSession)
        viewController.present(vc, animated: true, completion: completion)
    }
    
    func presentReviewViewController(on viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        let vc = WaniKaniReviewPageWebViewController.wrapped(url: WaniKaniURL.reviewSession)
        viewController.present(vc, animated: true, completion: completion)
    }
    
    private func initialiseDashboardViewController(_ viewController: DashboardTableViewController) {
        viewController.resourceRepository = resourceRepository
    }
    
    func makeResourceRepository(forAPIKey apiKey: String) -> ResourceRepository {
        return ResourceRepository(databaseManager: databaseManager, apiKey: apiKey, networkActivityDelegate: NetworkIndicatorController.shared)
    }
    
    func logOut() {
        // Reset app settings
        ApplicationSettings.resetToDefaults()
        
        // Clear web cookies
        let cookieStorage = HTTPCookieStorage.shared
        cookieStorage.removeCookies(since: Date(timeIntervalSince1970: 0))
        
        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: Date(timeIntervalSince1970: 0)) {
            self.webKitProcessPool = WKProcessPool()
        }
        
        // Notifications
        notificationManager.clearBadgeNumberAndRemoveAllNotifications()
        
        // Purge database
        resourceRepository = nil
        databaseManager.close()
        try! databaseConnectionFactory.destroyDatabase()
        
        if !databaseManager.open() {
            os_log("Failed to open database!", type: .fault)
            fatalError("Failed to open database!")
        }
        
        presentLoginViewController(animated: true)
    }
    
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        defer { completionHandler() }
        
        os_log("Received notification with identifier %@, action identifier %@", type: .debug, response.notification.request.identifier, response.actionIdentifier)
        guard let rootViewController = rootNavigationController else {
            return
        }
        
        let identifier = response.notification.request.identifier
        
        if identifier == NotificationManagerIdentifier.text.description {
            switch response.actionIdentifier {
            case UNNotificationDefaultActionIdentifier:
                os_log("Showing review page in response to notification interaction", type: .info)
                presentReviewViewController(on: rootViewController.topPresentedViewController, animated: true)
            case UNNotificationDismissActionIdentifier:
                os_log("Removing any pending review count notifications due to notification dismissal", type: .info)
                notificationManager.removePendingNotificationRequests(withIdentifier: identifier)
            default: break
            }
        }
    }
}
