//
//  AppDelegate.swift
//  AlliCrab
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import WebKit
import CocoaLumberjack
import FMDB
import OperationKit
import WaniKaniKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    // MARK: - Application lifecycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        // Logging
        #if DEBUG
            defaultDebugLevel = DDLogLevel.verbose
        #else
            defaultDebugLevel = DDLogLevel.info
        #endif
        
        if #available(iOS 10, *) {
            DDLog.add(DDOSLogger.sharedInstance)
        } else {
            DDLog.add(DDASLLogger.sharedInstance)
            DDLog.add(DDTTYLogger.sharedInstance)
        }
        
        #if DEBUG
            let fileLogger = DDFileLogger()!
            fileLogger.rollingFrequency = TimeInterval(24 * 60 * 60) // 24 hour rolling
            fileLogger.logFileManager.maximumNumberOfLogFiles = 7
            
            DDLog.add(fileLogger)
        #endif
        
        DDLogInfo("Starting new instance (logging level \(defaultDebugLevel))")
        
        // Check if we've been launched by Snapshot
        if UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") {
            DDLogInfo("Detected snapshot run: setting login cookie and disabling notification prompts")
            if let loginCookieValue = UserDefaults.standard.string(forKey: "LOGIN_COOKIE") {
                let loginCookie = HTTPCookie(properties: [
                    .domain: "www.wanikani.com",
                    .name: "remember_user_token",
                    .path: "/",
                    .secure: "TRUE",
                    .value: loginCookieValue
                    ])!
                
                DDLogDebug("Setting login cookie value \(loginCookieValue)")
                HTTPCookieStorage.shared.setCookie(loginCookie)
                ApplicationSettings.apiKeyVerified = false
            } else {
                fatalError("LOGIN_COOKIE not set!")
            }
            
            UserNotificationCondition.isEnabled = false
        }
        
        UINavigationBar.appearance().tintColor = ApplicationSettings.globalTintColor
        UINavigationBar.appearance().barTintColor = ApplicationSettings.globalBarTintColor
        UIToolbar.appearance().tintColor = ApplicationSettings.globalTintColor
        UIToolbar.appearance().barTintColor = ApplicationSettings.globalBarTintColor
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if ApplicationSettings.purgeDatabase {
            databaseManager.recreateDatabase()
        }
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        DDLogInfo("Low memory warning: clearing statement cache")
        databaseManager.clearCachedStatements()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        DDLogInfo("Opening due to url \(url)")
        return true
    }
    
    // MARK: - Background fetch
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        DDLogDebug("In background fetch handler")
        
        // We must have an API key set, or there's no data to fetch
        guard let apiKey = ApplicationSettings.apiKey else {
            DDLogDebug("Background fetch result = .NoData (No API key set)")
            completionHandler(.noData)
            return
        }
        
        let resolver = WaniKaniAPI.resourceResolverForAPIKey(apiKey)
        let operation = GetDashboardDataOperation(resolver: resolver, databaseQueue: databaseQueue, forcedFetch: false, isInteractive: false)
        DDLogInfo("Background fetch study queue for API key \(apiKey)...")
        
        let completionHandlerOperationObserver = BlockObserver { operation, errors in
            guard let operation = operation as? GetDashboardDataOperation else { return }
            
            DDLogDebug("Background run of \(type(of: operation)) finished with errors \(errors)")
            // Check if any of these errors are non-fatal
            let fatalErrors = errors.filterNonFatalErrors()
            
            if !fatalErrors.isEmpty {
                DDLogDebug("Background fetch result = .Failed")
                completionHandler(.failed)
            } else if operation.fetchRequired {
                DDLogDebug("Background fetch result = .NewData")
                completionHandler(.newData)
            } else {
                DDLogDebug("Background fetch result = .NoData")
                completionHandler(.noData)
            }
        }
        
        operation.addObserver(completionHandlerOperationObserver)
        
        operationQueue.addOperation(operation)
    }
    
    // MARK: - WKProcessPool
    
    lazy var webKitProcessPool = WKProcessPool()
    
    // MARK: - Operation queue
    
    lazy var operationQueue: OperationKit.OperationQueue = {
        let oq = OperationKit.OperationQueue()
        oq.name = "AlliCrab worker queue"
        return oq
    }()
    
    // MARK: - SQLite Database
    
    lazy var databaseManager = DatabaseManager()
    
    var databaseQueue: FMDatabaseQueue { return databaseManager.databaseQueue }
    
    // MARK: - Utitlity methods
    
    public func performLogOut() {
        // Reset app settings
        ApplicationSettings.resetToDefaults()
        
        // Clear web cookies
        let cookieStorage = HTTPCookieStorage.shared
        if let cookies = cookieStorage.cookies {
            for cookie in cookies
            {
                cookieStorage.deleteCookie(cookie)
            }
        }
        
        if #available(iOS 9.0, *) {
            WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: Date(timeIntervalSince1970: 0), completionHandler: {})
        } else {
            do {
                let fm = FileManager.default
                let libraryPath = try fm.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                try fm.removeItem(at: URL(string: "Cookies", relativeTo: libraryPath)!)
                try fm.removeItem(at: URL(string: "WebKit", relativeTo: libraryPath)!)
            } catch {
                DDLogWarn("Failed to remove cookies folder: \(error)")
            }
        }
        
        webKitProcessPool = WKProcessPool()
        
        // Notifications
        let application = UIApplication.shared
        application.applicationIconBadgeNumber = 0
        application.cancelAllLocalNotifications()
        
        // Purge database
        databaseQueue.inDatabase { _ in
            self.databaseManager.recreateDatabase()
        }
    }
    
}
