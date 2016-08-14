//
//  AppDelegate.swift
//  KeitaiWaniKani
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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Logging
        #if DEBUG
            defaultDebugLevel = DDLogLevel.verbose
        #else
            defaultDebugLevel = DDLogLevel.info
        #endif
        
        DDLog.add(DDASLLogger.sharedInstance())
        DDLog.add(DDTTYLogger.sharedInstance())
        
        let fileLogger = DDFileLogger()!
        fileLogger.rollingFrequency = 24 * 60 * 60 // 24 hour rolling
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        
        DDLog.add(fileLogger)
        
        DDLogInfo("Starting new instance (logging level \(defaultDebugLevel))")

        // Check if we've been launched by Snapshot
        if UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") {
            DDLogInfo("Detected snapshot run: setting login cookie and disabling notification prompts")
            if let loginCookieValue = UserDefaults.standard.string(forKey: "LOGIN_COOKIE") {
            let loginCookie = HTTPCookie(properties: [
                HTTPCookiePropertyKey.domain: "www.wanikani.com",
                HTTPCookiePropertyKey.name: "remember_user_token",
                HTTPCookiePropertyKey.path: "/",
                HTTPCookiePropertyKey.secure: "TRUE",
                HTTPCookiePropertyKey.value: loginCookieValue
                ])!
                
                DDLogDebug("Setting login cookie value \(loginCookieValue)")
                HTTPCookieStorage.shared.setCookie(loginCookie)
                ApplicationSettings.apiKeyVerified = false
            }
        
            UserNotificationCondition.enabled = false
        }
        
        UINavigationBar.appearance().tintColor = ApplicationSettings.globalTintColor()
        UINavigationBar.appearance().barTintColor = ApplicationSettings.globalBarTintColor()
        UIToolbar.appearance().tintColor = ApplicationSettings.globalTintColor()
        UIToolbar.appearance().barTintColor = ApplicationSettings.globalBarTintColor()
        
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
        databaseQueue.inDatabase { $0?.clearCachedStatements() }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [String : AnyObject]) -> Bool {
        DDLogInfo("Opening due to url \(url)")
        return true
    }
    
    // MARK: - Background fetch
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
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
            
            DDLogDebug("Background run of \(operation.dynamicType) finished with errors \(errors)")
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
    
}
